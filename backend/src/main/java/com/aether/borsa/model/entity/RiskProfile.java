package com.aether.borsa.model.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.util.UUID;

@Entity
@Table(name = "risk_profiles")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RiskProfile {

    @Id
    private UUID userId;

    @OneToOne
    @MapsId
    @JoinColumn(name = "user_id")
    private User user;

    @Column(name = "risk_per_trade_pct")
    private BigDecimal riskPerTradePct;

    @Column(name = "daily_loss_cap_pct")
    private BigDecimal dailyLossCapPct;

    @Column(name = "target_rr")
    private BigDecimal targetRr;

    @Column(name = "auto_stop_loss_enabled")
    private boolean autoStopLossEnabled;

}
