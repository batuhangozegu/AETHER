package com.aether.borsa.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;

@Getter
public class UpdateExchangeKeyRequest {

    @NotBlank(message = "Apikey boş olamaz")
    private String apiKey;

    @NotBlank(message = "Secret Key boş olamaz.")
    private String secretKey;

    private boolean canRead;

    private boolean canTrade;
}
