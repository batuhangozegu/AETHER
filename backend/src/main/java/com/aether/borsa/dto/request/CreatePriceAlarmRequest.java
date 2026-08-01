package com.aether.borsa.dto.request;

import com.aether.borsa.model.enums.AlarmDirection;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;

import java.math.BigDecimal;

@Getter
public class CreatePriceAlarmRequest {

    @NotBlank(message = "Symbol boş olamaz")
    private String symbol;

    @NotNull(message = "Hedef fiyat boş olamaz")
    private BigDecimal targetPrice;

    @NotNull(message = "Yön boş olamaz")
    private AlarmDirection direction;
}
