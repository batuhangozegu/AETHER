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

    @Override
    public PlacedOrder placeSpotOrder(String apiKey, String secretKey, String passphrase,
                                       String symbol, TradeSide side, String type,
                                       BigDecimal amount, BigDecimal limitPrice) {
        try {
            String ordType = "MARKET".equalsIgnoreCase(type) ? "market"
                    : "LIMIT".equalsIgnoreCase(type) ? "limit"
                    : null;
            if (ordType == null) {
                throw new RuntimeException("Desteklenmeyen emir tipi: " + type);
            }
            if ("limit".equals(ordType) && limitPrice == null) {
                throw new RuntimeException("Limit emir için fiyat gerekli.");
            }

            StringBuilder body = new StringBuilder("{")
                    .append("\"instId\":\"").append(toInstId(symbol)).append("\",")
                    .append("\"tdMode\":\"cash\",")
                    .append("\"side\":\"").append(side == TradeSide.BUY ? "buy" : "sell").append("\",")
                    .append("\"ordType\":\"").append(ordType).append("\",")
                    // sz'nin her zaman baz para birimi miktarı olması için
                    // (market alım emirlerinde OKX varsayılanı quote-currency'dir).
                    .append("\"tgtCcy\":\"base_ccy\",")
                    .append("\"sz\":\"").append(amount.toPlainString()).append("\"");
            if (limitPrice != null) {
                body.append(",\"px\":\"").append(limitPrice.toPlainString()).append("\"");
            }
            body.append("}");

            JsonNode root = postSigned("/api/v5/trade/order", body.toString(), apiKey, secretKey, passphrase);
            String exchangeOrderId = root.path("data").get(0).path("ordId").asText();
            BigDecimal fillPrice = limitPrice != null ? limitPrice : getCurrentPrice(symbol);

            return new PlacedOrder(exchangeOrderId, fillPrice, amount, "SUBMITTED");
        } catch (Exception e) {
            throw new RuntimeException("OKX emri gönderilemedi: " + e.getMessage(), e);
        }
    }

    @Override
    public void cancelSpotOrder(String apiKey, String secretKey, String passphrase,
                                 String symbol, String exchangeOrderId) {
        try {
            String body = "{\"instId\":\"" + toInstId(symbol) + "\",\"ordId\":\"" + exchangeOrderId + "\"}";
            postSigned("/api/v5/trade/cancel-order", body, apiKey, secretKey, passphrase);
        } catch (Exception e) {
            throw new RuntimeException("OKX emri iptal edilemedi: " + e.getMessage(), e);
        }
    }

    private JsonNode postSigned(String requestPath, String body, String apiKey, String secretKey, String passphrase) throws Exception {
        String timestamp = Instant.now().toString();
        String sign = sign(timestamp, "POST", requestPath, body, secretKey);

        HttpHeaders headers = new HttpHeaders();
        headers.set("OK-ACCESS-KEY", apiKey);
        headers.set("OK-ACCESS-SIGN", sign);
        headers.set("OK-ACCESS-TIMESTAMP", timestamp);
        headers.set("OK-ACCESS-PASSPHRASE", passphrase == null ? "" : passphrase);
        headers.setContentType(org.springframework.http.MediaType.APPLICATION_JSON);
        if (useSandbox) {
            headers.set("x-simulated-trading", "1");
        }

        ResponseEntity<String> response = restTemplate.exchange(
                BASE_URL + requestPath, HttpMethod.POST, new HttpEntity<>(body, headers), String.class);

        JsonNode root = objectMapper.readTree(response.getBody());
        checkCode(root);
        return root;
    }

    @Override
    public void setLeverage(String apiKey, String secretKey, String passphrase,
                             String symbol, int leverage, MarginMode marginMode) {
        try {
            String mgnMode = marginMode == MarginMode.ISOLATED ? "isolated" : "cross";
            String body = "{\"instId\":\"" + toSwapInstId(symbol) + "\",\"lever\":\"" + leverage
                    + "\",\"mgnMode\":\"" + mgnMode + "\"}";
            postSigned("/api/v5/account/set-leverage", body, apiKey, secretKey, passphrase);
        } catch (Exception e) {
            throw new RuntimeException("OKX kaldıraç ayarlanamadı: " + e.getMessage(), e);
        }
    }

    @Override
    public PlacedOrder placeFuturesOrder(String apiKey, String secretKey, String passphrase,
                                          String symbol, TradeSide side, String type,
                                          BigDecimal amount, BigDecimal limitPrice, boolean reduceOnly) {
        try {
            String ordType = "MARKET".equalsIgnoreCase(type) ? "market"
                    : "LIMIT".equalsIgnoreCase(type) ? "limit"
                    : null;
            if (ordType == null) {
                throw new RuntimeException("Desteklenmeyen emir tipi: " + type);
            }
            if ("limit".equals(ordType) && limitPrice == null) {
                throw new RuntimeException("Limit emir için fiyat gerekli.");
            }

            StringBuilder body = new StringBuilder("{")
                    .append("\"instId\":\"").append(toSwapInstId(symbol)).append("\",")
                    .append("\"tdMode\":\"cross\",")
                    .append("\"side\":\"").append(side == TradeSide.BUY ? "buy" : "sell").append("\",")
                    .append("\"ordType\":\"").append(ordType).append("\",")
                    .append("\"sz\":\"").append(amount.toPlainString()).append("\",")
                    .append("\"reduceOnly\":").append(reduceOnly);
            if (limitPrice != null) {
                body.append(",\"px\":\"").append(limitPrice.toPlainString()).append("\"");
            }
            body.append("}");

            JsonNode root = postSigned("/api/v5/trade/order", body.toString(), apiKey, secretKey, passphrase);
            String exchangeOrderId = root.path("data").get(0).path("ordId").asText();
            BigDecimal fillPrice = limitPrice != null ? limitPrice : getCurrentPrice(symbol);

            return new PlacedOrder(exchangeOrderId, fillPrice, amount, "SUBMITTED");
        } catch (Exception e) {
            throw new RuntimeException("OKX futures emri gönderilemedi: " + e.getMessage(), e);
        }
    }

    @Override
    public PositionInfo getPositionInfo(String apiKey, String secretKey, String passphrase, String symbol) {
        try {
            String instId = toSwapInstId(symbol);
            String requestPath = "/api/v5/account/positions?instId=" + instId;
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

            JsonNode data = root.path("data");
            JsonNode position = data.isArray() && !data.isEmpty() ? data.get(0) : null;
            if (position == null) {
                return new PositionInfo(BigDecimal.ZERO, getCurrentPrice(symbol), BigDecimal.ZERO);
            }

            BigDecimal liquidationPrice = parseOrZero(position.path("liqPx").asText("0"));
            BigDecimal markPrice = parseOrZero(position.path("markPx").asText("0"));
            BigDecimal positionAmt = parseOrZero(position.path("pos").asText("0"));

            return new PositionInfo(liquidationPrice, markPrice, positionAmt);
        } catch (Exception e) {
            throw new RuntimeException("OKX pozisyon bilgisi alınamadı: " + e.getMessage(), e);
        }
    }

    private BigDecimal parseOrZero(String text) {
        if (text == null || text.isBlank()) {
            return BigDecimal.ZERO;
        }
        return new BigDecimal(text);
    }

    /** OKX perpetual swap instId formatı, ör. BTC-USDT-SWAP. */
    private String toSwapInstId(String symbol) {
        if (symbol.endsWith("-SWAP")) {
            return symbol;
        }
        return toInstId(symbol) + "-SWAP";
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
