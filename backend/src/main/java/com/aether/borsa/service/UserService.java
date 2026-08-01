package com.aether.borsa.service;

import com.aether.borsa.dto.request.UpdateProfileRequest;
import com.aether.borsa.dto.response.UserProfileResponse;

import java.util.UUID;

public interface UserService {

    UserProfileResponse getProfile(UUID userId);
    UserProfileResponse updateProfile(UUID userId, UpdateProfileRequest request);
}
