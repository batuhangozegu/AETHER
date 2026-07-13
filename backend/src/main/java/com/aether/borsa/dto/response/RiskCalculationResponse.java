package com.aether.borsa.dto.response;


import lombok.AllArgsConstructor;
import lombok.Getter;

import java.math.BigDecimal;

@Getter
@AllArgsConstructor
public class RiskCalculationResponse {

    private BigDecimal suggestedAmount;
    private BigDecimal riskAmountUsd;
    private BigDecimal riskPercentage;
}
