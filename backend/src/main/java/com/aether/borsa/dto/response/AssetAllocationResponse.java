package com.aether.borsa.dto.response;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.math.BigDecimal;

@Getter
@AllArgsConstructor
public class AssetAllocationResponse {

    private String symbol;
    private BigDecimal amount;
    private BigDecimal usdValue;
    private BigDecimal allocationPct;

}
