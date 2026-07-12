package com.aether.borsa.service;

import com.aether.borsa.dto.request.AddExchangeKeyRequest;
import com.aether.borsa.dto.response.ExchangeKeyResponse;

import java.util.List;
import java.util.UUID;

public interface ExchangeKeyService {

    ExchangeKeyResponse addExchangeKey(UUID userId, AddExchangeKeyRequest request) throws Exception;
    List<ExchangeKeyResponse> getExchangeKeys(UUID userId);
    void deleteExchangeKeys(UUID userId, UUID keyId);
}
