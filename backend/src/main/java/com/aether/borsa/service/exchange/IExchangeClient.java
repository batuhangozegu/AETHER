package com.aether.borsa.service.exchange;

import java.math.BigDecimal;
import java.util.Map;

public interface IExchangeClient {

    BigDecimal getBalance(String apiKey, String secretKey, String assest);
    BigDecimal getCurrentPrice(String symbol);
    Map<String, BigDecimal> getAllBalances(String apiKey, String secretKey);
}
