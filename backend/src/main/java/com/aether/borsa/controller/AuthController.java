package com.aether.borsa.controller;


import com.aether.borsa.dto.request.LoginRequest;
import com.aether.borsa.dto.request.RegisterRequest;
import com.aether.borsa.dto.response.TokenResponse;
import com.aether.borsa.service.AuthService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService){
        this.authService = authService;
    }

    @PostMapping("/register")
    public ResponseEntity<TokenResponse> register(@RequestBody @Valid RegisterRequest request){
        return ResponseEntity.status(201).body(authService.register(request));
    }

    @PostMapping("/login")
    public ResponseEntity<TokenResponse> login(@RequestBody @Valid LoginRequest request){
        return ResponseEntity.ok(authService.login(request));
    }

}
