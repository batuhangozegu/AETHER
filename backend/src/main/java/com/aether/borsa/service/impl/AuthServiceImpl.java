package com.aether.borsa.service.impl;

import com.aether.borsa.dto.request.LoginRequest;
import com.aether.borsa.dto.request.RegisterRequest;
import com.aether.borsa.dto.response.ForgotPasswordResponse;
import com.aether.borsa.dto.response.TokenResponse;
import com.aether.borsa.dto.response.TwoFactorSetupResponse;
import com.aether.borsa.model.entity.PasswordResetToken;
import com.aether.borsa.model.entity.User;
import com.aether.borsa.repository.PasswordResetTokenRepository;
import com.aether.borsa.repository.UserRepository;
import com.aether.borsa.security.JwtTokenProvider;
import com.aether.borsa.service.AuthService;
import com.aether.borsa.util.TotpUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Base64;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AuthServiceImpl implements AuthService {

    private static final long RESET_TOKEN_TTL_MINUTES = 30;
    private static final String TOTP_ISSUER = "AETHER";

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;
    private final PasswordResetTokenRepository passwordResetTokenRepository;
    private final TotpUtil totpUtil;

    @Override
    public TokenResponse register(RegisterRequest request) {
        if(userRepository.existsByEmail(request.getEmail()) || userRepository.existsByUsername(request.getUsername()) )
        {
            throw new RuntimeException("This email or username is already in use.");
        }
        User user = User.builder()
                .username(request.getUsername())
                .email(request.getEmail())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .build();

        userRepository.save(user);

       String token = jwtTokenProvider.generateToken(user.getId());
       String refreshToken = jwtTokenProvider.generateRefreshToken(user.getId());
       return new TokenResponse(token, refreshToken, "Bearer" , jwtTokenProvider.getExpiration());
    }

    @Override
    public TokenResponse login(LoginRequest request) {

        User  user = userRepository.findByEmail(request.getEmail()).orElseThrow(() -> new RuntimeException("No account found with this email."));
        if(!passwordEncoder.matches(request.getPassword(), user.getPasswordHash()))
        {
            throw new RuntimeException("Incorrect password.");
        }

        if (user.isTwoFaEnabled()) {
            if (request.getTwoFactorCode() == null || request.getTwoFactorCode().isBlank()) {
                throw new RuntimeException("2FA code required.");
            }
            if (!totpUtil.verifyCode(user.getTwoFaSecret(), request.getTwoFactorCode())) {
                throw new RuntimeException("Invalid 2FA code.");
            }
        }

        String token = jwtTokenProvider.generateToken(user.getId());
        String refreshToken = jwtTokenProvider.generateRefreshToken(user.getId());
        return new TokenResponse(token, refreshToken, "Bearer", jwtTokenProvider.getExpiration());
    }

    @Override
    public TokenResponse refresh(String refreshToken) {
        if (!jwtTokenProvider.validateToken(refreshToken) || !jwtTokenProvider.isRefreshToken(refreshToken)) {
            throw new RuntimeException("Invalid or expired refresh token.");
        }

        UUID userId = UUID.fromString(jwtTokenProvider.getUserIdFromJWT(refreshToken));
        userRepository.findById(userId).orElseThrow(() -> new RuntimeException("User not found."));

        String newToken = jwtTokenProvider.generateToken(userId);
        String newRefreshToken = jwtTokenProvider.generateRefreshToken(userId);
        return new TokenResponse(newToken, newRefreshToken, "Bearer", jwtTokenProvider.getExpiration());
    }

    @Override
    public ForgotPasswordResponse forgotPassword(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("No account found with this email."));

        byte[] randomBytes = new byte[32];
        new SecureRandom().nextBytes(randomBytes);
        String token = Base64.getUrlEncoder().withoutPadding().encodeToString(randomBytes);

        PasswordResetToken resetToken = PasswordResetToken.builder()
                .user(user)
                .token(token)
                .expiresAt(LocalDateTime.now().plusMinutes(RESET_TOKEN_TTL_MINUTES))
                .build();
        passwordResetTokenRepository.save(resetToken);

        // No email/SMS provider is configured yet, so the token is handed back
        // directly for now — see ForgotPasswordResponse javadoc.
        return new ForgotPasswordResponse(
                "Reset token issued. Email delivery is not configured yet.",
                token,
                RESET_TOKEN_TTL_MINUTES * 60
        );
    }

    @Override
    public void resetPassword(String token, String newPassword) {
        PasswordResetToken resetToken = passwordResetTokenRepository.findByToken(token)
                .orElseThrow(() -> new RuntimeException("Invalid or expired reset token."));

        if (resetToken.isUsed() || resetToken.getExpiresAt().isBefore(LocalDateTime.now())) {
            throw new RuntimeException("Invalid or expired reset token.");
        }

        User user = resetToken.getUser();
        user.setPasswordHash(passwordEncoder.encode(newPassword));
        userRepository.save(user);

        resetToken.setUsed(true);
        passwordResetTokenRepository.save(resetToken);
    }

    @Override
    public TwoFactorSetupResponse setup2fa(UUID userId) {
        User user = userRepository.findById(userId).orElseThrow(() -> new RuntimeException("User not found."));

        String secret = totpUtil.generateSecret();
        user.setTwoFaSecret(secret);
        userRepository.save(user);

        String otpAuthUrl = totpUtil.buildOtpAuthUrl(secret, user.getEmail(), TOTP_ISSUER);
        return new TwoFactorSetupResponse(secret, otpAuthUrl);
    }

    @Override
    public void enable2fa(UUID userId, String code) {
        User user = userRepository.findById(userId).orElseThrow(() -> new RuntimeException("User not found."));

        if (user.getTwoFaSecret() == null) {
            throw new RuntimeException("Call /2fa/setup first.");
        }
        if (!totpUtil.verifyCode(user.getTwoFaSecret(), code)) {
            throw new RuntimeException("Invalid 2FA code.");
        }

        user.setTwoFaEnabled(true);
        userRepository.save(user);
    }

    @Override
    public void disable2fa(UUID userId, String code) {
        User user = userRepository.findById(userId).orElseThrow(() -> new RuntimeException("User not found."));

        if (!user.isTwoFaEnabled()) {
            return;
        }
        if (!totpUtil.verifyCode(user.getTwoFaSecret(), code)) {
            throw new RuntimeException("Invalid 2FA code.");
        }

        user.setTwoFaEnabled(false);
        user.setTwoFaSecret(null);
        userRepository.save(user);
    }
}
