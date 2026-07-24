package com.aether.borsa.dto.response;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.math.BigDecimal;

@Getter
@AllArgsConstructor
public class PortfolioSummaryResponse {

    private BigDecimal totalBalanceUsd;
    private BigDecimal dailyPnlUsd;
    private BigDecimal dailyPnlPct;
}
