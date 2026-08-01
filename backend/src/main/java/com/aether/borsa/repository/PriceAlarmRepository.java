package com.aether.borsa.repository;

import com.aether.borsa.model.entity.PriceAlarm;
import com.aether.borsa.model.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface PriceAlarmRepository extends JpaRepository<PriceAlarm, UUID> {

    List<PriceAlarm> findByUser(User user);
    List<PriceAlarm> findBySymbolAndTriggeredFalse(String symbol);
}
