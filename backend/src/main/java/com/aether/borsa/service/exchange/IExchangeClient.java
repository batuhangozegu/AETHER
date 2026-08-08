package com.aether.borsa.service.exchange;

import com.aether.borsa.dto.response.CandleResponse;
import com.aether.borsa.model.enums.MarginMode;
import com.aether.borsa.model.enums.TradeSide;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

public interface IExchangeClient {

    BigDecimal getBalance(String apiKey, String secretKey, String passphrase, String asset);
    BigDecimal getCurrentPrice(String symbol);
    Map<String, BigDecimal> getAllBalances(String apiKey, String secretKey, String passphrase);
    TickerInfo getTickerInfo(String symbol);
    List<CandleResponse> getCandles(String symbol, String timeframe);

    /**
     * Borsaya gerçek bir SPOT emri gönderir. {@code type} "MARKET" veya
     * "LIMIT" olmalı (LIMIT için {@code limitPrice} zorunlu). Spot
     * piyasalarda açığa satış (short) yoktur — bu metod sadece varlığı
     * satın almak/elden çıkarmak için kullanılır.
     */
    PlacedOrder placeSpotOrder(String apiKey, String secretKey, String passphrase,
                                String symbol, TradeSide side, String type,
                                BigDecimal amount, BigDecimal limitPrice);

    /** Açık (henüz gerçekleşmemiş) bir SPOT emrini borsada iptal eder. */
    void cancelSpotOrder(String apiKey, String secretKey, String passphrase,
                          String symbol, String exchangeOrderId);

    /**
     * Bir futures/perpetual sembolü için kaldıraç ve marjin modunu ayarlar.
     * Emir göndermeden önce çağrılmalı — kaldıraç pozisyon/sembol bazlı bir
     * ayardır, emrin kendisinin bir parçası değildir.
     */
    void setLeverage(String apiKey, String secretKey, String passphrase,
                      String symbol, int leverage, MarginMode marginMode);

    /**
     * Borsaya gerçek bir FUTURES (perpetual) emri gönderir. {@code reduceOnly}
     * true ise emir sadece mevcut pozisyonu azaltabilir/kapatabilir (yeni
     * pozisyon açmaz) — pozisyon kapatma akışında kullanılır.
     */
    PlacedOrder placeFuturesOrder(String apiKey, String secretKey, String passphrase,
                                   String symbol, TradeSide side, String type,
                                   BigDecimal amount, BigDecimal limitPrice, boolean reduceOnly);

    /** Borsanın kendi hesapladığı likidasyon fiyatı dahil güncel pozisyon bilgisini döner. */
    PositionInfo getPositionInfo(String apiKey, String secretKey, String passphrase, String symbol);
}
