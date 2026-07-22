package com.aether.borsa.service.exchange;

import org.knowm.xchange.Exchange;
import org.knowm.xchange.ExchangeFactory;
import org.knowm.xchange.ExchangeSpecification;
import org.knowm.xchange.binance.BinanceExchange;
import org.knowm.xchange.binance.dto.ExchangeType;
import org.knowm.xchange.dto.account.AccountInfo;
import org.knowm.xchange.dto.account.Balance;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;

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
}