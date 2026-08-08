package com.aether.borsa.model.entity;

import com.aether.borsa.model.enums.AlarmDirection;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "price_alarms")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PriceAlarm {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", updatable = false, nullable = false)
    private UUID id;

    @ManyToOne
    @JoinColumn(name = "user_id")
    private User user;

    @Column(name = "symbol", nullable = false, length = 20)
    private String symbol;

    // precision/scale açıkça belirtiliyor — bkz. Order.java'daki aynı
    // gerekçe (Hibernate varsayılanı numeric(38,2) altcoin fiyatlarını
    // sessizce yuvarlıyordu).
    @Column(name = "target_price", nullable = false, precision = 20, scale = 8)
    private BigDecimal targetPrice;

    @Column(name = "direction", nullable = false)
    private AlarmDirection direction;

    @Builder.Default
    @Column(name = "triggered", nullable = false)
    private boolean triggered = false;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
    }
}
