package com.aether.borsa.controller;

import com.aether.borsa.dto.request.CreatePriceAlarmRequest;
import com.aether.borsa.dto.response.PriceAlarmResponse;
import com.aether.borsa.service.PriceAlarmService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/alarms")
@RequiredArgsConstructor
public class PriceAlarmController {

    private final PriceAlarmService priceAlarmService;

    @GetMapping
    public ResponseEntity<List<PriceAlarmResponse>> getAlarms(Authentication authentication) {
        return ResponseEntity.ok(priceAlarmService.getAlarms(getUserId(authentication)));
    }

    @PostMapping
    public ResponseEntity<PriceAlarmResponse> createAlarm(Authentication authentication, @RequestBody @Valid CreatePriceAlarmRequest request) {
        return ResponseEntity.status(201).body(priceAlarmService.createAlarm(getUserId(authentication), request));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteAlarm(Authentication authentication, @PathVariable UUID id) {
        priceAlarmService.deleteAlarm(getUserId(authentication), id);
        return ResponseEntity.noContent().build();
    }

    private UUID getUserId(Authentication authentication) {
        return UUID.fromString(authentication.getName());
    }
}
