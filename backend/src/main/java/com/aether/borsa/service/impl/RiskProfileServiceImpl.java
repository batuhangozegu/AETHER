package com.aether.borsa.service.impl;

import com.aether.borsa.dto.request.RiskCalculationRequest;
import com.aether.borsa.dto.request.RiskProfileRequest;
import com.aether.borsa.dto.response.AssetAllocationResponse;
import com.aether.borsa.dto.response.RiskCalculationResponse;
import com.aether.borsa.dto.response.RiskProfileResponse;
import com.aether.borsa.model.entity.ExchangeKey;
import com.aether.borsa.model.entity.RiskProfile;
import com.aether.borsa.model.entity.User;
import com.aether.borsa.repository.ExchangeKeyRepository;
import com.aether.borsa.repository.RiskProfileRepository;
import com.aether.borsa.repository.UserRepository;
import com.aether.borsa.service.ExchangeService;
import com.aether.borsa.service.RiskProfileService;
import com.aether.borsa.service.exchange.ExchangeClientFactory;
import com.aether.borsa.service.exchange.IExchangeClient;
import lombok.RequiredArgsConstructor;
import org.knowm.xchange.Exchange;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class RiskProfileServiceImpl implements RiskProfileService {

    private final RiskProfileRepository riskProfileRepository;
    private final UserRepository userRepository;
    private final ExchangeService exchangeService;
    private final ExchangeKeyRepository exchangeKeyRepository;
    private final ExchangeClientFactory exchangeClientFactory;

    @Override
    public RiskProfileResponse getProfile(UUID userId) {

        RiskProfile profile = findOrCreateProfile(userId);

        return mapToResponse(profile);
    }

    @Override
    public RiskProfileResponse updateProfile(UUID userId, RiskProfileRequest request) {
        RiskProfile profile = findOrCreateProfile(userId);

        profile.setDailyLossCapPct(request.getDailyLossCapPct());
        profile.setRiskPerTradePct(request.getRiskPerTradePct());
        profile.setTargetRr(request.getTargetRr());
        profile.setAutoStopLossEnabled(request.isAutoStopLossEnabled());
        profile.setMaxOpenPositions(request.getMaxOpenPositions());

        RiskProfile updated = riskProfileRepository.save(profile);
        return mapToResponse(updated);
    }

    @Override
    public RiskCalculationResponse calculateRisk(UUID userId, RiskCalculationRequest request) {
        RiskProfile profile = findOrCreateProfile(userId);

        // 1. Risk yüzdesini orana çevir: örn 2.0 -> 0.02
        BigDecimal riskFraction = profile.getRiskPerTradePct()
                .divide(new BigDecimal("100"), 10, RoundingMode.HALF_UP);

        // 2. Riske edilecek dolar miktarı: kasa * oran
        BigDecimal riskAmountUsd = request.getAccountBalance().multiply(riskFraction);

        // 3. Giriş ve stop fiyatı arasındaki mutlak fark
        BigDecimal priceDiff = request.getEntryPrice()
                .subtract(request.getStopLossPrice())
                .abs();

        // 4. Önerilen miktar: risk tutarı / fiyat farkı
        BigDecimal suggestedAmount = riskAmountUsd
                .divide(priceDiff, 8, RoundingMode.HALF_UP);

        return new RiskCalculationResponse(
                suggestedAmount,
                riskAmountUsd,
                profile.getRiskPerTradePct()
        );
    }

    private RiskProfile createDefaultProfile(UUID userId){
        User user = userRepository.findById(userId).orElseThrow(() -> new RuntimeException("Kullanıcı Bulunamadı"));
        RiskProfile riskProfile = RiskProfile.builder()
                .user(user)
                .riskPerTradePct(new BigDecimal("2.0"))
                .dailyLossCapPct(new BigDecimal("5.0"))
                .targetRr(new BigDecimal("2.0"))
                .autoStopLossEnabled(false)
                .maxOpenPositions(5)
                .build();

        return riskProfileRepository.save(riskProfile);
    }

    private RiskProfileResponse mapToResponse(RiskProfile profile) {
        return new RiskProfileResponse(
                profile.getUserId(),
                profile.getRiskPerTradePct(),
                profile.getDailyLossCapPct(),
                profile.getTargetRr(),
                profile.isAutoStopLossEnabled(),
                profile.getMaxOpenPositions()
        );
    }

    private RiskProfile findOrCreateProfile(UUID userId) {
        return riskProfileRepository.findById(userId)
                .orElseGet(() -> createDefaultProfile(userId));
    }

    private BigDecimal getUsdValue(String symbol, BigDecimal amount, IExchangeClient client) {
        if (symbol.equals("USDT")) {
            return amount;
        } else {

            BigDecimal price = client.getCurrentPrice(symbol + "USDT");
            BigDecimal total = price.multiply(amount);
            return total;

        }
    }

}
