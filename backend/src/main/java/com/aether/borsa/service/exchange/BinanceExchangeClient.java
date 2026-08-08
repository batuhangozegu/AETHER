package com.aether.borsa.service.exchange;

import com.aether.borsa.dto.response.CandleResponse;
import com.aether.borsa.model.enums.MarginMode;
import com.aether.borsa.model.enums.TradeSide;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.knowm.xchange.Exchange;
import org.knowm.xchange.ExchangeFactory;
import org.knowm.xchange.ExchangeSpecification;
import org.knowm.xchange.binance.BinanceExchange;
import org.knowm.xchange.binance.dto.ExchangeType;
import org.knowm.xchange.currency.CurrencyPair;
import org.knowm.xchange.dto.account.AccountInfo;
import org.knowm.xchange.dto.marketdata.Ticker;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class BinanceExchangeClient implements IExchangeClient {

    @Value("${exchange.binance.use-sandbox}")
    private boolean useSandbox;

    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper = new ObjectMapper();

    // Sembol başına LOT_SIZE/PRICE_FILTER bilgisini önbelleğe alır — her
    // emirde exchangeInfo'ya gitmemek için (bu değerler pratikte hiç
    // değişmez).
    private final Map<String, BigDecimal[]> symbolFilterCache = new ConcurrentHashMap<>();

    public BinanceExchangeClient(RestTemplate restTemplate) {
        this.restTemplate = restTemplate;
    }

    @Override
    public BigDecimal getBalance(String apiKey, String secretKey, String passphrase, String asset) {
        Map<String, BigDecimal> balances = getAllBalances(apiKey, secretKey, passphrase);
        return balances.getOrDefault(asset, BigDecimal.ZERO);
    }

    @Override
    public BigDecimal getCurrentPrice(String symbol) {
        try {
            Exchange exchange = createExchange(null, null);

            CurrencyPair pair = parseSymbol(symbol);
            Ticker ticker = exchange.getMarketDataService().getTicker(pair);

            return ticker.getLast();

        } catch (Exception e) {
            throw new RuntimeException("Fiyat bilgisi alınamadı: " + e.getMessage(), e);
        }
    }

    @Override
    public Map<String, BigDecimal> getAllBalances(String apiKey, String secretKey, String passphrase) {
        // Spot ve futures cüzdanları ayrı hesaplar/API'ler olabilir (özellikle
        // testnet'te — ör. Binance "Demo Trading" key'leri sadece futures'ta
        // çalışıyor, spot'ta 401 dönüyor). Portföyün eksik görünmemesi için
        // ikisi de denenip birleştiriliyor; biri başarısız olursa (o cüzdan
        // için key geçerli değilse) sessizce atlanıyor, ikisi de başarısız
        // olursa hata fırlatılıyor.
        Map<String, BigDecimal> combined = new HashMap<>();
        Exception lastError = null;
        boolean anySucceeded = false;

        try {
            Exchange exchange = createExchange(apiKey, secretKey);
            AccountInfo accountInfo = exchange.getAccountService().getAccountInfo();
            accountInfo.getWallet().getBalances().forEach((currency, balance) -> {
                BigDecimal amount = balance.getAvailable();
                if (amount.compareTo(BigDecimal.ZERO) > 0) {
                    combined.merge(currency.getCurrencyCode(), amount, BigDecimal::add);
                }
            });
            anySucceeded = true;
        } catch (Exception e) {
            lastError = e;
        }

        try {
            getAllFuturesBalancesRaw(apiKey, secretKey)
                    .forEach((asset, amount) -> combined.merge(asset, amount, BigDecimal::add));
            anySucceeded = true;
        } catch (Exception e) {
            if (lastError == null) {
                lastError = e;
            }
        }

        if (!anySucceeded) {
            throw new RuntimeException("Bakiyeler alınamadı: " + lastError.getMessage(), lastError);
        }
        return combined;
    }

    @Override
    public TickerInfo getTickerInfo(String symbol) {
        try {
            Exchange exchange = createExchange(null, null);

            CurrencyPair pair = parseSymbol(symbol);
            Ticker ticker = exchange.getMarketDataService().getTicker(pair);

            BigDecimal price = ticker.getLast();
            BigDecimal changePercent = ticker.getPercentageChange();

            return new TickerInfo(price, changePercent);

        } catch (Exception e) {
            throw new RuntimeException("Ticker bilgisi alınamadı: " + e.getMessage(), e);
        }
    }

    private String spotBaseUrl() {
        return useSandbox ? "https://testnet.binance.vision" : "https://api.binance.com";
    }

    @Override
    public List<CandleResponse> getCandles(String symbol, String timeframe) {
        try {
            String baseUrl = spotBaseUrl();
            String url = baseUrl + "/api/v3/klines"
                    + "?symbol=" + symbol
                    + "&interval=" + timeframe
                    + "&limit=100";

            String response = restTemplate.getForObject(url, String.class);
            JsonNode root = objectMapper.readTree(response);

            List<CandleResponse> candles = new ArrayList<>();

            for (JsonNode candle : root) {
                long openTimeMillis = candle.get(0).asLong();
                LocalDateTime timestamp = LocalDateTime.ofInstant(
                        Instant.ofEpochMilli(openTimeMillis), ZoneId.systemDefault());

                BigDecimal open = new BigDecimal(candle.get(1).asText());
                BigDecimal high = new BigDecimal(candle.get(2).asText());
                BigDecimal low = new BigDecimal(candle.get(3).asText());
                BigDecimal close = new BigDecimal(candle.get(4).asText());

                candles.add(new CandleResponse(timestamp, open, high, low, close));
            }

            return candles;

        } catch (Exception e) {
            throw new RuntimeException("Mum verisi alınamadı: " + e.getMessage(), e);
        }
    }

    // NOT: Emir gönderme/iptal XChange'in TradeService'i yerine ham HTTP +
    // HMAC ile yapılıyor (diğer 3 borsayla aynı desen). Sebep: XChange
    // 5.2.0'ın Binance adaptörü, gerçek Binance API'sinin döndürdüğü
    // "timeInForce":"GTC" (düz string) alanını kendi TimeInForce enum'ına
    // parse ederken Jackson hatası veriyor (`As.WRAPPER_OBJECT` bekliyor,
    // Binance düz string dönüyor) — emir borsada BAŞARIYLA gerçekleşse
    // bile XChange bunu bir hataymış gibi fırlatıyor. Testnet'te bizzat
    // doğrulandı: emir borsada dolduğu halde XChange "null (HTTP status
    // code: 200)" hatası veriyordu. Ham HTTP bu kütüphane hatasını devre
    // dışı bırakıyor ve ayrıca gerçek fill fiyatını (fills[].price'ın
    // ağırlıklı ortalaması) tam olarak okumamızı sağlıyor.

    @Override
    public PlacedOrder placeSpotOrder(String apiKey, String secretKey, String passphrase,
                                       String symbol, TradeSide side, String type,
                                       BigDecimal amount, BigDecimal limitPrice) {
        try {
            String binanceType = "MARKET".equalsIgnoreCase(type) ? "MARKET"
                    : "LIMIT".equalsIgnoreCase(type) ? "LIMIT"
                    : null;
            if (binanceType == null) {
                throw new RuntimeException("Desteklenmeyen emir tipi: " + type);
            }
            if ("LIMIT".equals(binanceType) && limitPrice == null) {
                throw new RuntimeException("Limit emir için fiyat gerekli.");
            }

            // Binance, miktar/fiyatın sembolün LOT_SIZE/PRICE_FILTER adımının
            // tam katı olmasını istiyor — aksi halde -1111 hatası veriyor.
            BigDecimal[] filters = getSymbolFilters(symbol, false);
            BigDecimal roundedAmount = roundToStep(amount, filters[0]);
            if (roundedAmount.compareTo(BigDecimal.ZERO) <= 0) {
                throw new RuntimeException(
                        "Hesaplanan miktar (" + amount.toPlainString() + ") " + symbol
                                + " için minimum işlem büyüklüğünün altında.");
            }
            BigDecimal roundedLimitPrice = limitPrice != null ? roundToStep(limitPrice, filters[1]) : null;

            StringBuilder qs = new StringBuilder()
                    .append("symbol=").append(symbol)
                    .append("&side=").append(side == TradeSide.BUY ? "BUY" : "SELL")
                    .append("&type=").append(binanceType)
                    .append("&quantity=").append(roundedAmount.toPlainString());
            if ("LIMIT".equals(binanceType)) {
                qs.append("&price=").append(roundedLimitPrice.toPlainString()).append("&timeInForce=GTC");
            }

            JsonNode root = signedPost(spotBaseUrl() + "/api/v3/order", qs.toString(), apiKey, secretKey);
            String exchangeOrderId = root.path("orderId").asText();

            BigDecimal fillPrice;
            BigDecimal executedQty = new BigDecimal(root.path("executedQty").asText("0"));
            BigDecimal cumQuoteQty = new BigDecimal(root.path("cummulativeQuoteQty").asText("0"));
            if ("MARKET".equals(binanceType) && executedQty.compareTo(BigDecimal.ZERO) > 0) {
                // Gerçek ortalama gerçekleşme fiyatı — borsanın kendi fill verisinden.
                fillPrice = cumQuoteQty.divide(executedQty, 8, java.math.RoundingMode.HALF_UP);
            } else {
                fillPrice = roundedLimitPrice != null ? roundedLimitPrice : getCurrentPrice(symbol);
            }

            return new PlacedOrder(exchangeOrderId, fillPrice, roundedAmount, root.path("status").asText("SUBMITTED"));
        } catch (Exception e) {
            throw new RuntimeException("Binance emri gönderilemedi: " + e.getMessage(), e);
        }
    }

    @Override
    public void cancelSpotOrder(String apiKey, String secretKey, String passphrase,
                                 String symbol, String exchangeOrderId) {
        try {
            long timestamp = System.currentTimeMillis();
            String queryString = "symbol=" + symbol + "&orderId=" + exchangeOrderId + "&timestamp=" + timestamp;
            String signature = hmacSha256Hex(secretKey, queryString);

            HttpHeaders headers = new HttpHeaders();
            headers.set("X-MBX-APIKEY", apiKey);
            String url = spotBaseUrl() + "/api/v3/order?" + queryString + "&signature=" + signature;

            restTemplate.exchange(url, HttpMethod.DELETE, new HttpEntity<>(headers), String.class);
        } catch (Exception e) {
            throw new RuntimeException("Binance emri iptal edilemedi: " + e.getMessage(), e);
        }
    }

    // ── Futures (USDS-M) — XChange futures'ı desteklemiyor, ham HTTP + HMAC
    // Binance API'sinin standart imzalama deseniyle (query string + hex
    // HMAC-SHA256, X-MBX-APIKEY header) uygulanıyor. ──────────────────────

    private String futuresBaseUrl() {
        return useSandbox ? "https://testnet.binancefuture.com" : "https://fapi.binance.com";
    }

    @Override
    public void setLeverage(String apiKey, String secretKey, String passphrase,
                             String symbol, int leverage, MarginMode marginMode) {
        try {
            String marginType = marginMode == MarginMode.ISOLATED ? "ISOLATED" : "CROSSED";
            // Marjin tipi zaten istenen değerdeyse Binance hata döner; bu
            // durumu yutuyoruz, kaldıraç ayarı asıl kritik olan.
            try {
                signedPost(futuresBaseUrl() + "/fapi/v1/marginType",
                        "symbol=" + symbol + "&marginType=" + marginType, apiKey, secretKey);
            } catch (Exception ignored) {
            }
            signedPost(futuresBaseUrl() + "/fapi/v1/leverage",
                    "symbol=" + symbol + "&leverage=" + leverage, apiKey, secretKey);
        } catch (Exception e) {
            throw new RuntimeException("Binance kaldıraç ayarlanamadı: " + e.getMessage(), e);
        }
    }

    @Override
    public PlacedOrder placeFuturesOrder(String apiKey, String secretKey, String passphrase,
                                          String symbol, TradeSide side, String type,
                                          BigDecimal amount, BigDecimal limitPrice, boolean reduceOnly) {
        try {
            String binanceType = "MARKET".equalsIgnoreCase(type) ? "MARKET"
                    : "LIMIT".equalsIgnoreCase(type) ? "LIMIT"
                    : null;
            if (binanceType == null) {
                throw new RuntimeException("Desteklenmeyen emir tipi: " + type);
            }
            if ("LIMIT".equals(binanceType) && limitPrice == null) {
                throw new RuntimeException("Limit emir için fiyat gerekli.");
            }

            // Binance, miktar/fiyatın sembolün LOT_SIZE/PRICE_FILTER adımının
            // tam katı olmasını istiyor — aksi halde -1111 hatası veriyor.
            BigDecimal[] filters = getSymbolFilters(symbol, true);
            BigDecimal roundedAmount = roundToStep(amount, filters[0]);
            if (roundedAmount.compareTo(BigDecimal.ZERO) <= 0) {
                throw new RuntimeException(
                        "Hesaplanan miktar (" + amount.toPlainString() + ") " + symbol
                                + " için minimum işlem büyüklüğünün altında.");
            }
            BigDecimal roundedLimitPrice = limitPrice != null ? roundToStep(limitPrice, filters[1]) : null;

            StringBuilder qs = new StringBuilder()
                    .append("symbol=").append(symbol)
                    .append("&side=").append(side == TradeSide.BUY ? "BUY" : "SELL")
                    .append("&type=").append(binanceType)
                    .append("&quantity=").append(roundedAmount.toPlainString())
                    .append("&reduceOnly=").append(reduceOnly);
            if ("LIMIT".equals(binanceType)) {
                qs.append("&price=").append(roundedLimitPrice.toPlainString()).append("&timeInForce=GTC");
            }

            JsonNode root = signedPost(futuresBaseUrl() + "/fapi/v1/order", qs.toString(), apiKey, secretKey);
            String exchangeOrderId = root.path("orderId").asText();
            BigDecimal fillPrice = roundedLimitPrice != null ? roundedLimitPrice : getCurrentPrice(symbol);

            return new PlacedOrder(exchangeOrderId, fillPrice, roundedAmount, "SUBMITTED");
        } catch (Exception e) {
            throw new RuntimeException("Binance futures emri gönderilemedi: " + e.getMessage(), e);
        }
    }

    @Override
    public PositionInfo getPositionInfo(String apiKey, String secretKey, String passphrase, String symbol) {
        try {
            long timestamp = System.currentTimeMillis();
            String queryString = "symbol=" + symbol + "&timestamp=" + timestamp;
            String signature = hmacSha256Hex(secretKey, queryString);

            HttpHeaders headers = new HttpHeaders();
            headers.set("X-MBX-APIKEY", apiKey);
            String url = futuresBaseUrl() + "/fapi/v2/positionRisk?" + queryString + "&signature=" + signature;

            ResponseEntity<String> response = restTemplate.exchange(
                    url, HttpMethod.GET, new HttpEntity<>(headers), String.class);
            JsonNode root = objectMapper.readTree(response.getBody());
            JsonNode position = root.isArray() && !root.isEmpty() ? root.get(0) : root;

            BigDecimal liquidationPrice = new BigDecimal(position.path("liquidationPrice").asText("0"));
            BigDecimal markPrice = new BigDecimal(position.path("markPrice").asText("0"));
            BigDecimal positionAmt = new BigDecimal(position.path("positionAmt").asText("0"));

            return new PositionInfo(liquidationPrice, markPrice, positionAmt);
        } catch (Exception e) {
            throw new RuntimeException("Binance pozisyon bilgisi alınamadı: " + e.getMessage(), e);
        }
    }

    private JsonNode signedPost(String url, String queryString, String apiKey, String secretKey) throws Exception {
        long timestamp = System.currentTimeMillis();
        String fullQuery = queryString + "&timestamp=" + timestamp;
        String signature = hmacSha256Hex(secretKey, fullQuery);

        HttpHeaders headers = new HttpHeaders();
        headers.set("X-MBX-APIKEY", apiKey);

        ResponseEntity<String> response = restTemplate.exchange(
                url + "?" + fullQuery + "&signature=" + signature,
                HttpMethod.POST, new HttpEntity<>(headers), String.class);

        return objectMapper.readTree(response.getBody());
    }

    private JsonNode signedGet(String url, String queryString, String apiKey, String secretKey) throws Exception {
        long timestamp = System.currentTimeMillis();
        String fullQuery = queryString.isEmpty() ? "timestamp=" + timestamp : queryString + "&timestamp=" + timestamp;
        String signature = hmacSha256Hex(secretKey, fullQuery);

        HttpHeaders headers = new HttpHeaders();
        headers.set("X-MBX-APIKEY", apiKey);

        ResponseEntity<String> response = restTemplate.exchange(
                url + "?" + fullQuery + "&signature=" + signature,
                HttpMethod.GET, new HttpEntity<>(headers), String.class);

        return objectMapper.readTree(response.getBody());
    }

    /**
     * Sembolün LOT_SIZE (miktar) ve PRICE_FILTER (fiyat) hassasiyet
     * kurallarını döner: {stepSize, tickSize}. Binance, emir miktarının/
     * fiyatının bu adımların tam katı olmasını istiyor — aksi halde
     * "-1111 Precision is over the maximum defined for this asset" hatası
     * veriyor. Spot ve futures'ın exchangeInfo'su ayrı olduğu için
     * {@code futures} parametresiyle ayırt ediliyor.
     */
    private BigDecimal[] getSymbolFilters(String symbol, boolean futures) {
        String cacheKey = (futures ? "FUTURES:" : "SPOT:") + symbol;
        return symbolFilterCache.computeIfAbsent(cacheKey, k -> fetchSymbolFilters(symbol, futures));
    }

    private BigDecimal[] fetchSymbolFilters(String symbol, boolean futures) {
        BigDecimal defaultStep = new BigDecimal("0.00000001");
        try {
            String url = (futures ? futuresBaseUrl() + "/fapi/v1/exchangeInfo"
                    : spotBaseUrl() + "/api/v3/exchangeInfo") + "?symbol=" + symbol;
            String response = restTemplate.getForObject(url, String.class);
            JsonNode root = objectMapper.readTree(response);
            JsonNode symbols = root.path("symbols");
            // ÖNEMLİ: futures exchangeInfo ?symbol= parametresini yok sayıp
            // TÜM sembolleri döner (spot doğru filtreliyor) — bu yüzden
            // dizideki ilk elemanı almak yerine symbol alanı eşleşeni
            // bulmak gerekiyor, aksi halde yanlış sembolün hassasiyet
            // kuralları kullanılır.
            JsonNode symbolInfo = null;
            if (symbols.isArray()) {
                for (JsonNode candidate : symbols) {
                    if (symbol.equals(candidate.path("symbol").asText())) {
                        symbolInfo = candidate;
                        break;
                    }
                }
            }

            BigDecimal stepSize = defaultStep;
            BigDecimal tickSize = defaultStep;
            if (symbolInfo != null) {
                for (JsonNode filter : symbolInfo.path("filters")) {
                    String type = filter.path("filterType").asText();
                    if ("LOT_SIZE".equals(type)) {
                        stepSize = new BigDecimal(filter.path("stepSize").asText(defaultStep.toPlainString()));
                    } else if ("PRICE_FILTER".equals(type)) {
                        tickSize = new BigDecimal(filter.path("tickSize").asText(defaultStep.toPlainString()));
                    }
                }
            }
            return new BigDecimal[]{stepSize, tickSize};
        } catch (Exception e) {
            // Filtre bilgisi alınamazsa güvenli bir varsayılana düş — borsa
            // yine de reddedebilir ama en azından burada çökmüyoruz.
            return new BigDecimal[]{defaultStep, defaultStep};
        }
    }

    /** value'yu step'in bir alt katına (floor) yuvarlar, step'in ondalık basamağıyla. */
    private BigDecimal roundToStep(BigDecimal value, BigDecimal step) {
        if (step == null || step.compareTo(BigDecimal.ZERO) <= 0) {
            return value;
        }
        BigDecimal steps = value.divide(step, 0, RoundingMode.DOWN);
        return steps.multiply(step).setScale(step.scale(), RoundingMode.DOWN);
    }

    /**
     * Futures cüzdanındaki sıfırdan büyük bakiyeleri döner. Binance'in
     * "Demo Trading" (demo.binance.com) ürünü de dahil futures-testnet
     * hesapları için — bu hesaplar spot API'sinde kimlik doğrulanamıyor
     * (401), sadece {@code /fapi/} uç noktalarında geçerli.
     */
    private Map<String, BigDecimal> getAllFuturesBalancesRaw(String apiKey, String secretKey) throws Exception {
        JsonNode root = signedGet(futuresBaseUrl() + "/fapi/v2/balance", "", apiKey, secretKey);
        Map<String, BigDecimal> balances = new HashMap<>();
        if (root.isArray()) {
            for (JsonNode entry : root) {
                BigDecimal amount = new BigDecimal(entry.path("balance").asText("0"));
                if (amount.compareTo(BigDecimal.ZERO) > 0) {
                    balances.put(entry.path("asset").asText(), amount);
                }
            }
        }
        return balances;
    }

    private String hmacSha256Hex(String secret, String payload) throws Exception {
        Mac mac = Mac.getInstance("HmacSHA256");
        mac.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
        byte[] hash = mac.doFinal(payload.getBytes(StandardCharsets.UTF_8));
        StringBuilder hex = new StringBuilder();
        for (byte b : hash) {
            hex.append(String.format("%02x", b));
        }
        return hex.toString();
    }

    private Exchange createExchange(String apiKey, String secretKey) {
        ExchangeSpecification exSpec = new BinanceExchange().getDefaultExchangeSpecification();
        if (apiKey != null) {
            exSpec.setApiKey(apiKey);
        }
        if (secretKey != null) {
            exSpec.setSecretKey(secretKey);
        }
        exSpec.setExchangeSpecificParametersItem(BinanceExchange.EXCHANGE_TYPE, ExchangeType.SPOT);
        exSpec.setExchangeSpecificParametersItem("Use_Sandbox", useSandbox);
        return ExchangeFactory.INSTANCE.createExchange(exSpec);
    }

    private CurrencyPair parseSymbol(String symbol) {
        if (symbol.endsWith("USDT")) {
            String base = symbol.substring(0, symbol.length() - 4);
            return new CurrencyPair(base, "USDT");
        }
        throw new RuntimeException("Desteklenmeyen sembol formatı: " + symbol);
    }
}
