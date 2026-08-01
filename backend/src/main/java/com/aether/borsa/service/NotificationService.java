package com.aether.borsa.service;

import com.aether.borsa.dto.response.NotificationResponse;
import com.aether.borsa.model.entity.User;

import java.util.List;
import java.util.UUID;

public interface NotificationService {

    List<NotificationResponse> getNotifications(UUID userId);
    void markAsRead(UUID userId, UUID notificationId);
    void markAllAsRead(UUID userId);

    /** Internal helper used by other services (order close, price alarms, ...) to raise a notification. */
    void notify(User user, String type, String title, String message);
}
