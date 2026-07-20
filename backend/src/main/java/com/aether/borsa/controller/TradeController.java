package com.aether.borsa.controller;

import com.aether.borsa.dto.request.CreateOrderRequest;
import com.aether.borsa.dto.response.OrderResponse;
import com.aether.borsa.service.TradeService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/trades")
@RequiredArgsConstructor
public class TradeController {
    private final TradeService tradeService;

    @GetMapping("/active")
    public ResponseEntity<List<OrderResponse>> getActiveOrders(Authentication authentication) {
        UUID user = getUserId(authentication);
        return ResponseEntity.ok(tradeService.getActiveOrders(user));
    }

    @PostMapping("/order")
    public ResponseEntity<OrderResponse> createOrder(Authentication authentication, @RequestBody @Valid CreateOrderRequest request) {
        UUID user = getUserId(authentication);
        return ResponseEntity.status(201).body(tradeService.createOrder(user, request));
    }

    @PostMapping("/{id}/close")
    public ResponseEntity<OrderResponse> closeOrder(Authentication authentication, @PathVariable UUID id) {
        UUID user = getUserId(authentication);
        return ResponseEntity.ok(tradeService.closeOrder(user , id));
    }

    private UUID getUserId(Authentication authentication) {
        return UUID.fromString(authentication.getName());
    }

}