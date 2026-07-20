package com.aether.borsa.service;

import com.aether.borsa.dto.request.CreateOrderRequest;
import com.aether.borsa.dto.response.OrderResponse;

import java.util.List;
import java.util.UUID;

public interface TradeService {

    List<OrderResponse> getActiveOrders(UUID userId);
    OrderResponse createOrder(UUID userId, CreateOrderRequest request);
    OrderResponse closeOrder(UUID userId, UUID orderId);

}
