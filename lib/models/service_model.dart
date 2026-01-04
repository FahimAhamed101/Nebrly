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
  final List<String> providers; // List of provider IDs

  Service({
    required this.id,
    required this.name,
    required this.image,
    required this.hourlyRate,
    required this.description,
    required this.isActive,
    this.categoryType,
    this.category,
    this.providers = const [], // Initialize as empty list
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

    // Handle providers array
    List<String> providersList = [];
    if (json['providers'] != null && json['providers'] is List) {
      providersList = List<String>.from(json['providers']);
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
      providers: providersList,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'image': image,
      'defaultHourlyRate': hourlyRate,
      'description': description,
      'isActive': isActive,
      'categoryType': categoryType,
      'providers': providers,
    };
  }

  // Add getters for price calculations
  double get minPrice => hourlyRate * 0.8;
  double get maxPrice => hourlyRate * 1.2;

  // Get the first provider ID if available
  String? get firstProviderId => providers.isNotEmpty ? providers.first : null;

  // Check if service has providers
  bool get hasProviders => providers.isNotEmpty;

  // Get provider count
  int get providerCount => providers.length;

  // Image helpers
  bool get hasNetworkImage => image.isNotEmpty && image.startsWith('http');
  bool get hasAssetImage => image.isNotEmpty && image.startsWith('assets/');
  bool get hasImage => image.isNotEmpty;

  // Copy with method for creating modified copies
  Service copyWith({
    String? id,
    String? name,
    String? image,
    double? hourlyRate,
    String? description,
    bool? isActive,
    Map<String, dynamic>? categoryType,
    Map<String, dynamic>? category,
    List<String>? providers,
  }) {
    return Service(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      categoryType: categoryType ?? this.categoryType,
      category: category ?? this.category,
      providers: providers ?? this.providers,
    );
  }

  @override
  String toString() {
    return 'Service(id: $id, name: $name, hourlyRate: $hourlyRate, providers: ${providers.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Service &&
        other.id == id &&
        other.name == name &&
        other.hourlyRate == hourlyRate;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ hourlyRate.hashCode;
  }
}