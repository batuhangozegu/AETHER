package com.aether.borsa.dto.response;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@AllArgsConstructor
public class UserProfileResponse {

    private UUID id;
    private String username;
    private String email;
    private String kycStatus;
    private boolean twoFaEnabled;
    private LocalDateTime createdAt;
}
