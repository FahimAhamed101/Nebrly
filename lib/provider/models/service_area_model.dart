// models/service_area_model.dart
class ServiceAreaModel {
  final String id;
  final String zipCode;
  final String city;
  final String state;
  final bool isActive;
  final DateTime addedAt;

  ServiceAreaModel({
    required this.id,
    required this.zipCode,
    required this.city,
    required this.state,
    required this.isActive,
    required this.addedAt,
  });

  factory ServiceAreaModel.fromJson(Map<String, dynamic> json) {
    return ServiceAreaModel(
      id: json['_id'] ?? '',
      zipCode: json['zipCode'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      isActive: json['isActive'] ?? false,
      addedAt: DateTime.parse(json['addedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'zipCode': zipCode,
      'city': city,
      'state': state,
    };
  }
}

class ServiceAreaResponse {
  final bool success;
  final String message;
  final ServiceAreaData data;

  ServiceAreaResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ServiceAreaResponse.fromJson(Map<String, dynamic> json) {
    return ServiceAreaResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: ServiceAreaData.fromJson(json['data']),
    );
  }
}

class ServiceAreaData {
  final List<ServiceAreaModel> serviceAreas;
  final int totalAreas;
  final int activeAreas;

  ServiceAreaData({
    required this.serviceAreas,
    required this.totalAreas,
    required this.activeAreas,
  });

  factory ServiceAreaData.fromJson(Map<String, dynamic> json) {
    return ServiceAreaData(
      serviceAreas: (json['serviceAreas'] as List)
          .map((area) => ServiceAreaModel.fromJson(area))
          .toList(),
      totalAreas: json['totalAreas'] ?? 0,
      activeAreas: json['activeAreas'] ?? 0,
    );
  }
}