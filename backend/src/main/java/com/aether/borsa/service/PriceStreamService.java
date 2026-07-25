package com.aether.borsa.service;

import com.aether.borsa.dto.response.PriceUpdateResponse;
import com.aether.borsa.service.exchange.BinanceExchangeClient;
import com.aether.borsa.service.exchange.SupportedCoins;
import lombok.RequiredArgsConstructor;
import org.knowm.xchange.binance.dto.meta.exchangeinfo.Symbol;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class PriceStreamService {

    private final BinanceExchangeClient binanceExchangeClient;
    private final RedisTemplate<String, String> redisTemplate;
    private final SimpMessagingTemplate messagingTemplate;

    @Scheduled(fixedRate = 5000)
    public void updatePrices() {
        for (String symbol : SupportedCoins.SYMBOLS) {
            try {
                BigDecimal price = binanceExchangeClient.getCurrentPrice(symbol + "USDT");

                redisTemplate.opsForValue().set("price:" + symbol, price.toString());

                messagingTemplate.convertAndSend("/topic/prices", new PriceUpdateResponse(symbol, price));

            } catch (Exception e) {
                System.out.println("Fiyat güncellenemedi: " + symbol + " - " + e.getMessage());
            }
        }
    }

}
