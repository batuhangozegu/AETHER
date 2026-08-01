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

        List<Order> closedOrders = orderRepository.findByUserAndStatusOrderByCreatedAtDesc(
                user, OrderStatus.CLOSED, PageRequest.of(page, size));

        return closedOrders.stream()
                .map(order -> mapToResponse(order, order.getExitPrice() != null ? order.getExitPrice() : BigDecimal.ZERO))
                .toList();
    }

    @Override
    public OrderResponse createOrder(UUID userId, CreateOrderRequest request) {

        User user = userRepository.findById(userId).orElseThrow(() -> new RuntimeException("User not found."));
        ExchangeKey exchangeKey = exchangeKeyRepository.findById(request.getExchangeKeyId()).orElseThrow(() -> new RuntimeException("Exchange key not found."));
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
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found."));

        if (!order.getUser().getId().equals(userId)) {
            throw new RuntimeException("Access denied: this order does not belong to you.");
        }

        IExchangeClient client = exchangeClientFactory.getClient(order.getExchangeKey().getExchangeName());
        BigDecimal currentPrice = client.getCurrentPrice(order.getSymbol());

        order.setStatus(OrderStatus.CLOSED);
        order.setClosedAt(LocalDateTime.now());
        order.setExitPrice(currentPrice);

        Order updated = orderRepository.save(order);

        return mapToResponse(updated, currentPrice);
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
