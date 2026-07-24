package com.aether.borsa.service.impl;

import com.aether.borsa.dto.response.PortfolioSummaryResponse;
import com.aether.borsa.model.entity.Order;
import com.aether.borsa.model.entity.User;
import com.aether.borsa.model.enums.TradeSide;
import com.aether.borsa.repository.OrderRepository;
import com.aether.borsa.repository.UserRepository;
import com.aether.borsa.service.ExchangeService;
import com.aether.borsa.service.PortfolioService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class PortfolioServiceImpl implements PortfolioService {

    private final OrderRepository orderRepository;
    private final UserRepository userRepository;
    private final ExchangeService exchangeService;

    @Override
    public PortfolioSummaryResponse getSummary(UUID userId, UUID exchangeKeyId) {

        User user = userRepository.findById(userId).orElseThrow(() -> new RuntimeException("Kullanıcı bulunamadı"));

        BigDecimal totalBalance = exchangeService.getBalance(userId, exchangeKeyId, "USDT");

        LocalDateTime startOfDay = LocalDate.now().atStartOfDay();
        List<Order> closedToday = orderRepository.findByUserAndClosedAtAfter(user, startOfDay);

        BigDecimal dailyPnl = closedToday.stream().map(this::calculatePnL).reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal dailyPnlPct = BigDecimal.ZERO;
        if (totalBalance.compareTo(BigDecimal.ZERO) != 0) {
            dailyPnlPct = dailyPnl
                    .divide(totalBalance, 10, RoundingMode.HALF_UP)
                    .multiply(new BigDecimal("100"));
        }

        return new PortfolioSummaryResponse(totalBalance, dailyPnl, dailyPnlPct);
    }

    private BigDecimal calculatePnL(Order order) {
        BigDecimal diff;

        if (order.getSide() == TradeSide.BUY) {
            diff = order.getExitPrice().subtract(order.getEntryPrice());
        } else {
            diff = order.getEntryPrice().subtract(order.getExitPrice());
        }

        return diff.multiply(order.getAmount());
    }


}
