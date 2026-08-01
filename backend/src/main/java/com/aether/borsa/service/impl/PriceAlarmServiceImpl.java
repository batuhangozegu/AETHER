package com.aether.borsa.service.impl;

import com.aether.borsa.dto.request.CreatePriceAlarmRequest;
import com.aether.borsa.dto.response.PriceAlarmResponse;
import com.aether.borsa.model.entity.PriceAlarm;
import com.aether.borsa.model.entity.User;
import com.aether.borsa.model.enums.AlarmDirection;
import com.aether.borsa.repository.PriceAlarmRepository;
import com.aether.borsa.repository.UserRepository;
import com.aether.borsa.service.NotificationService;
import com.aether.borsa.service.PriceAlarmService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class PriceAlarmServiceImpl implements PriceAlarmService {

    private final PriceAlarmRepository priceAlarmRepository;
    private final UserRepository userRepository;
    private final NotificationService notificationService;

    @Override
    public List<PriceAlarmResponse> getAlarms(UUID userId) {
        User user = userRepository.findById(userId).orElseThrow(() -> new RuntimeException("User not found."));
        return priceAlarmRepository.findByUser(user).stream()
                .map(this::toResponse)
                .toList();
    }

    @Override
    public PriceAlarmResponse createAlarm(UUID userId, CreatePriceAlarmRequest request) {
        User user = userRepository.findById(userId).orElseThrow(() -> new RuntimeException("User not found."));
        PriceAlarm alarm = PriceAlarm.builder()
                .user(user)
                .symbol(request.getSymbol().toUpperCase())
                .targetPrice(request.getTargetPrice())
                .direction(request.getDirection())
                .build();
        return toResponse(priceAlarmRepository.save(alarm));
    }

    @Override
    public void deleteAlarm(UUID userId, UUID alarmId) {
        PriceAlarm alarm = priceAlarmRepository.findById(alarmId)
                .orElseThrow(() -> new RuntimeException("Price alarm not found."));
        if (!alarm.getUser().getId().equals(userId)) {
            throw new RuntimeException("Access denied: this price alarm does not belong to you.");
        }
        priceAlarmRepository.delete(alarm);
    }

    @Override
    public void checkAlarms(String symbol, BigDecimal currentPrice) {
        List<PriceAlarm> candidates = priceAlarmRepository.findBySymbolAndTriggeredFalse(symbol);
        for (PriceAlarm alarm : candidates) {
            boolean crossed = alarm.getDirection() == AlarmDirection.ABOVE
                    ? currentPrice.compareTo(alarm.getTargetPrice()) >= 0
                    : currentPrice.compareTo(alarm.getTargetPrice()) <= 0;
            if (!crossed) continue;

            alarm.setTriggered(true);
            priceAlarmRepository.save(alarm);

            String directionText = alarm.getDirection() == AlarmDirection.ABOVE ? "üzerine çıktı" : "altına düştü";
            notificationService.notify(
                    alarm.getUser(),
                    "alert",
                    alarm.getSymbol() + " $" + alarm.getTargetPrice() + " " + directionText,
                    "Güncel fiyat: $" + currentPrice
            );
        }
    }

    private PriceAlarmResponse toResponse(PriceAlarm alarm) {
        return new PriceAlarmResponse(
                alarm.getId(), alarm.getSymbol(), alarm.getTargetPrice(),
                alarm.getDirection(), alarm.isTriggered(), alarm.getCreatedAt()
        );
    }
}
