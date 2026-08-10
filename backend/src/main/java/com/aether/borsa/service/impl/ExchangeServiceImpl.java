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
import java.util.Map;
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

        DecryptedCredentials creds = decryptCredentials(exchangeKey);
        IExchangeClient client = exchangeClientFactory.getClient(exchangeKey.getExchangeName());
        return client.getBalance(creds.apiKey(), creds.secretKey(), creds.passphrase(), asset);
    }

    @Override
    public Map<String, BigDecimal> getAllBalances(UUID userId, UUID exchangeKeyId) {

        ExchangeKey exchangeKey = exchangeKeyRepository.findById(exchangeKeyId).orElseThrow(() -> new RuntimeException("Borsa bağlantısı bulunamadı."));

        if(!exchangeKey.getUser().getId().equals(userId)){
            throw new RuntimeException("Bu borsa bağlantısına erişim yetkiniz yok.");
        }

        DecryptedCredentials creds = decryptCredentials(exchangeKey);
        IExchangeClient client = exchangeClientFactory.getClient(exchangeKey.getExchangeName());
        return client.getAllBalances(creds.apiKey(), creds.secretKey(), creds.passphrase());
    }

    /**
     * Şifre çözme (AES) ile asıl borsa API çağrısını ayrı hata alanlarında
     * tutar. Eskiden ikisi aynı try/catch içindeydi ve hangisi patlarsa
     * patlasın kullanıcıya hep "Şifre çözme işlemi başarısız" gösteriliyordu
     * — yanlış API anahtarı/IP whitelist/imza gibi gerçek borsa hatalarını da
     * şifreleme sorunuymuş gibi maskeliyordu. Şifre çözme burada gerçekten
     * patlarsa (örn. encryption.secret-key kayıt anındakinden farklı), sebep
     * aynı kalıyor ama kullanıcıya somut bir aksiyon öneriliyor.
     */
    private DecryptedCredentials decryptCredentials(ExchangeKey exchangeKey) {
        try {
            String apiKey = encryptionUtil.decrypt(exchangeKey.getEncryptedApiKey());
            String secretKey = encryptionUtil.decrypt(exchangeKey.getEncryptedSecretKey());
            String passphrase = exchangeKey.getEncryptedPassphrase() != null
                    ? encryptionUtil.decrypt(exchangeKey.getEncryptedPassphrase())
                    : null;
            return new DecryptedCredentials(apiKey, secretKey, passphrase);
        } catch (Exception e) {
            throw new RuntimeException(
                    "Şifre çözme işlemi başarısız — bu API anahtarı, sunucudaki şifreleme " +
                    "anahtarı (ENCRYPTION_SECRET_KEY) değiştikten önce kaydedilmiş olabilir. " +
                    "Borsa anahtarını silip yeniden ekleyin.");
        }
    }

    private record DecryptedCredentials(String apiKey, String secretKey, String passphrase) {}
}
