package com.aether.borsa.service.exchange;

import org.knowm.xchange.Exchange;
import org.knowm.xchange.ExchangeFactory;
import org.knowm.xchange.ExchangeSpecification;
import org.knowm.xchange.binance.BinanceExchange;
import org.knowm.xchange.binance.dto.ExchangeType;
import org.knowm.xchange.currency.CurrencyPair;
import org.knowm.xchange.dto.account.AccountInfo;
import org.knowm.xchange.dto.account.Balance;
import org.knowm.xchange.dto.marketdata.Ticker;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.Map;

@Component
public class BinanceExchangeClient implements IExchangeClient {

    @Override
    public BigDecimal getBalance(String apiKey, String secretKey, String asset) {
        try {
            ExchangeSpecification exSpec = new BinanceExchange().getDefaultExchangeSpecification();
            exSpec.setApiKey(apiKey);
            exSpec.setSecretKey(secretKey);

            // Testnet moduna geçiş - XChange'in kendi mekanizması
            exSpec.setExchangeSpecificParametersItem(BinanceExchange.EXCHANGE_TYPE, ExchangeType.SPOT);
            exSpec.setExchangeSpecificParametersItem("Use_Sandbox", true);

            Exchange exchange = ExchangeFactory.INSTANCE.createExchange(exSpec);

            AccountInfo accountInfo = exchange.getAccountService().getAccountInfo();
            Balance balance = accountInfo.getWallet().getBalance(
                    org.knowm.xchange.currency.Currency.getInstance(asset)
            );

            return balance.getAvailable();

        } catch (Exception e) {
            throw new RuntimeException("Binance bakiye bilgisi alınamadı: " + e.getMessage(), e);
        }
    }

    @Override
    public BigDecimal getCurrentPrice(String symbol) {
        try {
            ExchangeSpecification exSpec = new BinanceExchange().getDefaultExchangeSpecification();
            exSpec.setExchangeSpecificParametersItem(BinanceExchange.EXCHANGE_TYPE, ExchangeType.SPOT);
            exSpec.setExchangeSpecificParametersItem("Use_Sandbox", true);

            Exchange exchange = ExchangeFactory.INSTANCE.createExchange(exSpec);

            CurrencyPair pair = parseSymbol(symbol);
            Ticker ticker = exchange.getMarketDataService().getTicker(pair);

            return ticker.getLast();

        } catch (Exception e) {
            throw new RuntimeException("Fiyat bilgisi alınamadı: " + e.getMessage(), e);
        }
    }

    @Override
    public Map<String, BigDecimal> getAllBalances(String apiKey, String secretKey) {
        try {
            ExchangeSpecification exSpec = new BinanceExchange().getDefaultExchangeSpecification();
            exSpec.setApiKey(apiKey);
            exSpec.setSecretKey(secretKey);
            exSpec.setExchangeSpecificParametersItem(BinanceExchange.EXCHANGE_TYPE, ExchangeType.SPOT);
            exSpec.setExchangeSpecificParametersItem("Use_Sandbox", true);

            Exchange exchange = ExchangeFactory.INSTANCE.createExchange(exSpec);
            AccountInfo accountInfo = exchange.getAccountService().getAccountInfo();

            Map<String, BigDecimal> balances = new HashMap<>();

            accountInfo.getWallet().getBalances().forEach((currency, balance) -> {
                BigDecimal amount = balance.getAvailable();
                if (amount.compareTo(BigDecimal.ZERO) > 0) {
                    balances.put(currency.getCurrencyCode(), amount);
                }
            });

            return balances;

        } catch (Exception e) {
            throw new RuntimeException("Bakiyeler alınamadı: " + e.getMessage(), e);
        }
    }

    private CurrencyPair parseSymbol(String symbol) {
        if (symbol.endsWith("USDT")) {
            String base = symbol.substring(0, symbol.length() - 4);
            return new CurrencyPair(base, "USDT");
        }
        throw new RuntimeException("Desteklenmeyen sembol formatı: " + symbol);
    }
}