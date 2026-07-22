package com.aether.borsa.dto.request;

import jakarta.validation.constraints.NotNull;
import lombok.Getter;

import java.math.BigDecimal;

@Getter
public class RiskProfileRequest {

    @NotNull
    private BigDecimal riskPerTradePct;

    @NotNull
    private BigDecimal dailyLossCapPct;

    @NotNull
    private BigDecimal targetRr;

    private boolean autoStopLossEnabled;

    private Integer maxOpenPositions;
}
