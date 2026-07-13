package com.aether.borsa.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;

import java.math.BigDecimal;

@Getter
public class RiskCalculationRequest {

    @NotBlank(message = "Symbol boş olamaz")
    private String symbol;

    @NotNull
    private BigDecimal entryPrice;

    @NotNull
    private BigDecimal stopLossPrice;

    @NotNull
    private BigDecimal accountBalance;

}
