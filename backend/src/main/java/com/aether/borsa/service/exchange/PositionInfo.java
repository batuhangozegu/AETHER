package com.aether.borsa.service.exchange;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.math.BigDecimal;

/**
 * Borsanın futures pozisyon endpoint'inden okunan gerçek pozisyon durumu.
 * `liquidationPrice` borsanın kendi hesapladığı değerdir — bakım marjı
 * kademeleri borsaya/notional büyüklüğe göre değiştiği için kendi
 * formülümüzü uydurmak yerine bu tek doğru kaynak kullanılır.
 */
@Getter
@AllArgsConstructor
public class PositionInfo {
    private BigDecimal liquidationPrice;
    private BigDecimal markPrice;
    private BigDecimal positionAmt;
}
