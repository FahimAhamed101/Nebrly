// models/service_model.dart
class Service {
  final String id;
  final String name;
  final String image;
  final double hourlyRate;
  final String description;
  final bool isActive;
  final Map<String, dynamic>? categoryType;
  final Map<String, dynamic>? category;
  final String? providerId; // Add this

  Service({
    required this.id,
    required this.name,
    required this.image,
    required this.hourlyRate,
    required this.description,
    required this.isActive,
    this.categoryType,
    this.category,
    this.providerId, // Add to constructor
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    String imageUrl = '';

    // Handle service image
    if (json['image'] != null) {
      if (json['image'] is String) {
        imageUrl = json['image'];
      } else if (json['image'] is Map && json['image']['url'] != null) {
        imageUrl = json['image']['url'] ?? '';
      }
    }

    // If no service image, try category type image
    if (imageUrl.isEmpty && json['categoryType']?['image'] != null) {
      if (json['categoryType']['image'] is String) {
        imageUrl = json['categoryType']['image'];
      } else if (json['categoryType']['image'] is Map) {
        imageUrl = json['categoryType']['image']['url'] ?? '';
      }
    }

    // If still no image, try category image
    if (imageUrl.isEmpty && json['categoryType']?['category']?['image'] != null) {
      if (json['categoryType']['category']['image'] is String) {
        imageUrl = json['categoryType']['category']['image'];
      } else if (json['categoryType']['category']['image'] is Map) {
        imageUrl = json['categoryType']['category']['image']['url'] ?? '';
      }
    }

    return Service(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      image: imageUrl,
      hourlyRate: (json['defaultHourlyRate'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      isActive: json['isActive'] ?? true,
      categoryType: json['categoryType'],
      category: json['categoryType']?['category'],
      providerId: json['providerId'], // Add this if available in your API
    );
  }

  // Add getters for price calculations
  double get minPrice => hourlyRate * 0.8;
  double get maxPrice => hourlyRate * 1.2;

  bool get hasNetworkImage => image.isNotEmpty && image.startsWith('http');
  bool get hasAssetImage => image.isNotEmpty && image.startsWith('assets/');
}