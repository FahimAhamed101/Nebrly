// models/notification.dart
class NotificationItem {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String link;
  final bool isRead;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int v;

  NotificationItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.link,
    required this.isRead,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['_id'] ?? '',
      userId: json['user'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      link: json['link'] ?? '',
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      v: json['__v'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user': userId,
      'title': title,
      'body': body,
      'link': link,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      '__v': v,
    };
  }

  NotificationItem copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    String? link,
    bool? isRead,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? v,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      link: link ?? this.link,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      v: v ?? this.v,
    );
  }
}

class NotificationResponse {
  final bool success;
  final List<NotificationItem> data;

  NotificationResponse({
    required this.success,
    required this.data,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    return NotificationResponse(
      success: json['success'] ?? false,
      data: (json['data'] as List)
          .map((item) => NotificationItem.fromJson(item))
          .toList(),
    );
  }
}