package com.aether.borsa.service.impl;

import com.aether.borsa.dto.response.CandleResponse;
import com.aether.borsa.dto.response.CoinResponse;
import com.aether.borsa.model.entity.ExchangeKey;
import com.aether.borsa.repository.ExchangeKeyRepository;
import com.aether.borsa.service.MarketService;
import com.aether.borsa.service.exchange.ExchangeClientFactory;
import com.aether.borsa.service.exchange.IExchangeClient;
import com.aether.borsa.service.exchange.SupportedCoins;
import com.aether.borsa.service.exchange.TickerInfo;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class MarketServiceImpl implements MarketService {

    private final ExchangeKeyRepository exchangeKeyRepository;
    private final ExchangeClientFactory exchangeClientFactory;

    @Override
    public List<CoinResponse> getCoins(UUID exchangeKeyId) {

        ExchangeKey exchangeKey = exchangeKeyRepository.findById(exchangeKeyId).orElseThrow(() -> new RuntimeException("Borsa bağlantısı bulunamadı."));

        IExchangeClient client = exchangeClientFactory.getClient(exchangeKey.getExchangeName());
        return SupportedCoins.SYMBOLS.stream()
                .map(symbol -> {
                    TickerInfo info = client.getTickerInfo(symbol + "USDT");
                    return new CoinResponse(symbol, info.getPrice(), info.getPriceChangePercent());
                }).toList();
    }

    @Override
    public List<CandleResponse> getCandles(UUID exchangeKeyId, String symbol, String timeframe) {
        ExchangeKey exchangeKey = exchangeKeyRepository.findById(exchangeKeyId)
                .orElseThrow(() -> new RuntimeException("Borsa bağlantısı bulunamadı."));

        IExchangeClient client = exchangeClientFactory.getClient(exchangeKey.getExchangeName());

        return client.getCandles(symbol, timeframe);
    }
}
