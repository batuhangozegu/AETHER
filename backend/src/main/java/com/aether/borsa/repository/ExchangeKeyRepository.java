package com.aether.borsa.repository;

import com.aether.borsa.model.entity.ExchangeKey;
import com.aether.borsa.model.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ExchangeKeyRepository extends JpaRepository<ExchangeKey, UUID> {

    List<ExchangeKey> findByUser(User user);

}
