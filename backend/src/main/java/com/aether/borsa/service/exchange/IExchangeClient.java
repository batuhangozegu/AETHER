package com.aether.borsa.service.exchange;

import com.aether.borsa.dto.response.CandleResponse;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

public interface IExchangeClient {

    BigDecimal getBalance(String apiKey, String secretKey, String assest);
    BigDecimal getCurrentPrice(String symbol);
    Map<String, BigDecimal> getAllBalances(String apiKey, String secretKey);
    TickerInfo getTickerInfo(String symbol);
    List<CandleResponse> getCandles(String symbol, String timeframe);
}
