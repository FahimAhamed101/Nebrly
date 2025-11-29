
class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String businessNameRegistered;
  final String businessNameDBA;
  final String providerRole;
  final String website;
  final List<Service> servicesProvided;
  final int experience;
  final double totalEarnings;
  final double availableBalance;
  final double pendingPayout;
  final BusinessAddress businessAddress;
  final BusinessHours businessHours;
  final BusinessServiceDays businessServiceDays;
  final List<ServiceArea> serviceAreas;
  final bool hasPayoutSetup;
  final String? profileImage;
  final String? businessLogo;
  final bool isApproved;
  final bool isAvailable;
  final double rating;
  final int totalReviews;
  final int totalJobsCompleted;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.businessNameRegistered,
    required this.businessNameDBA,
    required this.providerRole,
    required this.website,
    required this.servicesProvided,
    required this.experience,
    required this.totalEarnings,
    required this.availableBalance,
    required this.pendingPayout,
    required this.businessAddress,
    required this.businessHours,
    required this.businessServiceDays,
    required this.serviceAreas,
    required this.hasPayoutSetup,
    this.profileImage,
    this.businessLogo,
    required this.isApproved,
    required this.isAvailable,
    required this.rating,
    required this.totalReviews,
    required this.totalJobsCompleted,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      businessNameRegistered: json['businessNameRegistered'] ?? '',
      businessNameDBA: json['businessNameDBA'] ?? '',
      providerRole: json['providerRole'] ?? '',
      website: json['website'] ?? '',
      servicesProvided: (json['servicesProvided'] as List? ?? [])
          .map((service) => Service.fromJson(service))
          .toList(),
      experience: json['experience'] ?? 0,
      totalEarnings: (json['totalEarnings'] ?? 0).toDouble(),
      availableBalance: (json['availableBalance'] ?? 0).toDouble(),
      pendingPayout: (json['pendingPayout'] ?? 0).toDouble(),
      businessAddress: BusinessAddress.fromJson(json['businessAddress'] ?? {}),
      businessHours: BusinessHours.fromJson(json['businessHours'] ?? {}),
      businessServiceDays: BusinessServiceDays.fromJson(json['businessServiceDays'] ?? {}),
      serviceAreas: (json['serviceAreas'] as List? ?? [])
          .map((area) => ServiceArea.fromJson(area))
          .toList(),
      hasPayoutSetup: json['hasPayoutSetup'] ?? false,
      profileImage: json['profileImage']?['url'],
      businessLogo: json['businessLogo']?['url'],
      isApproved: json['isApproved'] ?? false,
      isAvailable: json['isAvailable'] ?? false,
      rating: (json['rating'] ?? 0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      totalJobsCompleted: json['totalJobsCompleted'] ?? 0,
    );
  }

  String get fullName {
    if (firstName.isEmpty && lastName.isEmpty) return 'Not Provided';
    return '$firstName $lastName'.trim();
  }

  String get fullAddress {
    final address = businessAddress;
    final parts = [
      address.street,
      address.city,
      if (address.state.isNotEmpty) address.state,
      if (address.zipCode.isNotEmpty) address.zipCode,
    ].where((part) => part.isNotEmpty).toList();
    return parts.join(', ');
  }

  String get serviceDaysFormatted {
    final days = businessServiceDays;
    return '${_capitalize(days.start)} - ${_capitalize(days.end)}';
  }

  String get workingHoursFormatted {
    final hours = businessHours;
    return '${hours.start} - ${hours.end}';
  }

  String get serviceAreasFormatted {
    if (serviceAreas.isEmpty) return 'No service areas';
    return serviceAreas.map((area) => area.zipCode).join(', ');
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

class Service {
  final String id;
  final String name;
  final double hourlyRate;

  Service({
    required this.id,
    required this.name,
    required this.hourlyRate,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      hourlyRate: (json['hourlyRate'] ?? 0).toDouble(),
    );
  }
}

class BusinessAddress {
  final String street;
  final String city;
  final String state;
  final String zipCode;

  BusinessAddress({
    required this.street,
    required this.city,
    required this.state,
    required this.zipCode,
  });

  factory BusinessAddress.fromJson(Map<String, dynamic> json) {
    return BusinessAddress(
      street: json['street'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      zipCode: json['zipCode'] ?? '',
    );
  }
}

class BusinessHours {
  final String start;
  final String end;

  BusinessHours({
    required this.start,
    required this.end,
  });

  factory BusinessHours.fromJson(Map<String, dynamic> json) {
    return BusinessHours(
      start: json['start'] ?? '',
      end: json['end'] ?? '',
    );
  }
}

class BusinessServiceDays {
  final String start;
  final String end;

  BusinessServiceDays({
    required this.start,
    required this.end,
  });

  factory BusinessServiceDays.fromJson(Map<String, dynamic> json) {
    return BusinessServiceDays(
      start: json['start'] ?? '',
      end: json['end'] ?? '',
    );
  }
}

class ServiceArea {
  final String id;
  final String zipCode;
  final String city;
  final String state;
  final bool isActive;
  final DateTime addedAt;

  ServiceArea({
    required this.id,
    required this.zipCode,
    required this.city,
    required this.state,
    required this.isActive,
    required this.addedAt,
  });

  factory ServiceArea.fromJson(Map<String, dynamic> json) {
    return ServiceArea(
      id: json['_id'] ?? '',
      zipCode: json['zipCode'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      isActive: json['isActive'] ?? false,
      addedAt: DateTime.parse(json['addedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}