package com.aether.borsa.service.exchange;

import com.aether.borsa.dto.response.CandleResponse;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
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

    private static final String BASE_URL = "https://open-api.bingx.com";

    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public BingXExchangeClient(RestTemplate restTemplate) {
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
            String path = "/openApi/spot/v1/account/balance";
            long timestamp = System.currentTimeMillis();
            String queryString = "timestamp=" + timestamp;
            String signature = hmacSha256Hex(secretKey, queryString);

            HttpHeaders headers = new HttpHeaders();
            headers.set("X-BX-APIKEY", apiKey);

            String url = BASE_URL + path + "?" + queryString + "&signature=" + signature;
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
            String url = BASE_URL + "/openApi/spot/v1/ticker/24hr?symbol=" + bxSymbol;
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
            String url = BASE_URL + "/openApi/spot/v1/market/kline?symbol=" + bxSymbol
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
