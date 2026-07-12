package com.aether.borsa.service;

import com.aether.borsa.dto.request.AddExchangeKeyRequest;
import com.aether.borsa.dto.response.ExchangeKeyResponse;
import com.aether.borsa.repository.ExchangeKeyRepository;

import java.util.List;
import java.util.UUID;

public interface ExchangeKeyService {

    ExchangeKeyRepository addExchangeKey(UUID userId, AddExchangeKeyRequest request);
    List<ExchangeKeyResponse> getExchangeKeys(UUID userId);
    void deleteExchangeKeys(UUID userId, UUID keyId);
}
