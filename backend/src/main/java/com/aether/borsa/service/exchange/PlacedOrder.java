package com.aether.borsa.service.exchange;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.math.BigDecimal;

/**
 * Borsaya gönderilen bir emrin sonucu. `filledPrice` MARKET emirlerde kesin
 * gerçekleşme fiyatı değil, emir anındaki güncel piyasa fiyatına yakın bir
 * yaklaşık değerdir (borsa fill-fiyatını sorgulamak yerine basitlik için) —
 * LIMIT emirlerde ise kullanıcının belirttiği fiyattır.
 */
@Getter
@AllArgsConstructor
public class PlacedOrder {
    private String exchangeOrderId;
    private BigDecimal filledPrice;
    private BigDecimal filledAmount;
    private String status;
}
