package com.aether.borsa.service.exchange;

import com.aether.borsa.model.enums.ExchangeName;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class ExchangeClientFactory {

    private final BinanceExchangeClient binanceExchangeClient;
    private final BybitExchangeClient bybitExchangeClient;
    private final OkxExchangeClient okxExchangeClient;
    private final BingXExchangeClient bingXExchangeClient;

    public IExchangeClient getClient(ExchangeName exchangeName){
        return switch (exchangeName) {
            case BINANCE -> binanceExchangeClient;
            case BYBIT -> bybitExchangeClient;
            case OKX -> okxExchangeClient;
            case BINGX -> bingXExchangeClient;
        };
    }

}
