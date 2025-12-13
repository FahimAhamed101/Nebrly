// models/search_provider.dart
class SearchProvider {
  final String id;
  final String firstName;
  final String lastName;
  final String? phone;
  final String businessNameRegistered;
  final double? rating;
  final int? totalReviews;
  final bool? isAvailable;
  final ProfileImage? profileImage;
  final BusinessLogo? businessLogo;
  final BusinessAddress? businessAddress;
  final List<ServiceProvided> servicesProvided;

  SearchProvider({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.phone,
    required this.businessNameRegistered,
    this.rating,
    this.totalReviews,
    this.isAvailable,
    this.profileImage,
    this.businessLogo,
    this.businessAddress,
    required this.servicesProvided,
  });

  factory SearchProvider.fromJson(Map<String, dynamic> json) {
    List<ServiceProvided> services = [];
    if (json['servicesProvided'] is List) {
      services = (json['servicesProvided'] as List)
          .map((s) => ServiceProvided.fromJson(s))
          .toList();
    }

    return SearchProvider(
      id: json['_id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      phone: json['phone'],
      businessNameRegistered: json['businessNameRegistered'] ?? '',
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      totalReviews: json['totalReviews'],
      isAvailable: json['isAvailable'],
      profileImage: json['profileImage'] != null
          ? ProfileImage.fromJson(json['profileImage'])
          : null,
      businessLogo: json['businessLogo'] != null
          ? BusinessLogo.fromJson(json['businessLogo'])
          : null,
      businessAddress: json['businessAddress'] != null
          ? BusinessAddress.fromJson(json['businessAddress'])
          : null,
      servicesProvided: services,
    );
  }

  String get displayName {
    if (businessNameRegistered.isNotEmpty) {
      return businessNameRegistered;
    }
    return '$firstName $lastName';
  }

  String get locationDisplay {
    if (businessAddress != null) {
      return '${businessAddress!.city}, ${businessAddress!.state}';
    }
    return 'Location not specified';
  }
}

class ProfileImage {
  final String url;
  final String publicId;

  ProfileImage({required this.url, required this.publicId});

  factory ProfileImage.fromJson(Map<String, dynamic> json) {
    return ProfileImage(
      url: json['url'] ?? '',
      publicId: json['publicId'] ?? '',
    );
  }
}

class BusinessLogo {
  final String url;
  final String publicId;

  BusinessLogo({required this.url, required this.publicId});

  factory BusinessLogo.fromJson(Map<String, dynamic> json) {
    return BusinessLogo(
      url: json['url'] ?? '',
      publicId: json['publicId'] ?? '',
    );
  }
}

class BusinessAddress {
  final String street;
  final String city;
  final String state;
  final String zipCode;
  final String? aptSuite;

  BusinessAddress({
    required this.street,
    required this.city,
    required this.state,
    required this.zipCode,
    this.aptSuite,
  });

  factory BusinessAddress.fromJson(Map<String, dynamic> json) {
    return BusinessAddress(
      street: json['street'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      zipCode: json['zipCode'] ?? '',
      aptSuite: json['aptSuite'],
    );
  }
}

class ServiceProvided {
  final String id;
  final String name;
  final String? description;
  final double? hourlyRate;

  ServiceProvided({
    required this.id,
    required this.name,
    this.description,
    this.hourlyRate,
  });

  factory ServiceProvided.fromJson(Map<String, dynamic> json) {
    return ServiceProvided(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      hourlyRate: json['hourlyRate'] != null
          ? (json['hourlyRate'] as num).toDouble()
          : null,
    );
  }
}

class RelatedService {
  final String id;
  final String name;
  final String? description;

  RelatedService({
    required this.id,
    required this.name,
    this.description,
  });

  factory RelatedService.fromJson(Map<String, dynamic> json) {
    return RelatedService(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
    );
  }
}