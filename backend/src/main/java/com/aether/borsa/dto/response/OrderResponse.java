package com.aether.borsa.dto.response;

import com.aether.borsa.model.enums.OrderStatus;
import com.aether.borsa.model.enums.TradeSide;
import lombok.AllArgsConstructor;
import lombok.Getter;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@AllArgsConstructor
public class OrderResponse {

    private UUID id;
    private String symbol;
    private TradeSide side;
    private BigDecimal amount;
    private OrderStatus status;
    private BigDecimal currentPnL;
    private LocalDateTime createdAt;
    private LocalDateTime closedAt;

}
