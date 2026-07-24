package com.aether.borsa.service;

import com.aether.borsa.dto.response.PortfolioSummaryResponse;

import java.util.UUID;

public interface PortfolioService {

    PortfolioSummaryResponse getSummary(UUID uuid,UUID exchangeKeyId);

}
