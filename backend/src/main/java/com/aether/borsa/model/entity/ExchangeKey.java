package com.aether.borsa.model.entity;

import com.aether.borsa.model.enums.ExchangeName;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "exchange_keys")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ExchangeKey {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", updatable = false, nullable = false)
    private UUID id;

    @ManyToOne
    @JoinColumn(name = "user_id")
    private User user;

    @Column(name = "exchange_name")
    private ExchangeName exchangeName;

    @Column(name= "encrypted_api_key")
    private String encryptedApiKey;

    @Column(name = "encrypted_secret_key")
    private String encryptedSecretKey;

    @Column(name = "can_read")
    private boolean canRead;

    @Column(name = "canTrade")
    private boolean canTrade;

    @Column(name = "created_at",nullable = false,updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate(){
        this.createdAt = LocalDateTime.now();
    }

}
