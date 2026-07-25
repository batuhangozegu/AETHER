package com.aether.borsa.service;

import com.aether.borsa.dto.request.CreateOrderRequest;
import com.aether.borsa.dto.response.OrderResponse;

import java.util.List;
import java.util.UUID;

public interface TradeService {

    List<OrderResponse> getActiveOrders(UUID userId);
    List<OrderResponse> getOrderHistory(UUID userId, int page, int size);
    OrderResponse createOrder(UUID userId, CreateOrderRequest request);
    OrderResponse closeOrder(UUID userId, UUID orderId);

}
