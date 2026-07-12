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
            throw new RuntimeException("Bu email veya kullanıcı adı zaten kullanılıyor");
        }
        User user = User.builder()
                .username(request.getUsername())
                .email(request.getEmail())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .build();

        userRepository.save(user);

       String token = jwtTokenProvider.generateToken(user.getId());
       return new TokenResponse(token,null, "Bearer" , jwtTokenProvider.getExpiration());
    }

    @Override
    public TokenResponse login(LoginRequest request) {

        User  user = userRepository.findByEmail(request.getEmail()).orElseThrow(() -> new RuntimeException("Bu email ile hesap bulunamadı"));
        if(!passwordEncoder.matches(request.getPassword(), user.getPasswordHash()))
        {
            throw new RuntimeException("Şifre hatalı");
        }
        String token = jwtTokenProvider.generateToken(user.getId());
        return new TokenResponse(token, null, "Bearer", jwtTokenProvider.getExpiration());
    }
}
