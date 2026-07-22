package com.aether.borsa.service;

import java.math.BigDecimal;
import java.util.UUID;

public interface ExchangeService {

    BigDecimal getBalance(UUID userId, UUID exchangeKeyId, String asset);
}
