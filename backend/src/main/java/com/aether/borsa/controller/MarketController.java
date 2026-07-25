package com.aether.borsa.controller;
import com.aether.borsa.dto.response.CandleResponse;
import com.aether.borsa.dto.response.CoinResponse;
import com.aether.borsa.service.MarketService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;
@RestController
@RequestMapping("/api/v1/markets")
@RequiredArgsConstructor
public class MarketController {

    private final MarketService marketService;

    @GetMapping("/coins")
    public ResponseEntity<List<CoinResponse>> getCoins(@RequestParam UUID exchangeKeyId){
        return ResponseEntity.ok(marketService.getCoins(exchangeKeyId));
    }

    @GetMapping("/coins/{symbol}/history")
    public ResponseEntity<List<CandleResponse>> getHistory(
            @PathVariable String symbol,
            @RequestParam UUID exchangeKeyId,
            @RequestParam String timeframe) {

        return ResponseEntity.ok(marketService.getCandles(exchangeKeyId,symbol,timeframe));
    }
}