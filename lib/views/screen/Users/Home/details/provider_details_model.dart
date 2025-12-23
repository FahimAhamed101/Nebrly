// models/provider_details_model.dart
class ProviderDetails {
  final String id;
  final String businessName;
  final double rating;
  final int totalReviews;
  final List<Service> services;
  final Service selectedService;
  final List<Service> otherServices;

  ProviderDetails({
    required this.id,
    required this.businessName,
    required this.rating,
    required this.totalReviews,
    required this.services,
    required this.selectedService,
    required this.otherServices,
  });

  factory ProviderDetails.fromJson(Map<String, dynamic> json) {
    return ProviderDetails(
      id: json['provider']['id'] ?? '',
      businessName: json['provider']['businessName'] ?? '',
      rating: (json['provider']['rating'] ?? 0).toDouble(),
      totalReviews: json['provider']['totalReviews'] ?? 0,
      selectedService: Service.fromJson(json['selectedService']),
      otherServices: List<Service>.from(
          json['otherServices']?.map((x) => Service.fromJson(x)) ?? []),
      services: [
        Service.fromJson(json['selectedService']),
        ...List<Service>.from(
            json['otherServices']?.map((x) => Service.fromJson(x)) ?? [])
      ],
    );
  }
}

class Service {
  final String name;
  final double hourlyRate;
  final String id;

  Service({
    required this.name,
    required this.hourlyRate,
    required this.id,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      name: json['name'] ?? '',
      hourlyRate: (json['hourlyRate'] ?? 0).toDouble(),
      id: json['_id'] ?? '',
    );
  }
}