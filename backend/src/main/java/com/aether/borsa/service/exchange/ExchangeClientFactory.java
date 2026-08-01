package com.aether.borsa.service.exchange;

import com.aether.borsa.exception.UnsupportedExchangeException;
import com.aether.borsa.model.enums.ExchangeName;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class ExchangeClientFactory {

    private final BinanceExchangeClient binanceExchangeClient;

    public IExchangeClient getClient(ExchangeName exchangeName){
        if(exchangeName == ExchangeName.BINANCE){
            return binanceExchangeClient;
        }else {
            throw new UnsupportedExchangeException(
                    "The " + exchangeName + " exchange is not supported yet. Currently only Binance is available; support for this exchange is coming soon.");
        }
    }


}
