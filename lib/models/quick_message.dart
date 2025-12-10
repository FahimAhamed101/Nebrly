// models/quick_message.dart
class QuickMessage {
  final String id;
  final String message;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? createdByRole;
  final bool? isActive;
  final int? usageCount;

  QuickMessage({
    required this.id,
    required this.message,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.createdByRole,
    this.isActive,
    this.usageCount,
  });

  factory QuickMessage.fromJson(Map<String, dynamic> json) {
    return QuickMessage(
      id: json['_id'] ?? json['id'] ?? '',
      message: json['content'] ?? json['message'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      createdBy: json['createdBy'],
      createdByRole: json['createdByRole'],
      isActive: json['isActive'],
      usageCount: json['usageCount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'content': message, // For API compatibility
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdBy': createdBy,
      'createdByRole': createdByRole,
      'isActive': isActive,
      'usageCount': usageCount,
    };
  }

  QuickMessage copyWith({
    String? id,
    String? message,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? createdByRole,
    bool? isActive,
    int? usageCount,
  }) {
    return QuickMessage(
      id: id ?? this.id,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      createdByRole: createdByRole ?? this.createdByRole,
      isActive: isActive ?? this.isActive,
      usageCount: usageCount ?? this.usageCount,
    );
  }
}