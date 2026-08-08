package com.aether.borsa.service.exchange;

import com.aether.borsa.dto.response.CandleResponse;
import com.aether.borsa.model.enums.MarginMode;
import com.aether.borsa.model.enums.TradeSide;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
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
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Component
public class BingXExchangeClient implements IExchangeClient {

    // BingX'in ayrı bir "VST" (demo trading) ortamı var; gerçek para
    // riskini önlemek için varsayılan olarak açık tutuluyor. application.yml
    // içinde exchange.bingx.use-sandbox: false yapılmadan gerçek emir
    // gönderilmez.
    @Value("${exchange.bingx.use-sandbox:true}")
    private boolean useSandbox;

    private static final String LIVE_BASE_URL = "https://open-api.bingx.com";
    // BingX demo trading (VST) alanı — implementasyon test edilirken
    // BingX'in güncel demo host'una göre doğrulanmalı.
    private static final String DEMO_BASE_URL = "https://open-api-vst.bingx.com";

    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public BingXExchangeClient(RestTemplate restTemplate) {
        this.restTemplate = restTemplate;
    }

    private String baseUrl() {
        return useSandbox ? DEMO_BASE_URL : LIVE_BASE_URL;
    }

    @Override
    public BigDecimal getBalance(String apiKey, String secretKey, String passphrase, String asset) {
        Map<String, BigDecimal> balances = getAllBalances(apiKey, secretKey, passphrase);
        return balances.getOrDefault(asset, BigDecimal.ZERO);
    }

    @Override
    public BigDecimal getCurrentPrice(String symbol) {
        return getTickerInfo(symbol).getPrice();
    }

    @Override
    public Map<String, BigDecimal> getAllBalances(String apiKey, String secretKey, String passphrase) {
        try {
            String path = "/openApi/spot/v1/account/balance";
            long timestamp = System.currentTimeMillis();
            String queryString = "timestamp=" + timestamp;
            String signature = hmacSha256Hex(secretKey, queryString);

            HttpHeaders headers = new HttpHeaders();
            headers.set("X-BX-APIKEY", apiKey);

            String url = baseUrl() + path + "?" + queryString + "&signature=" + signature;
            ResponseEntity<String> response = restTemplate.exchange(
                    url, HttpMethod.GET, new HttpEntity<>(headers), String.class);

            JsonNode root = objectMapper.readTree(response.getBody());
            checkCode(root);

            Map<String, BigDecimal> balances = new HashMap<>();
            for (JsonNode balance : root.path("data").path("balances")) {
                String currency = balance.path("asset").asText();
                BigDecimal amount = new BigDecimal(balance.path("free").asText("0"));
                if (amount.compareTo(BigDecimal.ZERO) > 0) {
                    balances.put(currency, amount);
                }
            }
            return balances;

        } catch (Exception e) {
            throw new RuntimeException("BingX bakiyeleri alınamadı: " + e.getMessage(), e);
        }
    }

    @Override
    public TickerInfo getTickerInfo(String symbol) {
        try {
            String bxSymbol = toBingxSymbol(symbol);
            String url = baseUrl() + "/openApi/spot/v1/ticker/24hr?symbol=" + bxSymbol;
            String response = restTemplate.getForObject(url, String.class);
            JsonNode root = objectMapper.readTree(response);
            checkCode(root);

            JsonNode ticker = root.path("data");
            if (ticker.isArray()) {
                ticker = ticker.get(0);
            }

            BigDecimal price = new BigDecimal(ticker.path("lastPrice").asText());
            BigDecimal changePercent = new BigDecimal(ticker.path("priceChangePercent").asText("0"));

            return new TickerInfo(price, changePercent);

        } catch (Exception e) {
            throw new RuntimeException("BingX ticker bilgisi alınamadı: " + e.getMessage(), e);
        }
    }

    @Override
    public List<CandleResponse> getCandles(String symbol, String timeframe) {
        try {
            String bxSymbol = toBingxSymbol(symbol);
            String url = baseUrl() + "/openApi/spot/v1/market/kline?symbol=" + bxSymbol
                    + "&interval=" + timeframe + "&limit=100";

            String response = restTemplate.getForObject(url, String.class);
            JsonNode root = objectMapper.readTree(response);
            checkCode(root);

            List<CandleResponse> candles = new ArrayList<>();
            for (JsonNode candle : root.path("data")) {
                long openTimeMillis = candle.path("time").asLong();
                LocalDateTime timestamp = LocalDateTime.ofInstant(
                        Instant.ofEpochMilli(openTimeMillis), ZoneId.systemDefault());

                BigDecimal open = new BigDecimal(candle.path("open").asText());
                BigDecimal high = new BigDecimal(candle.path("high").asText());
                BigDecimal low = new BigDecimal(candle.path("low").asText());
                BigDecimal close = new BigDecimal(candle.path("close").asText());

                candles.add(new CandleResponse(timestamp, open, high, low, close));
            }

            return candles;

        } catch (Exception e) {
            throw new RuntimeException("BingX mum verisi alınamadı: " + e.getMessage(), e);
        }
    }

    @Override
    public PlacedOrder placeSpotOrder(String apiKey, String secretKey, String passphrase,
                                       String symbol, TradeSide side, String type,
                                       BigDecimal amount, BigDecimal limitPrice) {
        try {
            String bxType = "MARKET".equalsIgnoreCase(type) ? "MARKET"
                    : "LIMIT".equalsIgnoreCase(type) ? "LIMIT"
                    : null;
            if (bxType == null) {
                throw new RuntimeException("Desteklenmeyen emir tipi: " + type);
            }
            if ("LIMIT".equals(bxType) && limitPrice == null) {
                throw new RuntimeException("Limit emir için fiyat gerekli.");
            }

            String bxSymbol = toBingxSymbol(symbol);
            long timestamp = System.currentTimeMillis();
            StringBuilder qs = new StringBuilder()
                    .append("symbol=").append(bxSymbol)
                    .append("&side=").append(side == TradeSide.BUY ? "BUY" : "SELL")
                    .append("&type=").append(bxType)
                    .append("&quantity=").append(amount.toPlainString());
            if (limitPrice != null) {
                qs.append("&price=").append(limitPrice.toPlainString());
            }
            qs.append("&timestamp=").append(timestamp);

            String signature = hmacSha256Hex(secretKey, qs.toString());
            String url = baseUrl() + "/openApi/spot/v1/trade/order?" + qs + "&signature=" + signature;

            HttpHeaders headers = new HttpHeaders();
            headers.set("X-BX-APIKEY", apiKey);

            ResponseEntity<String> response = restTemplate.exchange(
                    url, HttpMethod.POST, new HttpEntity<>(headers), String.class);

            JsonNode root = objectMapper.readTree(response.getBody());
            checkCode(root);

            String exchangeOrderId = root.path("data").path("orderId").asText();
            BigDecimal fillPrice = limitPrice != null ? limitPrice : getCurrentPrice(symbol);

            return new PlacedOrder(exchangeOrderId, fillPrice, amount, "SUBMITTED");
        } catch (Exception e) {
            throw new RuntimeException("BingX emri gönderilemedi: " + e.getMessage(), e);
        }
    }

    @Override
    public void cancelSpotOrder(String apiKey, String secretKey, String passphrase,
                                 String symbol, String exchangeOrderId) {
        try {
            String bxSymbol = toBingxSymbol(symbol);
            long timestamp = System.currentTimeMillis();
            String qs = "symbol=" + bxSymbol + "&orderId=" + exchangeOrderId + "&timestamp=" + timestamp;
            String signature = hmacSha256Hex(secretKey, qs);
            String url = baseUrl() + "/openApi/spot/v1/trade/cancel?" + qs + "&signature=" + signature;

            HttpHeaders headers = new HttpHeaders();
            headers.set("X-BX-APIKEY", apiKey);

            ResponseEntity<String> response = restTemplate.exchange(
                    url, HttpMethod.POST, new HttpEntity<>(headers), String.class);

            JsonNode root = objectMapper.readTree(response.getBody());
            checkCode(root);
        } catch (Exception e) {
            throw new RuntimeException("BingX emri iptal edilemedi: " + e.getMessage(), e);
        }
    }

    @Override
    public void setLeverage(String apiKey, String secretKey, String passphrase,
                             String symbol, int leverage, MarginMode marginMode) {
        try {
            String bxSymbol = toBingxSymbol(symbol);
            String marginType = marginMode == MarginMode.ISOLATED ? "ISOLATED" : "CROSSED";
            long timestamp = System.currentTimeMillis();
            // Marjin tipi (LONG ve SHORT yönleri için ayrı ayrı).
            for (String side : new String[]{"LONG", "SHORT"}) {
                try {
                    String qs = "symbol=" + bxSymbol + "&marginType=" + marginType
                            + "&side=" + side + "&timestamp=" + timestamp;
                    String signature = hmacSha256Hex(secretKey, qs);
                    String url = baseUrl() + "/openApi/swap/v2/trade/marginType?" + qs + "&signature=" + signature;
                    HttpHeaders headers = new HttpHeaders();
                    headers.set("X-BX-APIKEY", apiKey);
                    restTemplate.exchange(url, HttpMethod.POST, new HttpEntity<>(headers), String.class);
                } catch (Exception ignored) {
                    // Zaten istenen modda olabilir.
                }
            }

            String qs = "symbol=" + bxSymbol + "&side=BOTH&leverage=" + leverage + "&timestamp=" + timestamp;
            String signature = hmacSha256Hex(secretKey, qs);
            String url = baseUrl() + "/openApi/swap/v2/trade/leverage?" + qs + "&signature=" + signature;

            HttpHeaders headers = new HttpHeaders();
            headers.set("X-BX-APIKEY", apiKey);
            ResponseEntity<String> response = restTemplate.exchange(
                    url, HttpMethod.POST, new HttpEntity<>(headers), String.class);

            JsonNode root = objectMapper.readTree(response.getBody());
            checkCode(root);
        } catch (Exception e) {
            throw new RuntimeException("BingX kaldıraç ayarlanamadı: " + e.getMessage(), e);
        }
    }

    @Override
    public PlacedOrder placeFuturesOrder(String apiKey, String secretKey, String passphrase,
                                          String symbol, TradeSide side, String type,
                                          BigDecimal amount, BigDecimal limitPrice, boolean reduceOnly) {
        try {
            String bxType = "MARKET".equalsIgnoreCase(type) ? "MARKET"
                    : "LIMIT".equalsIgnoreCase(type) ? "LIMIT"
                    : null;
            if (bxType == null) {
                throw new RuntimeException("Desteklenmeyen emir tipi: " + type);
            }
            if ("LIMIT".equals(bxType) && limitPrice == null) {
                throw new RuntimeException("Limit emir için fiyat gerekli.");
            }

            String bxSymbol = toBingxSymbol(symbol);
            long timestamp = System.currentTimeMillis();
            StringBuilder qs = new StringBuilder()
                    .append("symbol=").append(bxSymbol)
                    .append("&side=").append(side == TradeSide.BUY ? "BUY" : "SELL")
                    .append("&positionSide=BOTH")
                    .append("&type=").append(bxType)
                    .append("&quantity=").append(amount.toPlainString())
                    .append("&reduceOnly=").append(reduceOnly);
            if (limitPrice != null) {
                qs.append("&price=").append(limitPrice.toPlainString());
            }
            qs.append("&timestamp=").append(timestamp);

            String signature = hmacSha256Hex(secretKey, qs.toString());
            String url = baseUrl() + "/openApi/swap/v2/trade/order?" + qs + "&signature=" + signature;

            HttpHeaders headers = new HttpHeaders();
            headers.set("X-BX-APIKEY", apiKey);

            ResponseEntity<String> response = restTemplate.exchange(
                    url, HttpMethod.POST, new HttpEntity<>(headers), String.class);

            JsonNode root = objectMapper.readTree(response.getBody());
            checkCode(root);

            String exchangeOrderId = root.path("data").path("order").path("orderId").asText();
            BigDecimal fillPrice = limitPrice != null ? limitPrice : getCurrentPrice(symbol);

            return new PlacedOrder(exchangeOrderId, fillPrice, amount, "SUBMITTED");
        } catch (Exception e) {
            throw new RuntimeException("BingX futures emri gönderilemedi: " + e.getMessage(), e);
        }
    }

    @Override
    public PositionInfo getPositionInfo(String apiKey, String secretKey, String passphrase, String symbol) {
        try {
            String bxSymbol = toBingxSymbol(symbol);
            long timestamp = System.currentTimeMillis();
            String qs = "symbol=" + bxSymbol + "&timestamp=" + timestamp;
            String signature = hmacSha256Hex(secretKey, qs);
            String url = baseUrl() + "/openApi/swap/v2/user/positions?" + qs + "&signature=" + signature;

            HttpHeaders headers = new HttpHeaders();
            headers.set("X-BX-APIKEY", apiKey);

            ResponseEntity<String> response = restTemplate.exchange(
                    url, HttpMethod.GET, new HttpEntity<>(headers), String.class);

            JsonNode root = objectMapper.readTree(response.getBody());
            checkCode(root);

            JsonNode data = root.path("data");
            JsonNode position = data.isArray() && !data.isEmpty() ? data.get(0) : null;
            if (position == null) {
                return new PositionInfo(BigDecimal.ZERO, getCurrentPrice(symbol), BigDecimal.ZERO);
            }

            BigDecimal liquidationPrice = parseOrZero(position.path("liquidationPrice").asText("0"));
            BigDecimal markPrice = parseOrZero(position.path("markPrice").asText("0"));
            BigDecimal positionAmt = parseOrZero(position.path("positionAmt").asText("0"));

            return new PositionInfo(liquidationPrice, markPrice, positionAmt);
        } catch (Exception e) {
            throw new RuntimeException("BingX pozisyon bilgisi alınamadı: " + e.getMessage(), e);
        }
    }

    private BigDecimal parseOrZero(String text) {
        if (text == null || text.isBlank()) {
            return BigDecimal.ZERO;
        }
        return new BigDecimal(text);
    }

    private String toBingxSymbol(String symbol) {
        if (symbol.contains("-")) {
            return symbol;
        }
        if (symbol.endsWith("USDT")) {
            String base = symbol.substring(0, symbol.length() - 4);
            return base + "-USDT";
        }
        throw new RuntimeException("Desteklenmeyen sembol formatı: " + symbol);
    }

    private void checkCode(JsonNode root) {
        int code = root.path("code").asInt(-1);
        if (code != 0) {
            String msg = root.path("msg").asText("Bilinmeyen BingX hatası");
            throw new RuntimeException(msg);
        }
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
}
