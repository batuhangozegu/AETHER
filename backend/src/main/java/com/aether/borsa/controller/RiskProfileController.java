package com.aether.borsa.controller;


import com.aether.borsa.dto.request.RiskCalculationRequest;
import com.aether.borsa.dto.request.RiskProfileRequest;
import com.aether.borsa.dto.response.RiskCalculationResponse;
import com.aether.borsa.dto.response.RiskProfileResponse;
import com.aether.borsa.service.RiskProfileService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;


import java.util.UUID;

@RestController
@RequestMapping("/api/v1/risk")
@RequiredArgsConstructor
public class RiskProfileController {

    private final RiskProfileService riskProfileService;

    @GetMapping("/profile")
    public ResponseEntity<RiskProfileResponse> getRiskProfile(Authentication authentication) {

        UUID userId = getUserId(authentication);
        return ResponseEntity.ok(riskProfileService.getProfile(userId));
    }

    @PutMapping("/profile")
    public ResponseEntity<RiskProfileResponse> updateRiskProfile(Authentication authentication, @RequestBody @Valid RiskProfileRequest riskProfileRequest) {

        UUID userId = getUserId(authentication);
        return ResponseEntity.ok(riskProfileService.updateProfile(userId, riskProfileRequest));

    }

    @PostMapping("/calculate")
    public ResponseEntity<RiskCalculationResponse> calculateRisk(Authentication authentication, @RequestBody @Valid RiskCalculationRequest riskCalculationRequest){

        UUID userId = getUserId(authentication);
        return  ResponseEntity.ok(riskProfileService.calculateRisk(userId , riskCalculationRequest));

    }

    private UUID getUserId(Authentication authentication) {
        return UUID.fromString(authentication.getName());
    }
}
