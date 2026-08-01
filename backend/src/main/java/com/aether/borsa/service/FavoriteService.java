package com.aether.borsa.service;

import com.aether.borsa.dto.response.FavoriteResponse;

import java.util.List;
import java.util.UUID;

public interface FavoriteService {

    List<FavoriteResponse> getFavorites(UUID userId);
    FavoriteResponse addFavorite(UUID userId, String symbol);
    void removeFavorite(UUID userId, String symbol);
}
