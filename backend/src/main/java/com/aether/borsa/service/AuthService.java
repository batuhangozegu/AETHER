package com.aether.borsa.service;

import com.aether.borsa.dto.request.LoginRequest;
import com.aether.borsa.dto.request.RegisterRequest;
import com.aether.borsa.dto.response.ForgotPasswordResponse;
import com.aether.borsa.dto.response.TokenResponse;
import com.aether.borsa.dto.response.TwoFactorSetupResponse;

import java.util.UUID;

public interface AuthService {

    TokenResponse register(RegisterRequest request);
    TokenResponse login(LoginRequest request);
    TokenResponse refresh(String refreshToken);

    ForgotPasswordResponse forgotPassword(String email);
    void resetPassword(String token, String newPassword);

    TwoFactorSetupResponse setup2fa(UUID userId);
    void enable2fa(UUID userId, String code);
    void disable2fa(UUID userId, String code);
}
