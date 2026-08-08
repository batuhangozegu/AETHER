package com.aether.borsa.service.impl;

import com.aether.borsa.dto.request.CreateOrderRequest;
import com.aether.borsa.dto.response.OrderResponse;
import com.aether.borsa.model.entity.ExchangeKey;
import com.aether.borsa.model.entity.Order;
import com.aether.borsa.model.entity.User;
import com.aether.borsa.model.enums.MarginMode;
import com.aether.borsa.model.enums.MarketType;
import com.aether.borsa.model.enums.OrderStatus;
import com.aether.borsa.model.enums.TradeSide;
import com.aether.borsa.repository.ExchangeKeyRepository;
import com.aether.borsa.repository.OrderRepository;
import com.aether.borsa.repository.UserRepository;
import com.aether.borsa.service.NotificationService;
import com.aether.borsa.service.TradeService;
import com.aether.borsa.service.exchange.ExchangeClientFactory;
import com.aether.borsa.service.exchange.IExchangeClient;
import com.aether.borsa.service.exchange.PlacedOrder;
import com.aether.borsa.service.exchange.PositionInfo;
import com.aether.borsa.util.EncryptionUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class TradeServiceImpl implements TradeService {

    private final OrderRepository orderRepository;
    private final UserRepository userRepository;
    private final ExchangeKeyRepository exchangeKeyRepository;
    private final ExchangeClientFactory exchangeClientFactory;
    private final NotificationService notificationService;
    private final EncryptionUtil encryptionUtil;

    @Override
    public List<OrderResponse> getActiveOrders(UUID userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found."));

        List<Order> orders = orderRepository.findByUserAndStatus(user, OrderStatus.OPEN);

        if (orders.isEmpty()) {
            return List.of();
        }

        Map<String, BigDecimal> priceMap = getPriceMap(orders);

        return orders.stream()
                .map(order -> mapToResponse(order, priceMap.get(priceKey(order))))
                .toList();
    }

    @Override
    public List<OrderResponse> getOrderHistory(UUID userId, int page, int size) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found."));

        List<Order> orders = orderRepository.findByUserOrderByCreatedAtDesc(
                user, PageRequest.of(page, size));

        if (orders.isEmpty()) {
            return List.of();
        }

        // Still-open orders need a live market price for PnL; closed ones
        // already carry their exitPrice from when they were closed.
        List<Order> openOrders = orders.stream()
                .filter(order -> order.getStatus() == OrderStatus.OPEN)
                .toList();
        Map<String, BigDecimal> priceMap = openOrders.isEmpty() ? Map.of() : getPriceMap(openOrders);

        return orders.stream()
                .map(order -> {
                    BigDecimal price = order.getStatus() == OrderStatus.OPEN
                            ? priceMap.get(priceKey(order))
                            : order.getExitPrice();
                    return mapToResponse(order, price);
                })
                .toList();
    }

    @Override
    public OrderResponse createOrder(UUID userId, CreateOrderRequest request) {

        User user = userRepository.findById(userId).orElseThrow(() -> new RuntimeException("User not found."));
        ExchangeKey exchangeKey = exchangeKeyRepository.findById(request.getExchangeKeyId()).orElseThrow(() -> new RuntimeException("Exchange key not found."));

        if (!exchangeKey.getUser().getId().equals(userId)) {
            throw new RuntimeException("Bu borsa bağlantısına erişim yetkiniz yok.");
        }
        if (!exchangeKey.isCanTrade()) {
            throw new RuntimeException("Bu borsa bağlantısının işlem (trade) izni yok.");
        }

        MarketType marketType = request.getMarketType() != null ? request.getMarketType() : MarketType.SPOT;

        // Spot piyasalarda açığa satış (short) yoktur — short pozisyon
        // istemek kaldıraçlı (futures) işlem seçmek anlamına gelir.
        if (marketType == MarketType.SPOT && request.getSide() == TradeSide.SELL) {
            throw new RuntimeException(
                    "Spot piyasalarda açığa satış yapılamaz. Short pozisyon için kaldıraçlı (futures) işlem kullanın.");
        }

        IExchangeClient client = exchangeClientFactory.getClient(exchangeKey.getExchangeName());
        DecryptedKeys keys = decryptKeys(exchangeKey);
        BigDecimal limitPrice = "MARKET".equalsIgnoreCase(request.getType()) ? null : request.getEntryPrice();

        PlacedOrder placed;
        Integer leverage = null;
        MarginMode marginMode = null;
        BigDecimal liquidationPrice = null;

        if (marketType == MarketType.FUTURES) {
            leverage = request.getLeverage() != null ? request.getLeverage() : 1;
            if (leverage < 1 || leverage > 125) {
                throw new RuntimeException("Kaldıraç 1 ile 125 arasında olmalı.");
            }
            marginMode = request.getMarginMode() != null ? request.getMarginMode() : MarginMode.ISOLATED;

            client.setLeverage(keys.apiKey(), keys.secretKey(), keys.passphrase(),
                    request.getSymbol(), leverage, marginMode);
            placed = client.placeFuturesOrder(
                    keys.apiKey(), keys.secretKey(), keys.passphrase(),
                    request.getSymbol(), request.getSide(), request.getType(),
                    request.getAmount(), limitPrice, false);

            PositionInfo position = client.getPositionInfo(
                    keys.apiKey(), keys.secretKey(), keys.passphrase(), request.getSymbol());
            liquidationPrice = position.getLiquidationPrice();
        } else {
            placed = client.placeSpotOrder(
                    keys.apiKey(), keys.secretKey(), keys.passphrase(),
                    request.getSymbol(), request.getSide(), request.getType(),
                    request.getAmount(), limitPrice);
        }

        Order order = Order.builder()
                .user(user)
                .exchangeKey(exchangeKey)
                .symbol(request.getSymbol())
                .side(request.getSide())
                .type(request.getType())
                .status(OrderStatus.OPEN)
                // Borsaya gerçekten gönderilen (sembolün hassasiyet kuralına
                // yuvarlanmış) miktar — kullanıcının istediği ham değer değil,
                // aksi halde DB'deki kayıt borsadaki gerçek pozisyonla uyuşmaz.
                .amount(placed.getFilledAmount())
                .entryPrice(placed.getFilledPrice())
                .takeProfit(request.getTakeProfit())
                .stopLoss(request.getStopLoss())
                .exchangeOrderId(placed.getExchangeOrderId())
                .marketType(marketType)
                .leverage(leverage)
                .marginMode(marginMode)
                .liquidationPrice(liquidationPrice)
                .build();

        Order saved = orderRepository.save(order);
        return mapToResponse(saved, saved.getEntryPrice());
    }

    @Override
    public OrderResponse closeOrder(UUID userId, UUID orderId) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found."));

        if (!order.getUser().getId().equals(userId)) {
            throw new RuntimeException("Access denied: this order does not belong to you.");
        }

        ExchangeKey exchangeKey = order.getExchangeKey();
        IExchangeClient client = exchangeClientFactory.getClient(exchangeKey.getExchangeName());
        DecryptedKeys keys = decryptKeys(exchangeKey);

        // Pozisyonu kapatmak için ters yönde bir MARKET emri gönder.
        // FUTURES'ta reduceOnly=true ile sadece mevcut pozisyon kapatılır,
        // yeni pozisyon açılmaz.
        TradeSide closingSide = order.getSide() == TradeSide.BUY ? TradeSide.SELL : TradeSide.BUY;
        PlacedOrder placed = order.getMarketType() == MarketType.FUTURES
                ? client.placeFuturesOrder(keys.apiKey(), keys.secretKey(), keys.passphrase(),
                        order.getSymbol(), closingSide, "MARKET", order.getAmount(), null, true)
                : client.placeSpotOrder(keys.apiKey(), keys.secretKey(), keys.passphrase(),
                        order.getSymbol(), closingSide, "MARKET", order.getAmount(), null);
        BigDecimal exitPrice = placed.getFilledPrice();

        order.setStatus(OrderStatus.CLOSED);
        order.setClosedAt(LocalDateTime.now());
        order.setExitPrice(exitPrice);

        Order updated = orderRepository.save(order);

        BigDecimal pnl = calculatePnL(updated, exitPrice);
        String pnlText = (pnl.signum() >= 0 ? "+" : "") + pnl + " USD";
        notificationService.notify(
                order.getUser(),
                pnl.signum() >= 0 ? "success" : "loss",
                "Pozisyon kapatıldı: " + order.getSymbol(),
                "PnL: " + pnlText
        );

        return mapToResponse(updated, exitPrice);
    }


    private OrderResponse mapToResponse(Order order, BigDecimal currentPrice) {
        BigDecimal safeCurrentPrice = currentPrice != null ? currentPrice : BigDecimal.ZERO;
        BigDecimal currentPnL = calculatePnL(order, safeCurrentPrice);

        return new OrderResponse(
                order.getId(),
                order.getSymbol(),
                order.getSide(),
                order.getAmount(),
                order.getEntryPrice(),
                order.getExitPrice(),
                order.getTakeProfit(),
                order.getStopLoss(),
                order.getStatus(),
                currentPnL,
                order.getCreatedAt(),
                order.getClosedAt(),
                order.getExchangeOrderId(),
                order.getMarketType(),
                order.getLeverage(),
                order.getMarginMode(),
                order.getLiquidationPrice()
        );
    }

    private BigDecimal calculatePnL(Order order, BigDecimal currentPrice) {
        BigDecimal diff;

        if (order.getSide() == TradeSide.BUY){
            diff = currentPrice.subtract(order.getEntryPrice());
        }else {
            diff = order.getEntryPrice().subtract(currentPrice);
        }
        return diff.multiply(order.getAmount());
    }

    /** {@code encryptionUtil.decrypt} checked exception fırlatır — burada RuntimeException'a sarılıyor. */
    private DecryptedKeys decryptKeys(ExchangeKey exchangeKey) {
        try {
            String apiKey = encryptionUtil.decrypt(exchangeKey.getEncryptedApiKey());
            String secretKey = encryptionUtil.decrypt(exchangeKey.getEncryptedSecretKey());
            String passphrase = exchangeKey.getEncryptedPassphrase() != null
                    ? encryptionUtil.decrypt(exchangeKey.getEncryptedPassphrase())
                    : null;
            return new DecryptedKeys(apiKey, secretKey, passphrase);
        } catch (Exception e) {
            throw new RuntimeException("Şifre çözme işlemi başarısız: " + e.getMessage(), e);
        }
    }

    private record DecryptedKeys(String apiKey, String secretKey, String passphrase) {}

    private String priceKey(Order order) {
        return order.getExchangeKey().getId() + ":" + order.getSymbol();
    }

    private Map<String, BigDecimal> getPriceMap(List<Order> orders) {
        Map<String, BigDecimal> priceMap = new HashMap<>();

        Map<UUID, List<Order>> ordersByExchangeKeyId = orders.stream()
                .collect(java.util.stream.Collectors.groupingBy(order -> order.getExchangeKey().getId()));

        for (List<Order> ordersForKey : ordersByExchangeKeyId.values()) {
            ExchangeKey exchangeKey = ordersForKey.get(0).getExchangeKey();
            IExchangeClient client = exchangeClientFactory.getClient(exchangeKey.getExchangeName());

            ordersForKey.stream()
                    .map(Order::getSymbol)
                    .distinct()
                    .forEach(symbol -> {
                        BigDecimal price = client.getCurrentPrice(symbol);
                        priceMap.put(exchangeKey.getId() + ":" + symbol, price);
                    });
        }

        return priceMap;
    }


}
