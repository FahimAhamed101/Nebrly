// models/bundle_model.dart
class Bundle {
  final String id;
  final String title;
  final String description;
  final String category;
  final String categoryTypeName;
  final List<Service> services;
  final DateTime serviceDate;
  final String serviceTimeStart;
  final String serviceTimeEnd;
  final int bundleDiscount;
  final double finalPrice;
  final Creator creator;
  final List<Participant> participants;
  final Address address;
  final String status;
  final int maxParticipants;
  final int currentParticipants;
  final int availableSpots;
  final String? shareToken;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String userRole;
  final bool canJoin;
  final Pricing pricing;

  Bundle({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.categoryTypeName,
    required this.services,
    required this.serviceDate,
    required this.serviceTimeStart,
    required this.serviceTimeEnd,
    required this.bundleDiscount,
    required this.finalPrice,
    required this.creator,
    required this.participants,
    required this.address,
    required this.status,
    required this.maxParticipants,
    required this.currentParticipants,
    required this.availableSpots,
    this.shareToken,
    required this.createdAt,
    required this.expiresAt,
    required this.userRole,
    required this.canJoin,
    required this.pricing,
  });

  factory Bundle.fromJson(Map<String, dynamic> json) {
    return Bundle(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      categoryTypeName: json['categoryTypeName'] ?? '',
      services: (json['services'] as List?)
          ?.map((s) => Service.fromJson(s))
          .toList() ?? [],
      serviceDate: DateTime.parse(json['serviceDate'] ?? DateTime.now().toString()),
      serviceTimeStart: json['serviceTimeStart'] ?? '00:00',
      serviceTimeEnd: json['serviceTimeEnd'] ?? '00:00',
      bundleDiscount: json['bundleDiscount'] ?? 0,
      finalPrice: (json['finalPrice'] ?? 0).toDouble(),
      creator: Creator.fromJson(json['creator'] ?? {}),
      participants: (json['participants'] as List?)
          ?.map((p) => Participant.fromJson(p))
          .toList() ?? [],
      address: Address.fromJson(json['address'] ?? {}),
      status: json['status'] ?? 'pending',
      maxParticipants: json['maxParticipants'] ?? 0,
      currentParticipants: json['currentParticipants'] ?? 0,
      availableSpots: json['availableSpots'] ?? 0,
      shareToken: json['shareToken'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toString()),
      expiresAt: DateTime.parse(json['expiresAt'] ?? DateTime.now().add(const Duration(days: 7)).toString()),
      userRole: json['userRole'] ?? 'viewer',
      canJoin: json['canJoin'] ?? false,
      pricing: Pricing.fromJson(json['pricing'] ?? {}),
    );
  }

  double get originalPrice => pricing.originalPrice;
  double get discountAmount => pricing.discountAmount;
  int get discountPercent => pricing.discountPercent;
}

class Pricing {
  final double originalPrice;
  final double discountAmount;
  final double finalPrice;
  final int discountPercent;

  Pricing({
    required this.originalPrice,
    required this.discountAmount,
    required this.finalPrice,
    required this.discountPercent,
  });

  factory Pricing.fromJson(Map<String, dynamic> json) {
    return Pricing(
      originalPrice: (json['originalPrice'] ?? 0).toDouble(),
      discountAmount: (json['discountAmount'] ?? 0).toDouble(),
      finalPrice: (json['finalPrice'] ?? 0).toDouble(),
      discountPercent: (json['discountPercent'] ?? 0).toInt(),
    );
  }
}

class Creator {
  final String id;
  final String firstName;
  final String lastName;
  final ProfileImage profileImage;
  final Address address;

  Creator({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.profileImage,
    required this.address,
  });

  factory Creator.fromJson(Map<String, dynamic> json) {
    return Creator(
      id: json['_id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      profileImage: ProfileImage.fromJson(json['profileImage'] ?? {}),
      address: Address.fromJson(json['address'] ?? {}),
    );
  }

  String get fullName => '$firstName $lastName';
}

class Participant {
  final String id;
  final String status;
  final DateTime joinedAt;
  final Customer customer;
  final Address address;

  Participant({
    required this.id,
    required this.status,
    required this.joinedAt,
    required this.customer,
    required this.address,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      id: json['_id'] ?? '',
      status: json['status'] ?? '',
      joinedAt: DateTime.parse(json['joinedAt'] ?? DateTime.now().toString()),
      customer: Customer.fromJson(json['customer'] ?? {}),
      address: Address.fromJson(json['address'] ?? {}),
    );
  }
}

class Customer {
  final String id;
  final String firstName;
  final String lastName;
  final ProfileImage profileImage;
  final Address address;

  Customer({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.profileImage,
    required this.address,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['_id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      profileImage: ProfileImage.fromJson(json['profileImage'] ?? {}),
      address: Address.fromJson(json['address'] ?? {}),
    );
  }

  String get fullName => '$firstName $lastName';
}

class Address {
  final String street;
  final String city;
  final String state;
  final String aptSuite;
  final String? zipCode;

  Address({
    required this.street,
    required this.city,
    required this.state,
    required this.aptSuite,
    this.zipCode,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      street: json['street']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      aptSuite: json['aptSuite']?.toString() ?? '',
      zipCode: json['zipCode']?.toString(),
    );
  }

  String get formattedAddress {
    final parts = [
      street,
      aptSuite.isNotEmpty ? 'Apt $aptSuite' : null,
      '$city, $state ${zipCode ?? ''}'
    ];
    return parts.where((part) => part != null && part.isNotEmpty).join(' ');
  }
}

class ProfileImage {
  final String url;
  final String publicId;

  ProfileImage({
    required this.url,
    required this.publicId,
  });

  factory ProfileImage.fromJson(Map<String, dynamic> json) {
    return ProfileImage(
      url: json['url']?.toString() ?? '',
      publicId: json['publicId']?.toString() ?? '',
    );
  }
}

class Service {
  final String id;
  final String name;
  final double hourlyRate;
  final double estimatedHours;

  Service({
    required this.id,
    required this.name,
    required this.hourlyRate,
    required this.estimatedHours,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      hourlyRate: (json['hourlyRate'] ?? 0).toDouble(),
      estimatedHours: (json['estimatedHours'] ?? 0).toDouble(),
    );
  }
}