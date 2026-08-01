package com.aether.borsa.service;

import com.aether.borsa.dto.request.CreatePriceAlarmRequest;
import com.aether.borsa.dto.response.PriceAlarmResponse;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

public interface PriceAlarmService {

    List<PriceAlarmResponse> getAlarms(UUID userId);
    PriceAlarmResponse createAlarm(UUID userId, CreatePriceAlarmRequest request);
    void deleteAlarm(UUID userId, UUID alarmId);

    /** Called by the price stream on every tick to fire any alarms crossed by the new price. */
    void checkAlarms(String symbol, BigDecimal currentPrice);
}
