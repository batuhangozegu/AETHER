package com.aether.borsa.controller;
import com.aether.borsa.dto.response.CoinResponse;
import com.aether.borsa.service.MarketService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
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
}