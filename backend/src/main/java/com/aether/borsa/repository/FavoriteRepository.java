package com.aether.borsa.repository;

import com.aether.borsa.model.entity.Favorite;
import com.aether.borsa.model.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface FavoriteRepository extends JpaRepository<Favorite, UUID> {

    List<Favorite> findByUser(User user);
    Optional<Favorite> findByUserAndSymbol(User user, String symbol);
    boolean existsByUserAndSymbol(User user, String symbol);
}
