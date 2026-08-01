package com.aether.borsa.controller;

import com.aether.borsa.dto.request.AddFavoriteRequest;
import com.aether.borsa.dto.response.FavoriteResponse;
import com.aether.borsa.service.FavoriteService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/favorites")
@RequiredArgsConstructor
public class FavoriteController {

    private final FavoriteService favoriteService;

    @GetMapping
    public ResponseEntity<List<FavoriteResponse>> getFavorites(Authentication authentication) {
        return ResponseEntity.ok(favoriteService.getFavorites(getUserId(authentication)));
    }

    @PostMapping
    public ResponseEntity<FavoriteResponse> addFavorite(Authentication authentication, @RequestBody @Valid AddFavoriteRequest request) {
        return ResponseEntity.status(201).body(favoriteService.addFavorite(getUserId(authentication), request.getSymbol()));
    }

    @DeleteMapping("/{symbol}")
    public ResponseEntity<Void> removeFavorite(Authentication authentication, @PathVariable String symbol) {
        favoriteService.removeFavorite(getUserId(authentication), symbol);
        return ResponseEntity.noContent().build();
    }

    private UUID getUserId(Authentication authentication) {
        return UUID.fromString(authentication.getName());
    }
}
