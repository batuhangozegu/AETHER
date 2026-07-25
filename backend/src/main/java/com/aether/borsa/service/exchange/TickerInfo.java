package com.aether.borsa.service.exchange;

import lombok.AllArgsConstructor;
import lombok.Getter;
import java.math.BigDecimal;

@Getter
@AllArgsConstructor
public class TickerInfo {
    private BigDecimal price;
    private BigDecimal priceChangePercent;
}