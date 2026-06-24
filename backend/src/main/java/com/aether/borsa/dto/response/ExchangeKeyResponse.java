package com.aether.borsa.dto.response;

import com.aether.borsa.model.enums.ExchangeName;
import lombok.AllArgsConstructor;
import lombok.Getter;

import java.util.UUID;

@Getter
@AllArgsConstructor
public class ExchangeKeyResponse {

    private UUID id;
    private ExchangeName exchangeName;
    private String maskedApiKey;
    private String permissions;
    private String status;
}
