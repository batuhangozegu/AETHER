package com.aether.borsa.service.impl;

import com.aether.borsa.dto.request.LoginRequest;
import com.aether.borsa.dto.request.RegisterRequest;
import com.aether.borsa.dto.response.TokenResponse;
import com.aether.borsa.model.entity.User;
import com.aether.borsa.repository.UserRepository;
import com.aether.borsa.security.JwtTokenProvider;
import com.aether.borsa.service.AuthService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AuthServiceImpl implements AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;

    @Override
    public TokenResponse register(RegisterRequest request) {
        if(userRepository.existsByEmail(request.getEmail()) || userRepository.existsByUsername(request.getUsername()) )
        {
            throw new RuntimeException("This email or username is already in use.");
        }
        User user = User.builder()
                .username(request.getUsername())
                .email(request.getEmail())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .build();

        userRepository.save(user);

       String token = jwtTokenProvider.generateToken(user.getId());
       String refreshToken = jwtTokenProvider.generateRefreshToken(user.getId());
       return new TokenResponse(token, refreshToken, "Bearer" , jwtTokenProvider.getExpiration());
    }

    @Override
    public TokenResponse login(LoginRequest request) {

        User  user = userRepository.findByEmail(request.getEmail()).orElseThrow(() -> new RuntimeException("No account found with this email."));
        if(!passwordEncoder.matches(request.getPassword(), user.getPasswordHash()))
        {
            throw new RuntimeException("Incorrect password.");
        }
        String token = jwtTokenProvider.generateToken(user.getId());
        String refreshToken = jwtTokenProvider.generateRefreshToken(user.getId());
        return new TokenResponse(token, refreshToken, "Bearer", jwtTokenProvider.getExpiration());
    }

    @Override
    public TokenResponse refresh(String refreshToken) {
        if (!jwtTokenProvider.validateToken(refreshToken) || !jwtTokenProvider.isRefreshToken(refreshToken)) {
            throw new RuntimeException("Invalid or expired refresh token.");
        }

        UUID userId = UUID.fromString(jwtTokenProvider.getUserIdFromJWT(refreshToken));
        userRepository.findById(userId).orElseThrow(() -> new RuntimeException("User not found."));

        String newToken = jwtTokenProvider.generateToken(userId);
        String newRefreshToken = jwtTokenProvider.generateRefreshToken(userId);
        return new TokenResponse(newToken, newRefreshToken, "Bearer", jwtTokenProvider.getExpiration());
    }
}
