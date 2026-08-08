package com.aether.borsa.model.entity;


import com.aether.borsa.model.enums.MarginMode;
import com.aether.borsa.model.enums.MarketType;
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

    // precision/scale açıkça belirtiliyor — aksi halde Hibernate'in
    // varsayılanı (numeric(38,2)) küsüratlı kripto miktarlarını (ör. 0.001
    // BTC) ve altcoin fiyatlarını sessizce 2 ondalığa yuvarlayıp veriyi
    // bozuyordu (testnet testinde canlı olarak tespit edildi).
    @Column(name = "amount", precision = 20, scale = 8, nullable = false)
    private BigDecimal amount;

    @Column(name = "entry_price", precision = 20, scale = 8, nullable = false)
    private BigDecimal entryPrice;

    @Column(name = "take_profit", precision = 20, scale = 8)
    private BigDecimal takeProfit;

    @Column(name = "stop_loss", precision = 20, scale = 8)
    private BigDecimal stopLoss;

    @Column(name = "created_at",nullable = false,updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "closed_at")
    private LocalDateTime closedAt;

    @Column(name = "exit_price", precision = 20, scale = 8)
    private BigDecimal exitPrice;

    @Column(name = "exchange_order_id")
    private String exchangeOrderId;

    // V12 migration market_type'ı VARCHAR olarak oluşturuyor (V11'de
    // exchange_name için yapılan Postgres ENUM -> VARCHAR düzeltmesiyle
    // aynı gerekçe: Hibernate @Enumerated(STRING) ile uyumluluk).
    @Enumerated(EnumType.STRING)
    @Column(name = "market_type")
    @Builder.Default
    private MarketType marketType = MarketType.SPOT;

    /** Sadece marketType=FUTURES için anlamlı. */
    @Column(name = "leverage")
    private Integer leverage;

    @Enumerated(EnumType.STRING)
    @Column(name = "margin_mode")
    private MarginMode marginMode;

    /** Borsanın kendi hesapladığı likidasyon fiyatı (sadece FUTURES). */
    @Column(name = "liquidation_price", precision = 20, scale = 8)
    private BigDecimal liquidationPrice;

    @PrePersist
    protected void onCreate(){
        this.createdAt = LocalDateTime.now();
    }
}
