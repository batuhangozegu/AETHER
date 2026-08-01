package com.aether.borsa.controller;


import com.aether.borsa.dto.request.ForgotPasswordRequest;
import com.aether.borsa.dto.request.LoginRequest;
import com.aether.borsa.dto.request.RefreshTokenRequest;
import com.aether.borsa.dto.request.RegisterRequest;
import com.aether.borsa.dto.request.ResetPasswordRequest;
import com.aether.borsa.dto.request.TwoFactorCodeRequest;
import com.aether.borsa.dto.response.ForgotPasswordResponse;
import com.aether.borsa.dto.response.TokenResponse;
import com.aether.borsa.dto.response.TwoFactorSetupResponse;
import com.aether.borsa.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @PostMapping("/register")
    public ResponseEntity<TokenResponse> register(@RequestBody @Valid RegisterRequest request){
        return ResponseEntity.status(201).body(authService.register(request));
    }

    @PostMapping("/login")
    public ResponseEntity<TokenResponse> login(@RequestBody @Valid LoginRequest request){
        return ResponseEntity.ok(authService.login(request));
    }

    @PostMapping("/refresh")
    public ResponseEntity<TokenResponse> refresh(@RequestBody @Valid RefreshTokenRequest request){
        return ResponseEntity.ok(authService.refresh(request.getRefreshToken()));
    }

    @PostMapping("/forgot-password")
    public ResponseEntity<ForgotPasswordResponse> forgotPassword(@RequestBody @Valid ForgotPasswordRequest request) {
        return ResponseEntity.ok(authService.forgotPassword(request.getEmail()));
    }

    @PostMapping("/reset-password")
    public ResponseEntity<Void> resetPassword(@RequestBody @Valid ResetPasswordRequest request) {
        authService.resetPassword(request.getToken(), request.getNewPassword());
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/2fa/setup")
    public ResponseEntity<TwoFactorSetupResponse> setup2fa(Authentication authentication) {
        return ResponseEntity.ok(authService.setup2fa(getUserId(authentication)));
    }

    @PostMapping("/2fa/enable")
    public ResponseEntity<Void> enable2fa(Authentication authentication, @RequestBody @Valid TwoFactorCodeRequest request) {
        authService.enable2fa(getUserId(authentication), request.getCode());
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/2fa/disable")
    public ResponseEntity<Void> disable2fa(Authentication authentication, @RequestBody @Valid TwoFactorCodeRequest request) {
        authService.disable2fa(getUserId(authentication), request.getCode());
        return ResponseEntity.noContent().build();
    }

    private UUID getUserId(Authentication authentication) {
        return UUID.fromString(authentication.getName());
    }

}
