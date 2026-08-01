package com.aether.borsa.dto.response;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class TwoFactorSetupResponse {

    private String secret;
    private String otpAuthUrl;
}
