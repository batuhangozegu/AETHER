package com.aether.borsa.dto.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.Getter;

@Getter
public class LoginRequest {

    @NotBlank(message = "Email boş olamaz")
    @Email(message = "Geçerli bir email giriniz")
    private String email;

    @NotBlank(message = "Şifre boş olamaz")
    private String password;

    /** Only required when the account has 2FA enabled. */
    private String twoFactorCode;

    /**
     * "Oturumu açık tut" — true olursa refresh token kısa (7 gün) yerine
     * uzun ömürlü (application.yml'deki jwt.remember-me-refresh-expiration)
     * verilir, böylece kullanıcı günlük 401/expiry döngüsüne takılmadan
     * uzun süre giriş yapmış kalabilir.
     */
    private boolean rememberMe;

}
