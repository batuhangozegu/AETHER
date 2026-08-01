package com.aether.borsa.service.impl;

import com.aether.borsa.dto.response.FavoriteResponse;
import com.aether.borsa.model.entity.Favorite;
import com.aether.borsa.model.entity.User;
import com.aether.borsa.repository.FavoriteRepository;
import com.aether.borsa.repository.UserRepository;
import com.aether.borsa.service.FavoriteService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class FavoriteServiceImpl implements FavoriteService {

    private final FavoriteRepository favoriteRepository;
    private final UserRepository userRepository;

    @Override
    public List<FavoriteResponse> getFavorites(UUID userId) {
        User user = userRepository.findById(userId).orElseThrow(() -> new RuntimeException("User not found."));
        return favoriteRepository.findByUser(user).stream()
                .map(f -> new FavoriteResponse(f.getId(), f.getSymbol(), f.getCreatedAt()))
                .toList();
    }

    @Override
    public FavoriteResponse addFavorite(UUID userId, String symbol) {
        User user = userRepository.findById(userId).orElseThrow(() -> new RuntimeException("User not found."));
        String normalizedSymbol = symbol.toUpperCase();

        Favorite favorite = favoriteRepository.findByUserAndSymbol(user, normalizedSymbol)
                .orElseGet(() -> favoriteRepository.save(
                        Favorite.builder().user(user).symbol(normalizedSymbol).build()));

        return new FavoriteResponse(favorite.getId(), favorite.getSymbol(), favorite.getCreatedAt());
    }

    @Override
    public void removeFavorite(UUID userId, String symbol) {
        User user = userRepository.findById(userId).orElseThrow(() -> new RuntimeException("User not found."));
        Favorite favorite = favoriteRepository.findByUserAndSymbol(user, symbol.toUpperCase())
                .orElseThrow(() -> new RuntimeException("Favorite not found."));
        favoriteRepository.delete(favorite);
    }
}
