package com.aether.borsa.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.util.Date;
import java.util.UUID;

@Component
public class JwtTokenProvider {

    private static final String TOKEN_TYPE_CLAIM = "type";
    private static final String REFRESH_TOKEN_TYPE = "refresh";
    private static final String REMEMBER_ME_CLAIM = "remember";

    @Value("${jwt.secret}")
    private String jwtSecret;

    @Value("${jwt.expiration}")
    private Long jwtExpiration;

    @Value("${jwt.refresh-expiration}")
    private Long jwtRefreshExpiration;

    /** "Oturumu açık tut" seçiliyken kullanılan uzun ömürlü refresh süresi. */
    @Value("${jwt.remember-me-refresh-expiration}")
    private Long jwtRememberMeRefreshExpiration;


    public String generateToken(UUID userId) {
        Date now = new Date();
        Date expiryDate = new Date(now.getTime() + jwtExpiration);

        SecretKey key = getSigningKey();

        return Jwts.builder()
                .subject(userId.toString())
                .issuedAt(now)
                .expiration(expiryDate)
                .signWith(key)
                .compact();
    }

    public String generateRefreshToken(UUID userId) {
        return generateRefreshToken(userId, false);
    }

    /**
     * @param rememberMe true ise refresh token {@code jwt.remember-me-refresh-expiration}
     *                   ile (uzun ömürlü), false ise normal {@code jwt.refresh-expiration}
     *                   ile üretilir. Bu bilgi token içine claim olarak gömülür ki her
     *                   yenilemede {@link #isRememberMeToken} ile okunup aynı süre
     *                   uzatılarak devam ettirilebilsin.
     */
    public String generateRefreshToken(UUID userId, boolean rememberMe) {
        Date now = new Date();
        long expirationMillis = rememberMe ? jwtRememberMeRefreshExpiration : jwtRefreshExpiration;
        Date expiryDate = new Date(now.getTime() + expirationMillis);

        SecretKey key = getSigningKey();

        return Jwts.builder()
                .subject(userId.toString())
                .claim(TOKEN_TYPE_CLAIM, REFRESH_TOKEN_TYPE)
                .claim(REMEMBER_ME_CLAIM, rememberMe)
                .issuedAt(now)
                .expiration(expiryDate)
                .signWith(key)
                .compact();
    }

    public boolean isRefreshToken(String token) {
        SecretKey key = getSigningKey();
        Claims claims = Jwts.parser()
                .verifyWith(key)
                .build()
                .parseSignedClaims(token)
                .getPayload();

        return REFRESH_TOKEN_TYPE.equals(claims.get(TOKEN_TYPE_CLAIM, String.class));
    }

    /** Bir refresh token'ın "oturumu açık tut" ile mi üretildiğini döner. */
    public boolean isRememberMeToken(String token) {
        SecretKey key = getSigningKey();
        Claims claims = Jwts.parser()
                .verifyWith(key)
                .build()
                .parseSignedClaims(token)
                .getPayload();

        return Boolean.TRUE.equals(claims.get(REMEMBER_ME_CLAIM, Boolean.class));
    }


    public String getUserIdFromJWT(String token){

        SecretKey key = getSigningKey();

        Claims claims = Jwts.parser()
                .verifyWith(key)
                .build()
                .parseSignedClaims(token)
                .getPayload();

        return claims.getSubject();

    }

    public long getExpiration() {
        return jwtExpiration;
    }

    public boolean validateToken(String token){

        SecretKey key = getSigningKey();

        try{
            Jwts.parser().verifyWith(key).build().parseSignedClaims(token).getPayload();
            return true;
        }catch (JwtException e){
            return false;
        }
    }



    private SecretKey getSigningKey() {
        return Keys.hmacShaKeyFor(jwtSecret.getBytes());
    }


}
