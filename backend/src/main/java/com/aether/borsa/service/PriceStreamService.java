package com.aether.borsa.service;

import com.aether.borsa.dto.response.PriceUpdateResponse;
import com.aether.borsa.service.exchange.BinanceExchangeClient;
import com.aether.borsa.service.exchange.SupportedCoins;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;

@Slf4j
@Service
@RequiredArgsConstructor
public class PriceStreamService {

    private final BinanceExchangeClient binanceExchangeClient;
    private final RedisTemplate<String, String> redisTemplate;
    private final SimpMessagingTemplate messagingTemplate;
    private final PriceAlarmService priceAlarmService;

    @Scheduled(fixedRate = 5000)
    public void updatePrices() {
        for (String symbol : SupportedCoins.SYMBOLS) {
            try {
                BigDecimal price = binanceExchangeClient.getCurrentPrice(symbol + "USDT");

                redisTemplate.opsForValue().set("price:" + symbol, price.toString());

                messagingTemplate.convertAndSend("/topic/prices", new PriceUpdateResponse(symbol, price));

                priceAlarmService.checkAlarms(symbol, price);

            } catch (Exception e) {
                log.warn("Fiyat güncellenemedi: {} - {}", symbol, e.getMessage());
            }
        }
    }

}
