package com.aether.borsa.controller;

import com.aether.borsa.service.ExchangeService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/exchange")
@RequiredArgsConstructor
public class ExchangeController {
    private final ExchangeService exchangeService;

    @GetMapping("/{id}/balance")
    public ResponseEntity<BigDecimal> getBalance(Authentication authentication, @PathVariable UUID id, @RequestParam String asset){

        UUID userId = getUserId(authentication);
        return ResponseEntity.ok(exchangeService.getBalance(userId, id,asset));
    }

    private UUID getUserId(Authentication authentication){
        return UUID.fromString(authentication.getName());
    }
}
