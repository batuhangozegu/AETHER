package com.aether.borsa.service.impl;

import com.aether.borsa.dto.response.AssetAllocationResponse;
import com.aether.borsa.dto.response.PortfolioSummaryResponse;
import com.aether.borsa.model.entity.ExchangeKey;
import com.aether.borsa.model.entity.Order;
import com.aether.borsa.model.entity.User;
import com.aether.borsa.model.enums.OrderStatus;
import com.aether.borsa.model.enums.TradeSide;
import com.aether.borsa.repository.ExchangeKeyRepository;
import com.aether.borsa.repository.OrderRepository;
import com.aether.borsa.repository.UserRepository;
import com.aether.borsa.service.ExchangeService;
import com.aether.borsa.service.PortfolioService;
import com.aether.borsa.service.exchange.ExchangeClientFactory;
import com.aether.borsa.service.exchange.IExchangeClient;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class PortfolioServiceImpl implements PortfolioService {

    private final OrderRepository orderRepository;
    private final UserRepository userRepository;
    private final ExchangeService exchangeService;
    private final ExchangeKeyRepository exchangeKeyRepository;
    private final ExchangeClientFactory exchangeClientFactory;

    @Override
    public PortfolioSummaryResponse getSummary(UUID userId, UUID exchangeKeyId) {

        User user = userRepository.findById(userId).orElseThrow(() -> new RuntimeException("User not found."));

        // Sadece USDT bakiyesi değil, açık pozisyonlardaki coin'ler dahil
        // tüm varlıkların güncel USD karşılığının toplamı — aksi halde kasa
        // açık bir işlem varken bile hiç değişmiyormuş gibi görünüyor ve
        // portfolio breakdown'daki TOPLAM ile tutarsız kalıyordu.
        Map<String, BigDecimal> balances = exchangeService.getAllBalances(userId, exchangeKeyId);
        ExchangeKey exchangeKey = exchangeKeyRepository.findById(exchangeKeyId)
                .orElseThrow(() -> new RuntimeException("Exchange key not found."));
        IExchangeClient client = exchangeClientFactory.getClient(exchangeKey.getExchangeName());
        BigDecimal totalBalance = totalUsdValue(usdValuesByAsset(balances, client));

        LocalDateTime startOfDay = LocalDate.now().atStartOfDay();
        List<Order> closedToday = orderRepository.findByUserAndStatusAndClosedAtAfter(
                user, OrderStatus.CLOSED, startOfDay);

        BigDecimal dailyPnl = closedToday.stream().map(this::calculatePnL).reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal dailyPnlPct = BigDecimal.ZERO;
        if (totalBalance.compareTo(BigDecimal.ZERO) != 0) {
            dailyPnlPct = dailyPnl
                    .divide(totalBalance, 10, RoundingMode.HALF_UP)
                    .multiply(new BigDecimal("100"));
        }

        return new PortfolioSummaryResponse(totalBalance, dailyPnl, dailyPnlPct);
    }

    @Override
    public List<AssetAllocationResponse> getBreakdown(UUID userId, UUID exchangeKeyId) {
        Map<String, BigDecimal> balances = exchangeService.getAllBalances(userId, exchangeKeyId);

        ExchangeKey exchangeKey = exchangeKeyRepository.findById(exchangeKeyId)
                .orElseThrow(() -> new RuntimeException("Exchange key not found."));

        IExchangeClient client = exchangeClientFactory.getClient(exchangeKey.getExchangeName());

        Map<String, BigDecimal> usdValues = usdValuesByAsset(balances, client);
        BigDecimal totalUsdValue = totalUsdValue(usdValues);

        return usdValues.entrySet().stream()
                .map(entry -> {
                    String symbol = entry.getKey();
                    BigDecimal usdValue = entry.getValue();
                    BigDecimal amount = balances.get(symbol);

                    BigDecimal allocationPct = BigDecimal.ZERO;
                    if (totalUsdValue.compareTo(BigDecimal.ZERO) != 0) {
                        allocationPct = usdValue
                                .divide(totalUsdValue, 10, RoundingMode.HALF_UP)
                                .multiply(new BigDecimal("100"));
                    }

                    return new AssetAllocationResponse(symbol, amount, usdValue, allocationPct);
                })
                .toList();
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

    private Map<String, BigDecimal> usdValuesByAsset(Map<String, BigDecimal> balances, IExchangeClient client) {
        // Bir varlığın (dust bakiye, delisted/futures-only coin vb.) USDT paritesi
        // yoksa client.getCurrentPrice fırlatabilir — bu tek varlık yüzünden
        // tüm portfolio summary/breakdown'ın çökmesini (ve mobile'da "boş cüzdan"
        // gibi görünmesini) engellemek için o varlığı atlayıp devam ediyoruz.
        Map<String, BigDecimal> result = new LinkedHashMap<>();
        for (Map.Entry<String, BigDecimal> entry : balances.entrySet()) {
            try {
                result.put(entry.getKey(), getUsdValue(entry.getKey(), entry.getValue(), client));
            } catch (Exception e) {
                log.warn("Could not price asset {} for USD value, skipping: {}", entry.getKey(), e.getMessage());
            }
        }
        return result;
    }

    private BigDecimal totalUsdValue(Map<String, BigDecimal> usdValues) {
        return usdValues.values().stream().reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    private BigDecimal getUsdValue(String symbol, BigDecimal amount, IExchangeClient client) {
        if (symbol.equals("USDT")) {
            return amount;
        } else {

            BigDecimal price = client.getCurrentPrice(symbol + "USDT");
            BigDecimal total = price.multiply(amount);
            return total;

        }
    }


}
