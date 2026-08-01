// lib/models/notification.dart
//
// Backend /api/v1/notifications endpoint'inden dönen response'u parse eder.
// NotificationResponse { id, type, title, message, isRead, createdAt }

class NotificationModel {
  final String id;
  final String type; // alert | success | loss | security | info
  final String title;
  final String? message;
  final bool isRead;
  final String createdAt;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
        id: (json['id'] as String?) ?? '',
        type: (json['type'] as String?) ?? 'info',
        title: (json['title'] as String?) ?? '',
        message: json['message'] as String?,
        isRead: (json['isRead'] as bool?) ?? false,
        createdAt: (json['createdAt'] as String?) ?? '',
      );
}
