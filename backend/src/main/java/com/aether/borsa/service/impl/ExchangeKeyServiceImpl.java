package com.aether.borsa.service.impl;

import com.aether.borsa.dto.request.AddExchangeKeyRequest;
import com.aether.borsa.dto.request.UpdateExchangeKeyRequest;
import com.aether.borsa.dto.response.ExchangeKeyResponse;
import com.aether.borsa.model.entity.ExchangeKey;
import com.aether.borsa.model.entity.User;
import com.aether.borsa.repository.ExchangeKeyRepository;
import com.aether.borsa.repository.UserRepository;
import com.aether.borsa.service.ExchangeKeyService;
import com.aether.borsa.util.EncryptionUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.security.Key;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class ExchangeKeyServiceImpl implements ExchangeKeyService {

    private final UserRepository userRepository;
    private final ExchangeKeyRepository exchangeKeyRepository;
    private final EncryptionUtil encryptionUtil;


    @Override
    public ExchangeKeyResponse addExchangeKey(UUID userId, AddExchangeKeyRequest request) throws Exception {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found."));

        String encryptedApiKey = encryptionUtil.encrypt(request.getApiKey());
        String encryptedSecretKey = encryptionUtil.encrypt(request.getSecretKey());

        String maskedApiKey = maskApiKey(request.getApiKey());

        ExchangeKey exchangeKey = ExchangeKey.builder()
                .user(user)
                .exchangeName(request.getExchangeName())
                .encryptedApiKey(encryptedApiKey)
                .encryptedSecretKey(encryptedSecretKey)
                .maskedApiKey(maskedApiKey)
                .canRead(request.isCanRead())
                .canTrade(request.isCanTrade())
                .build();
        exchangeKeyRepository.save(exchangeKey);

        return new ExchangeKeyResponse(
                exchangeKey.getId(),
                exchangeKey.getExchangeName(),
                maskedApiKey,
                exchangeKey.isCanRead(),
                exchangeKey.isCanTrade(),
                "ACTIVE"
        );
    }

    @Override
    public List<ExchangeKeyResponse> getExchangeKeys(UUID userId) {

        User user = userRepository.findById(userId).orElseThrow(() -> new RuntimeException("User not found."));
        List<ExchangeKey> keyList = exchangeKeyRepository.findByUser(user);

        return keyList.stream()
                .map(key -> new ExchangeKeyResponse(
                        key.getId(),
                        key.getExchangeName(),
                        key.getMaskedApiKey(),
                        key.isCanRead(),
                        key.isCanTrade(),
                        "ACTIVE"
                )).toList();
    }

    @Override
    public void deleteExchangeKeys(UUID userId, UUID keyId) {
        ExchangeKey exchangeKey = exchangeKeyRepository.findById(keyId)
                .orElseThrow(() -> new RuntimeException("Exchange key not found."));

        if(!exchangeKey.getUser().getId().equals(userId)){
            throw new RuntimeException("Access denied: this exchange key does not belong to you.");
        }
        exchangeKeyRepository.delete(exchangeKey);
    }

    @Override
    public ExchangeKeyResponse updateExchangeKey(UUID userId, UUID keyId, UpdateExchangeKeyRequest request) throws Exception {
        ExchangeKey exchangeKey = exchangeKeyRepository.findById(keyId)
                .orElseThrow(() -> new RuntimeException("Exchange key not found."));

        if (!exchangeKey.getUser().getId().equals(userId)) {
            throw new RuntimeException("Access denied: this exchange key does not belong to you.");
        }

        String maskedApiKey = maskApiKey(request.getApiKey());

        exchangeKey.setEncryptedApiKey(encryptionUtil.encrypt(request.getApiKey()));
        exchangeKey.setEncryptedSecretKey(encryptionUtil.encrypt(request.getSecretKey()));
        exchangeKey.setMaskedApiKey(maskedApiKey);
        exchangeKey.setCanRead(request.isCanRead());
        exchangeKey.setCanTrade(request.isCanTrade());
        exchangeKeyRepository.save(exchangeKey);

        return new ExchangeKeyResponse(
                exchangeKey.getId(),
                exchangeKey.getExchangeName(),
                maskedApiKey,
                exchangeKey.isCanRead(),
                exchangeKey.isCanTrade(),
                "ACTIVE"
        );
    }

    private String maskApiKey(String apiKey){

        char[] CharApiKey = apiKey.toCharArray();

        for(int i = 0; i < CharApiKey.length - 4; i++) {
            CharApiKey[i] = '*';
        }

        return new String(CharApiKey);

    }

}
