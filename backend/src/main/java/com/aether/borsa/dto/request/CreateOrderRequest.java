package com.aether.borsa.dto.request;

import com.aether.borsa.model.enums.MarginMode;
import com.aether.borsa.model.enums.MarketType;
import com.aether.borsa.model.enums.TradeSide;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;

import java.math.BigDecimal;
import java.util.UUID;

@Getter
public class CreateOrderRequest {

    @NotNull
    private UUID exchangeKeyId;

    @NotBlank(message = "Sembol boş olamaz")
    private String symbol;

    @NotNull
    private TradeSide side;

    @NotBlank
    private String type;

    @NotNull
    private BigDecimal amount;

    @NotNull
    private BigDecimal entryPrice;

    private BigDecimal stopLoss;

    private BigDecimal takeProfit;

    /** Belirtilmezse SPOT varsayılır (geriye dönük uyumluluk). */
    private MarketType marketType;

    /** Sadece marketType=FUTURES için: 1-125 arası kaldıraç. */
    private Integer leverage;

    /** Sadece marketType=FUTURES için; belirtilmezse ISOLATED varsayılır. */
    private MarginMode marginMode;

}
