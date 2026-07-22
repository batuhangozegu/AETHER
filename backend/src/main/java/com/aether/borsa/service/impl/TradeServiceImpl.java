package com.aether.borsa.service.impl;

import com.aether.borsa.dto.request.CreateOrderRequest;
import com.aether.borsa.dto.response.OrderResponse;
import com.aether.borsa.model.entity.ExchangeKey;
import com.aether.borsa.model.entity.Order;
import com.aether.borsa.model.entity.User;
import com.aether.borsa.model.enums.OrderStatus;
import com.aether.borsa.model.enums.TradeSide;
import com.aether.borsa.repository.ExchangeKeyRepository;
import com.aether.borsa.repository.OrderRepository;
import com.aether.borsa.repository.UserRepository;
import com.aether.borsa.service.TradeService;
import com.aether.borsa.service.exchange.ExchangeClientFactory;
import com.aether.borsa.service.exchange.IExchangeClient;
import lombok.RequiredArgsConstructor;
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

    @Override
    public List<OrderResponse> getActiveOrders(UUID userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Kullanıcı Bulunamadı."));

        List<Order> orders = orderRepository.findByUserAndStatus(user, OrderStatus.OPEN);

        if (orders.isEmpty()) {
            return List.of();
        }

        List<String> symbols = getUniqueSymbols(orders);
        Map<String, BigDecimal> priceMap = getPriceMap(symbols, orders.get(0).getExchangeKey());

        return orders.stream()
                .map(order -> mapToResponse(order, priceMap.get(order.getSymbol())))
                .toList();
    }

    @Override
    public OrderResponse createOrder(UUID userId, CreateOrderRequest request) {

        User user = userRepository.findById(userId).orElseThrow(() -> new RuntimeException("Kullanıcı Bulunamadı"));
        ExchangeKey exchangeKey = exchangeKeyRepository.findById(request.getExchangeKeyId()).orElseThrow(() -> new RuntimeException("Borsa Bağlantısı Kurulamadı."));
        Order order = Order.builder()
                .user(user)
                .exchangeKey(exchangeKey)
                .symbol(request.getSymbol())
                .side(request.getSide())
                .type(request.getType())
                .status(OrderStatus.OPEN)
                .amount(request.getAmount())
                .entryPrice(request.getEntryPrice())
                .takeProfit(request.getTakeProfit())
                .stopLoss(request.getStopLoss())
                .build();

        Order saved = orderRepository.save(order);
        return mapToResponse(saved, saved.getEntryPrice());
    }

    @Override
    public OrderResponse closeOrder(UUID userId, UUID orderId) {

        Order order = orderRepository.findById(orderId).orElseThrow(() -> new RuntimeException("Order bulunamadı"));
        order.setStatus(OrderStatus.CLOSED);
        order.setClosedAt(LocalDateTime.now());

        Order updated = orderRepository.save(order);

        IExchangeClient client = exchangeClientFactory.getClient(updated.getExchangeKey().getExchangeName());
        BigDecimal currentPrice = client.getCurrentPrice(updated.getSymbol());

        return mapToResponse(updated, currentPrice);
    }


    private OrderResponse mapToResponse(Order order, BigDecimal currentPrice) {
        BigDecimal currentPnL = calculatePnL(order, currentPrice);

        return new OrderResponse(
                order.getId(),
                order.getSymbol(),
                order.getSide(),
                order.getAmount(),
                order.getStatus(),
                currentPnL,
                order.getCreatedAt(),
                order.getClosedAt()
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

    private List<String> getUniqueSymbols(List<Order> orders) {
        return orders.stream()
                .map(Order::getSymbol)
                .distinct()
                .toList();
    }

    private Map<String, BigDecimal> getPriceMap(List<String> symbols, ExchangeKey exchangeKey) {
        Map<String, BigDecimal> priceMap = new HashMap<>();

        IExchangeClient client = exchangeClientFactory.getClient(exchangeKey.getExchangeName());

        for (String symbol : symbols) {
            BigDecimal price = client.getCurrentPrice(symbol);
            priceMap.put(symbol, price);
        }

        return priceMap;
    }


}
