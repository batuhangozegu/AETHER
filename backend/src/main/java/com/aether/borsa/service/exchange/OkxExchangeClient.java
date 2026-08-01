package com.aether.borsa.service.exchange;

import com.aether.borsa.dto.response.CandleResponse;
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
import java.util.Base64;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Component
public class OkxExchangeClient implements IExchangeClient {

    @Value("${exchange.okx.use-sandbox}")
    private boolean useSandbox;

    private static final String BASE_URL = "https://www.okx.com";

    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public OkxExchangeClient(RestTemplate restTemplate) {
        this.restTemplate = restTemplate;
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
            String requestPath = "/api/v5/account/balance";
            String timestamp = Instant.now().toString();
            String sign = sign(timestamp, "GET", requestPath, "", secretKey);

            HttpHeaders headers = new HttpHeaders();
            headers.set("OK-ACCESS-KEY", apiKey);
            headers.set("OK-ACCESS-SIGN", sign);
            headers.set("OK-ACCESS-TIMESTAMP", timestamp);
            headers.set("OK-ACCESS-PASSPHRASE", passphrase == null ? "" : passphrase);
            if (useSandbox) {
                headers.set("x-simulated-trading", "1");
            }

            ResponseEntity<String> response = restTemplate.exchange(
                    BASE_URL + requestPath, HttpMethod.GET, new HttpEntity<>(headers), String.class);

            JsonNode root = objectMapper.readTree(response.getBody());
            checkCode(root);

            Map<String, BigDecimal> balances = new HashMap<>();
            JsonNode data = root.path("data");
            if (data.isArray() && !data.isEmpty()) {
                for (JsonNode detail : data.get(0).path("details")) {
                    String currency = detail.path("ccy").asText();
                    BigDecimal amount = new BigDecimal(detail.path("availBal").asText("0").isBlank()
                            ? "0" : detail.path("availBal").asText("0"));
                    if (amount.compareTo(BigDecimal.ZERO) > 0) {
                        balances.put(currency, amount);
                    }
                }
            }
            return balances;

        } catch (Exception e) {
            throw new RuntimeException("OKX bakiyeleri alınamadı: " + e.getMessage(), e);
        }
    }

    @Override
    public TickerInfo getTickerInfo(String symbol) {
        try {
            String instId = toInstId(symbol);
            String url = BASE_URL + "/api/v5/market/ticker?instId=" + instId;
            String response = restTemplate.getForObject(url, String.class);
            JsonNode root = objectMapper.readTree(response);
            checkCode(root);

            JsonNode ticker = root.path("data").get(0);
            BigDecimal last = new BigDecimal(ticker.path("last").asText());
            BigDecimal open24h = new BigDecimal(ticker.path("open24h").asText());

            BigDecimal changePercent = BigDecimal.ZERO;
            if (open24h.compareTo(BigDecimal.ZERO) != 0) {
                changePercent = last.subtract(open24h)
                        .divide(open24h, 10, java.math.RoundingMode.HALF_UP)
                        .multiply(new BigDecimal("100"));
            }

            return new TickerInfo(last, changePercent);

        } catch (Exception e) {
            throw new RuntimeException("OKX ticker bilgisi alınamadı: " + e.getMessage(), e);
        }
    }

    @Override
    public List<CandleResponse> getCandles(String symbol, String timeframe) {
        try {
            String instId = toInstId(symbol);
            String bar = mapBar(timeframe);
            String url = BASE_URL + "/api/v5/market/candles?instId=" + instId + "&bar=" + bar + "&limit=100";

            String response = restTemplate.getForObject(url, String.class);
            JsonNode root = objectMapper.readTree(response);
            checkCode(root);

            List<CandleResponse> candles = new ArrayList<>();
            for (JsonNode candle : root.path("data")) {
                long openTimeMillis = candle.get(0).asLong();
                LocalDateTime timestamp = LocalDateTime.ofInstant(
                        Instant.ofEpochMilli(openTimeMillis), ZoneId.systemDefault());

                BigDecimal open = new BigDecimal(candle.get(1).asText());
                BigDecimal high = new BigDecimal(candle.get(2).asText());
                BigDecimal low = new BigDecimal(candle.get(3).asText());
                BigDecimal close = new BigDecimal(candle.get(4).asText());

                candles.add(new CandleResponse(timestamp, open, high, low, close));
            }

            // OKX returns candles newest-first; normalize to oldest-first like Binance.
            java.util.Collections.reverse(candles);
            return candles;

        } catch (Exception e) {
            throw new RuntimeException("OKX mum verisi alınamadı: " + e.getMessage(), e);
        }
    }

    private String toInstId(String symbol) {
        if (symbol.contains("-")) {
            return symbol;
        }
        if (symbol.endsWith("USDT")) {
            String base = symbol.substring(0, symbol.length() - 4);
            return base + "-USDT";
        }
        throw new RuntimeException("Desteklenmeyen sembol formatı: " + symbol);
    }

    private String mapBar(String timeframe) {
        return switch (timeframe) {
            case "1m" -> "1m";
            case "3m" -> "3m";
            case "5m" -> "5m";
            case "15m" -> "15m";
            case "30m" -> "30m";
            case "1h" -> "1H";
            case "2h" -> "2H";
            case "4h" -> "4H";
            case "6h" -> "6H";
            case "12h" -> "12H";
            case "1d" -> "1D";
            case "1w" -> "1W";
            case "1M" -> "1M";
            default -> throw new RuntimeException("Desteklenmeyen zaman aralığı: " + timeframe);
        };
    }

    private void checkCode(JsonNode root) {
        String code = root.path("code").asText("1");
        if (!"0".equals(code)) {
            String msg = root.path("msg").asText("Bilinmeyen OKX hatası");
            throw new RuntimeException(msg);
        }
    }

    private String sign(String timestamp, String method, String requestPath, String body, String secretKey) throws Exception {
        String payload = timestamp + method + requestPath + body;
        Mac mac = Mac.getInstance("HmacSHA256");
        mac.init(new SecretKeySpec(secretKey.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
        byte[] hash = mac.doFinal(payload.getBytes(StandardCharsets.UTF_8));
        return Base64.getEncoder().encodeToString(hash);
    }
}
