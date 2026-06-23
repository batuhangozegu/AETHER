package com.aether.borsa.service;

import com.aether.borsa.dto.request.LoginRequest;
import com.aether.borsa.dto.request.RegisterRequest;
import com.aether.borsa.dto.response.TokenResponse;

public interface AuthService {

    TokenResponse register(RegisterRequest request);
    TokenResponse login(LoginRequest request);

}
