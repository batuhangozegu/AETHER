package com.aether.borsa.controller;

import com.aether.borsa.dto.response.AssetAllocationResponse;
import com.aether.borsa.dto.response.PortfolioSummaryResponse;
import com.aether.borsa.service.PortfolioService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/portfolio")
@RequiredArgsConstructor
public class PortfolioController {
    private final PortfolioService portfolioService;

    @GetMapping("/summary")
    public ResponseEntity<PortfolioSummaryResponse> getSummary(Authentication authentication, @RequestParam UUID exchangeKeyId) {
        UUID userId = getUserId(authentication);

        return ResponseEntity.ok(portfolioService.getSummary(userId, exchangeKeyId));
    }

    @GetMapping("/breakdown")
    public ResponseEntity<List<AssetAllocationResponse>> getBreakdown(Authentication authentication, @RequestParam UUID exchangeKeyId) {
        UUID userId = getUserId(authentication);

        return ResponseEntity.ok(portfolioService.getBreakdown(userId,exchangeKeyId));
    }

    private UUID getUserId(Authentication authentication) {
        return UUID.fromString(authentication.getName());
    }


}