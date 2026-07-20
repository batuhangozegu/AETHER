package com.aether.borsa.service.impl;

import com.aether.borsa.dto.request.CreateOrderRequest;
import com.aether.borsa.dto.response.OrderResponse;
import com.aether.borsa.model.entity.ExchangeKey;
import com.aether.borsa.model.entity.Order;
import com.aether.borsa.model.entity.User;
import com.aether.borsa.model.enums.OrderStatus;
import com.aether.borsa.repository.ExchangeKeyRepository;
import com.aether.borsa.repository.OrderRepository;
import com.aether.borsa.repository.UserRepository;
import com.aether.borsa.service.TradeService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class TradeServiceImpl implements TradeService {

    private final OrderRepository orderRepository;
    private final UserRepository userRepository;
    private final ExchangeKeyRepository exchangeKeyRepository;

    @Override
    public List<OrderResponse> getActiveOrders(UUID userId){

        User user = userRepository.findById(userId).orElseThrow(() -> new RuntimeException("Kullanıcı Bulunamadı."));

        List<Order> orders = orderRepository.findByUserAndStatus(user, OrderStatus.OPEN);

        return orders.stream()
                .map(this::mapToResponse)
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

        return mapToResponse(saved);
    }

    @Override
    public OrderResponse closeOrder(UUID userId, UUID orderId) {

        Order order = orderRepository.findById(orderId).orElseThrow(() -> new RuntimeException("Order bulunamadı"));
        order.setStatus(OrderStatus.CLOSED);
        order.setClosedAt(LocalDateTime.now());

        Order updated = orderRepository.save(order);

        return mapToResponse(updated);
    }


    private OrderResponse mapToResponse(Order order) {
        return new OrderResponse(
                order.getId(),
                order.getSymbol(),
                order.getSide(),
                order.getAmount(),
                order.getStatus(),
                null,
                order.getCreatedAt(),
                order.getClosedAt()
        );
    }


}
