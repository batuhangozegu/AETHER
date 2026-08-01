package com.aether.borsa.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;

@Getter
public class TwoFactorCodeRequest {

    @NotBlank(message = "Kod boş olamaz")
    private String code;
}
