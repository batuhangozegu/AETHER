package com.aether.borsa.dto.response;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@AllArgsConstructor
public class FavoriteResponse {

    private UUID id;
    private String symbol;
    private LocalDateTime createdAt;
}
