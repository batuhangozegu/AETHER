package com.aether.borsa.dto.response;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * No email/SMS delivery is wired up yet, so the reset token is returned
 * directly in the response as a temporary stand-in until a real mail
 * provider is configured. Do not ship this as-is to production.
 */
@Getter
@AllArgsConstructor
public class ForgotPasswordResponse {

    private String message;
    private String resetToken;
    private long expiresInSeconds;
}
