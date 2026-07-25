package com.aether.borsa.service;

import com.aether.borsa.dto.response.CandleResponse;
import com.aether.borsa.dto.response.CoinResponse;

import java.util.List;
import java.util.UUID;

public interface MarketService {

    List<CoinResponse> getCoins(UUID exchangeKeyId);
    List<CandleResponse> getCandles(UUID exchangeKeyId, String symbol, String timeframe);
}
