package com.aether.borsa.dto.response;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.math.BigDecimal;

@Getter
@AllArgsConstructor
public class CoinResponse {


    private String symbol;
    private BigDecimal price;
    private BigDecimal priceChangePercent;

}
