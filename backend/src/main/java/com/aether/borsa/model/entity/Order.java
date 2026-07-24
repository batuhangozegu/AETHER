package com.aether.borsa.model.entity;


import com.aether.borsa.model.enums.OrderStatus;
import com.aether.borsa.model.enums.TradeSide;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "orders")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Order {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", updatable = false, nullable = false)
    private UUID id;

    @ManyToOne
    @JoinColumn(name = "user_id")
    private User user;

    @ManyToOne
    @JoinColumn(name = "exchange_key_id")
    private ExchangeKey exchangeKey;

    @Column(name = "symbol")
    private String symbol;

    @Column(name = "side")
    private TradeSide side;

    @Column(name = "type")
    private String type;

    @Column(name = "status")
    private OrderStatus status;

    @Column(name = "amount")
    private BigDecimal amount;

    @Column(name = "entry_price")
    private BigDecimal entryPrice;

    @Column(name = "take_profit")
    private BigDecimal takeProfit;

    @Column(name = "stop_loss")
    private BigDecimal stopLoss;

    @Column(name = "created_at",nullable = false,updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "closed_at")
    private LocalDateTime closedAt;

    @Column(name = "exit_price")
    private BigDecimal exitPrice;

    @PrePersist
    protected void onCreate(){
        this.createdAt = LocalDateTime.now();
    }
}
