package com.aether.borsa.service.impl;

import com.aether.borsa.model.entity.ExchangeKey;
import com.aether.borsa.repository.ExchangeKeyRepository;
import com.aether.borsa.service.ExchangeService;
import com.aether.borsa.service.exchange.ExchangeClientFactory;
import com.aether.borsa.service.exchange.IExchangeClient;
import com.aether.borsa.util.EncryptionUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class ExchangeServiceImpl implements ExchangeService {

    private final ExchangeKeyRepository exchangeKeyRepository;
    private final EncryptionUtil encryptionUtil;
    private final ExchangeClientFactory exchangeClientFactory;

    @Override
    public BigDecimal getBalance(UUID userId, UUID exchangeKeyId, String asset) {

        ExchangeKey exchangeKey = exchangeKeyRepository.findById(exchangeKeyId).orElseThrow(() -> new RuntimeException("Borsa bağlantısı bulunamadı."));

        if(!exchangeKey.getUser().getId().equals(userId)){
            throw new RuntimeException("Bu borsa bağlantısına erişim yetkiniz yok.");
        }

        try {

            String apiKey = encryptionUtil.decrypt(exchangeKey.getEncryptedApiKey());
            String secretKey = encryptionUtil.decrypt(exchangeKey.getEncryptedSecretKey());

            IExchangeClient client = exchangeClientFactory.getClient(exchangeKey.getExchangeName());
            return client.getBalance(apiKey, secretKey, asset);
        } catch (Exception e){
            throw new RuntimeException("Şifre çözme işlemi başarısız:" + e.getMessage());
        }

    }
}
