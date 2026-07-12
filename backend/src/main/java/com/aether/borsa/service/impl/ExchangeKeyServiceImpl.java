package com.aether.borsa.service.impl;

import com.aether.borsa.dto.request.AddExchangeKeyRequest;
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
                .orElseThrow(() -> new RuntimeException("Kullanıcı Bulunamadı"));

        String encryptedApiKey = encryptionUtil.encrypt(request.getApiKey());
        String encryptedSecretKey = encryptionUtil.encrypt(request.getSecretKey());

        ExchangeKey exchangeKey = ExchangeKey.builder()
                .user(user)
                .exchangeName(request.getExchangeName())
                .encryptedApiKey(encryptedApiKey)
                .encryptedSecretKey(encryptedSecretKey)
                .canRead(request.isCanRead())
                .canTrade(request.isCanTrade())
                .build();
        exchangeKeyRepository.save(exchangeKey);

        return new ExchangeKeyResponse(
                exchangeKey.getId(),
                exchangeKey.getExchangeName(),
                maskApiKey(encryptedApiKey),
                exchangeKey.isCanRead(),
                exchangeKey.isCanTrade(),
                "ACTIVE"
        );
    }

    @Override
    public List<ExchangeKeyResponse> getExchangeKeys(UUID userId) {

        User user = userRepository.findById(userId).orElseThrow(() -> new RuntimeException("Kullanıcı Bulunamadı"));
        List<ExchangeKey> keyList = exchangeKeyRepository.findByUser(user);

        return keyList.stream()
                .map(key -> new ExchangeKeyResponse(
                        key.getId(),
                        key.getExchangeName(),
                        maskApiKey(key.getEncryptedApiKey()),
                        key.isCanRead(),
                        key.isCanTrade(),
                        "ACTİVE"
                )).toList();
    }

    @Override
    public void deleteExchangeKeys(UUID userId, UUID keyId) {
        ExchangeKey exchangeKey = exchangeKeyRepository.findById(keyId)
                .orElseThrow(() -> new RuntimeException("Key Bulunamadı"));

        if(!exchangeKey.getUser().getId().equals(userId)){
            throw new RuntimeException("Bu Key Size Ait Değil");
        }
        exchangeKeyRepository.delete(exchangeKey);
    }

    private String maskApiKey(String apiKey){

        char[] CharApiKey = apiKey.toCharArray();

        for(int i = 0; i < CharApiKey.length - 4; i++) {
            CharApiKey[i] = '*';
        }

        return new String(CharApiKey);

    }

}
