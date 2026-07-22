package com.aether.borsa.service.exchange;

import java.math.BigDecimal;

public interface IExchangeClient {

    BigDecimal getBalance(String apiKey, String secretKey, String assest);
}
