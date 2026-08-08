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
public class BybitExchangeClient implements IExchangeClient {

    @Value("${exchange.bybit.use-testnet}")
    private boolean useTestnet;

    private static final String RECV_WINDOW = "5000";

    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public BybitExchangeClient(RestTemplate restTemplate) {
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
            String queryString = "accountType=UNIFIED";
            String path = "/v5/account/wallet-balance";
            long timestamp = System.currentTimeMillis();

            String signaturePayload = timestamp + apiKey + RECV_WINDOW + queryString;
            String signature = hmacSha256Hex(secretKey, signaturePayload);

            HttpHeaders headers = new HttpHeaders();
            headers.set("X-BAPI-API-KEY", apiKey);
            headers.set("X-BAPI-SIGN", signature);
            headers.set("X-BAPI-TIMESTAMP", String.valueOf(timestamp));
            headers.set("X-BAPI-RECV-WINDOW", RECV_WINDOW);

            String url = baseUrl() + path + "?" + queryString;
            ResponseEntity<String> response = restTemplate.exchange(
                    url, HttpMethod.GET, new HttpEntity<>(headers), String.class);

            JsonNode root = objectMapper.readTree(response.getBody());
            checkRetCode(root);

            Map<String, BigDecimal> balances = new HashMap<>();
            JsonNode accounts = root.path("result").path("list");
            if (accounts.isArray() && !accounts.isEmpty()) {
                for (JsonNode coin : accounts.get(0).path("coin")) {
                    String currency = coin.path("coin").asText();
                    BigDecimal amount = parseBalanceField(coin);
                    if (amount.compareTo(BigDecimal.ZERO) > 0) {
                        balances.put(currency, amount);
                    }
                }
            }
            return balances;

        } catch (Exception e) {
            throw new RuntimeException("Bybit bakiyeleri alınamadı: " + e.getMessage(), e);
        }
    }

    @Override
    public TickerInfo getTickerInfo(String symbol) {
        try {
            String url = baseUrl() + "/v5/market/tickers?category=spot&symbol=" + symbol;
            String response = restTemplate.getForObject(url, String.class);
            JsonNode root = objectMapper.readTree(response);
            checkRetCode(root);

            JsonNode ticker = root.path("result").path("list").get(0);
            BigDecimal price = new BigDecimal(ticker.path("lastPrice").asText());
            BigDecimal changePercent = new BigDecimal(ticker.path("price24hPcnt").asText())
                    .multiply(new BigDecimal("100"));

            return new TickerInfo(price, changePercent);

        } catch (Exception e) {
            throw new RuntimeException("Bybit ticker bilgisi alınamadı: " + e.getMessage(), e);
        }
    }

    @Override
    public List<CandleResponse> getCandles(String symbol, String timeframe) {
        try {
            String interval = mapInterval(timeframe);
            String url = baseUrl() + "/v5/market/kline?category=spot&symbol=" + symbol
                    + "&interval=" + interval + "&limit=100";

            String response = restTemplate.getForObject(url, String.class);
            JsonNode root = objectMapper.readTree(response);
            checkRetCode(root);

            List<CandleResponse> candles = new ArrayList<>();
            JsonNode list = root.path("result").path("list");

            for (JsonNode candle : list) {
                long openTimeMillis = candle.get(0).asLong();
                LocalDateTime timestamp = LocalDateTime.ofInstant(
                        Instant.ofEpochMilli(openTimeMillis), ZoneId.systemDefault());

                BigDecimal open = new BigDecimal(candle.get(1).asText());
                BigDecimal high = new BigDecimal(candle.get(2).asText());
                BigDecimal low = new BigDecimal(candle.get(3).asText());
                BigDecimal close = new BigDecimal(candle.get(4).asText());

                candles.add(new CandleResponse(timestamp, open, high, low, close));
            }

            // Bybit returns candles newest-first; normalize to oldest-first like Binance.
            java.util.Collections.reverse(candles);
            return candles;

        } catch (Exception e) {
            throw new RuntimeException("Bybit mum verisi alınamadı: " + e.getMessage(), e);
        }
    }

    @Override
    public PlacedOrder placeSpotOrder(String apiKey, String secretKey, String passphrase,
                                       String symbol, TradeSide side, String type,
                                       BigDecimal amount, BigDecimal limitPrice) {
        try {
            String bybitType = "MARKET".equalsIgnoreCase(type) ? "Market"
                    : "LIMIT".equalsIgnoreCase(type) ? "Limit"
                    : null;
            if (bybitType == null) {
                throw new RuntimeException("Desteklenmeyen emir tipi: " + type);
            }
            if ("Limit".equals(bybitType) && limitPrice == null) {
                throw new RuntimeException("Limit emir için fiyat gerekli.");
            }

            StringBuilder body = new StringBuilder("{")
                    .append("\"category\":\"spot\",")
                    .append("\"symbol\":\"").append(symbol).append("\",")
                    .append("\"side\":\"").append(side == TradeSide.BUY ? "Buy" : "Sell").append("\",")
                    .append("\"orderType\":\"").append(bybitType).append("\",")
                    .append("\"qty\":\"").append(amount.toPlainString()).append("\"");
            if (limitPrice != null) {
                body.append(",\"price\":\"").append(limitPrice.toPlainString()).append("\"");
            }
            body.append("}");

            JsonNode root = postSigned("/v5/order/create", body.toString(), apiKey, secretKey);
            String exchangeOrderId = root.path("result").path("orderId").asText();
            BigDecimal fillPrice = limitPrice != null ? limitPrice : getCurrentPrice(symbol);

            return new PlacedOrder(exchangeOrderId, fillPrice, amount, "SUBMITTED");
        } catch (Exception e) {
            throw new RuntimeException("Bybit emri gönderilemedi: " + e.getMessage(), e);
        }
    }

    @Override
    public void cancelSpotOrder(String apiKey, String secretKey, String passphrase,
                                 String symbol, String exchangeOrderId) {
        try {
            String body = "{\"category\":\"spot\",\"symbol\":\"" + symbol
                    + "\",\"orderId\":\"" + exchangeOrderId + "\"}";
            postSigned("/v5/order/cancel", body, apiKey, secretKey);
        } catch (Exception e) {
            throw new RuntimeException("Bybit emri iptal edilemedi: " + e.getMessage(), e);
        }
    }

    @Override
    public void setLeverage(String apiKey, String secretKey, String passphrase,
                             String symbol, int leverage, MarginMode marginMode) {
        try {
            // Bybit izole/çapraz modu ve kaldıracı tek çağrıda ayarlıyor.
            int tradeMode = marginMode == MarginMode.ISOLATED ? 1 : 0;
            String body = "{\"category\":\"linear\",\"symbol\":\"" + symbol
                    + "\",\"tradeMode\":" + tradeMode
                    + ",\"buyLeverage\":\"" + leverage + "\",\"sellLeverage\":\"" + leverage + "\"}";
            try {
                postSigned("/v5/position/switch-isolated", body, apiKey, secretKey);
            } catch (Exception ignored) {
                // Pozisyon zaten istenen modda olabilir — bu durumda Bybit hata döner,
                // asıl kritik olan sonraki set-leverage çağrısı.
            }
            String leverageBody = "{\"category\":\"linear\",\"symbol\":\"" + symbol
                    + "\",\"buyLeverage\":\"" + leverage + "\",\"sellLeverage\":\"" + leverage + "\"}";
            postSigned("/v5/position/set-leverage", leverageBody, apiKey, secretKey);
        } catch (Exception e) {
            throw new RuntimeException("Bybit kaldıraç ayarlanamadı: " + e.getMessage(), e);
        }
    }

    @Override
    public PlacedOrder placeFuturesOrder(String apiKey, String secretKey, String passphrase,
                                          String symbol, TradeSide side, String type,
                                          BigDecimal amount, BigDecimal limitPrice, boolean reduceOnly) {
        try {
            String bybitType = "MARKET".equalsIgnoreCase(type) ? "Market"
                    : "LIMIT".equalsIgnoreCase(type) ? "Limit"
                    : null;
            if (bybitType == null) {
                throw new RuntimeException("Desteklenmeyen emir tipi: " + type);
            }
            if ("Limit".equals(bybitType) && limitPrice == null) {
                throw new RuntimeException("Limit emir için fiyat gerekli.");
            }

            StringBuilder body = new StringBuilder("{")
                    .append("\"category\":\"linear\",")
                    .append("\"symbol\":\"").append(symbol).append("\",")
                    .append("\"side\":\"").append(side == TradeSide.BUY ? "Buy" : "Sell").append("\",")
                    .append("\"orderType\":\"").append(bybitType).append("\",")
                    .append("\"qty\":\"").append(amount.toPlainString()).append("\",")
                    .append("\"reduceOnly\":").append(reduceOnly);
            if (limitPrice != null) {
                body.append(",\"price\":\"").append(limitPrice.toPlainString()).append("\"");
            }
            body.append("}");

            JsonNode root = postSigned("/v5/order/create", body.toString(), apiKey, secretKey);
            String exchangeOrderId = root.path("result").path("orderId").asText();
            BigDecimal fillPrice = limitPrice != null ? limitPrice : getCurrentPrice(symbol);

            return new PlacedOrder(exchangeOrderId, fillPrice, amount, "SUBMITTED");
        } catch (Exception e) {
            throw new RuntimeException("Bybit futures emri gönderilemedi: " + e.getMessage(), e);
        }
    }

    @Override
    public PositionInfo getPositionInfo(String apiKey, String secretKey, String passphrase, String symbol) {
        try {
            String queryString = "category=linear&symbol=" + symbol;
            long timestamp = System.currentTimeMillis();
            String signaturePayload = timestamp + apiKey + RECV_WINDOW + queryString;
            String signature = hmacSha256Hex(secretKey, signaturePayload);

            HttpHeaders headers = new HttpHeaders();
            headers.set("X-BAPI-API-KEY", apiKey);
            headers.set("X-BAPI-SIGN", signature);
            headers.set("X-BAPI-TIMESTAMP", String.valueOf(timestamp));
            headers.set("X-BAPI-RECV-WINDOW", RECV_WINDOW);

            String url = baseUrl() + "/v5/position/list?" + queryString;
            ResponseEntity<String> response = restTemplate.exchange(
                    url, HttpMethod.GET, new HttpEntity<>(headers), String.class);

            JsonNode root = objectMapper.readTree(response.getBody());
            checkRetCode(root);

            JsonNode list = root.path("result").path("list");
            JsonNode position = list.isArray() && !list.isEmpty() ? list.get(0) : null;
            if (position == null) {
                return new PositionInfo(BigDecimal.ZERO, getCurrentPrice(symbol), BigDecimal.ZERO);
            }

            BigDecimal liquidationPrice = parseOrZero(position.path("liqPrice").asText("0"));
            BigDecimal markPrice = parseOrZero(position.path("markPrice").asText("0"));
            BigDecimal positionAmt = parseOrZero(position.path("size").asText("0"));

            return new PositionInfo(liquidationPrice, markPrice, positionAmt);
        } catch (Exception e) {
            throw new RuntimeException("Bybit pozisyon bilgisi alınamadı: " + e.getMessage(), e);
        }
    }

    private BigDecimal parseOrZero(String text) {
        if (text == null || text.isBlank()) {
            return BigDecimal.ZERO;
        }
        return new BigDecimal(text);
    }

    private JsonNode postSigned(String path, String body, String apiKey, String secretKey) throws Exception {
        long timestamp = System.currentTimeMillis();
        String signaturePayload = timestamp + apiKey + RECV_WINDOW + body;
        String signature = hmacSha256Hex(secretKey, signaturePayload);

        HttpHeaders headers = new HttpHeaders();
        headers.set("X-BAPI-API-KEY", apiKey);
        headers.set("X-BAPI-SIGN", signature);
        headers.set("X-BAPI-TIMESTAMP", String.valueOf(timestamp));
        headers.set("X-BAPI-RECV-WINDOW", RECV_WINDOW);
        headers.setContentType(org.springframework.http.MediaType.APPLICATION_JSON);

        ResponseEntity<String> response = restTemplate.exchange(
                baseUrl() + path, HttpMethod.POST, new HttpEntity<>(body, headers), String.class);

        JsonNode root = objectMapper.readTree(response.getBody());
        checkRetCode(root);
        return root;
    }

    private BigDecimal parseBalanceField(JsonNode coin) {
        String availableText = coin.path("availableToWithdraw").asText();
        if (availableText != null && !availableText.isBlank()) {
            return new BigDecimal(availableText);
        }
        String walletText = coin.path("walletBalance").asText("0");
        if (walletText.isBlank()) {
            return BigDecimal.ZERO;
        }
        return new BigDecimal(walletText);
    }

    private void checkRetCode(JsonNode root) {
        int retCode = root.path("retCode").asInt(-1);
        if (retCode != 0) {
            String msg = root.path("retMsg").asText("Bilinmeyen Bybit hatası");
            throw new RuntimeException(msg);
        }
    }

    private String mapInterval(String timeframe) {
        return switch (timeframe) {
            case "1m" -> "1";
            case "3m" -> "3";
            case "5m" -> "5";
            case "15m" -> "15";
            case "30m" -> "30";
            case "1h" -> "60";
            case "2h" -> "120";
            case "4h" -> "240";
            case "6h" -> "360";
            case "12h" -> "720";
            case "1d" -> "D";
            case "1w" -> "W";
            case "1M" -> "M";
            default -> throw new RuntimeException("Desteklenmeyen zaman aralığı: " + timeframe);
        };
    }

    private String baseUrl() {
        return useTestnet ? "https://api-testnet.bybit.com" : "https://api.bybit.com";
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
