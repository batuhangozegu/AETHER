package com.aether.borsa.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;

@Getter
public class AddFavoriteRequest {

    @NotBlank(message = "Symbol boş olamaz")
    private String symbol;
}
