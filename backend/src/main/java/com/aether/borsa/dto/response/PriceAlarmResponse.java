package com.aether.borsa.dto.response;

import com.aether.borsa.model.enums.AlarmDirection;
import lombok.AllArgsConstructor;
import lombok.Getter;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@AllArgsConstructor
public class PriceAlarmResponse {

    private UUID id;
    private String symbol;
    private BigDecimal targetPrice;
    private AlarmDirection direction;
    private boolean triggered;
    private LocalDateTime createdAt;
}
