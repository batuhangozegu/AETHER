package com.aether.borsa.service;

import com.aether.borsa.dto.request.RiskCalculationRequest;
import com.aether.borsa.dto.request.RiskProfileRequest;
import com.aether.borsa.dto.response.AssetAllocationResponse;
import com.aether.borsa.dto.response.RiskCalculationResponse;
import com.aether.borsa.dto.response.RiskProfileResponse;

import java.util.List;
import java.util.UUID;

public interface RiskProfileService {
    RiskProfileResponse getProfile(UUID userId);
    RiskProfileResponse updateProfile(UUID userId, RiskProfileRequest request);
    RiskCalculationResponse calculateRisk(UUID userId, RiskCalculationRequest request);

}