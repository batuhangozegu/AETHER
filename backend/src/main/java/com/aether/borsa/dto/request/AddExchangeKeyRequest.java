package com.aether.borsa.dto.request;

import com.aether.borsa.model.enums.ExchangeName;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Getter;

@Getter
public class AddExchangeKeyRequest {

    @NotNull
    private ExchangeName exchangeName;

    @NotBlank(message = "Apikey boş olamaz")
    private String apiKey;

    @NotBlank(message = "Secret Key boş olamaz.")
    private String secretKey;

    private boolean canRead;

    private boolean canTrade;

}
