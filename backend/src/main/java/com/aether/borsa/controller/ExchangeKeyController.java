package com.aether.borsa.controller;

import com.aether.borsa.dto.request.AddExchangeKeyRequest;
import com.aether.borsa.dto.response.ExchangeKeyResponse;
import com.aether.borsa.model.entity.ExchangeKey;
import com.aether.borsa.service.ExchangeKeyService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/exchanges")
@RequiredArgsConstructor
public class ExchangeKeyController {

    private final ExchangeKeyService exchangeKeyService;

    @GetMapping()
    public ResponseEntity<List<ExchangeKeyResponse>> getExchangeKeys(Authentication authentication){
        UUID userId = UUID.fromString(authentication.getName());
        return ResponseEntity.ok(exchangeKeyService.getExchangeKeys(userId));
    }

    @PostMapping
    public ResponseEntity<ExchangeKeyResponse> addExchangeKeys(Authentication authentication, @RequestBody @Valid AddExchangeKeyRequest request) throws Exception{
        UUID userId = UUID.fromString(authentication.getName());
        return ResponseEntity.status(201).body(exchangeKeyService.addExchangeKey(userId,request));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteExchangeKeys(Authentication authentication , @PathVariable UUID id){
        UUID userId = UUID.fromString(authentication.getName());
        exchangeKeyService.deleteExchangeKeys(userId, id);

        return ResponseEntity.noContent().build();
    }

}
