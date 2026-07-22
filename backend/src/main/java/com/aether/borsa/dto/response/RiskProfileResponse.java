package com.aether.borsa.dto.response;

import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Getter;

import java.math.BigDecimal;
import java.util.UUID;

@Getter
@AllArgsConstructor
public class RiskProfileResponse {

    private UUID userId;
    private BigDecimal riskPerTradePct;
    private BigDecimal dailyLossCapPct;
    private BigDecimal targetRr;
    private Boolean autoStopLossEnabled;
    private Integer maxOpenPositions;

}
