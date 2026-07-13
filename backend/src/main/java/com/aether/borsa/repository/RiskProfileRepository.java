package com.aether.borsa.repository;

import com.aether.borsa.model.entity.RiskProfile;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface RiskProfileRepository extends JpaRepository<RiskProfile, UUID> {
}
