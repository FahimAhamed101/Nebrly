// models/user_request.dart
import 'dart:ui';

import 'package:flutter/material.dart';

enum RequestStatus { pending, accepted, cancelled, done }

class UserRequest {
  final String id;
  final String serviceName;
  final double averagePrice;
  final DateTime date;
  final String time;
  final String? imagePath;
  final String status;
  final String? problemDescription;
  final Provider? provider;
  final String address;
  final List<RequestedService> requestedServices;
  final DateTime createdAt;
  final DateTime? scheduledDate;
  final double price;
  final int estimatedHours;
  final Commission? commission;
  final Review? review;
  final String? customerId;
  // Bundle-specific fields
  final bool isBundle;
  final String? bundleTitle;
  final String? bundleDescription;
  final String? bundleCategory;
  final int? maxParticipants;
  final int? currentParticipants;
  final DateTime? expiresAt;
  final List<BundleService>? bundleServices;

  // For backward compatibility with demo screens
  final String? providerName;
  final String? providerImage;
  final double? providerRating;
  final int? providerReviewCount;
  final bool isTeamService;
  final List<String>? teamMembers;
  final String? bundleType;
  final String? cancellationReason;
  final DateTime? cancellationTime;

  UserRequest({
    required this.id,
    this.customerId,
    required this.serviceName,
    required this.averagePrice,
    required this.date,
    required this.time,
    this.imagePath,
    required this.status,
    this.problemDescription,
    this.provider,
    required this.address,
    required this.requestedServices,
    required this.createdAt,
    this.scheduledDate,
    required this.price,
    required this.estimatedHours,
    this.commission,
    this.review,
    this.isBundle = false,
    this.bundleTitle,
    this.bundleDescription,
    this.bundleCategory,
    this.maxParticipants,
    this.currentParticipants,
    this.expiresAt,
    this.bundleServices,

    // Demo fields
    this.providerName,
    this.providerImage,
    this.providerRating,
    this.providerReviewCount,
    this.isTeamService = false,
    this.teamMembers,
    this.bundleType,
    this.cancellationReason,
    this.cancellationTime,
  });

  factory UserRequest.fromJson(Map<String, dynamic> json) {
    // Parse scheduled date
    DateTime? scheduledDate;
    if (json['scheduledDate'] != null) {
      try {
        scheduledDate = DateTime.parse(json['scheduledDate']);
      } catch (e) {
        scheduledDate = null;
      }
    }

    // Parse provider
    Provider? provider;
    if (json['provider'] != null && json['provider'] is Map<String, dynamic>) {
      provider = Provider.fromJson(json['provider']);
    }

    // Parse requested services
    List<RequestedService> requestedServices = [];
    if (json['requestedServices'] is List) {
      for (var service in json['requestedServices']) {
        requestedServices.add(RequestedService.fromJson(service));
      }
    }

    // Parse commission
    Commission? commission;
    if (json['commission'] != null && json['commission'] is Map<String, dynamic>) {
      commission = Commission.fromJson(json['commission']);
    }

    // Parse review
    Review? review;
    if (json['review'] != null && json['review'] is Map<String, dynamic>) {
      review = Review.fromJson(json['review']);
    }

    // Get address from location info
    String address = '';
    if (json['locationInfo'] != null && json['locationInfo'] is Map<String, dynamic>) {
      final location = json['locationInfo']['customerAddress'];
      if (location != null) {
        address = '${location['street'] ?? ''}, ${location['city'] ?? ''}, ${location['state'] ?? ''} ${location['zipCode'] ?? ''}';
      }
    }
    String? customerId;
    if (json['creator'] != null && json['creator'] is Map<String, dynamic>) {
      customerId = json['creator']['_id'];
    } else if (json['customer'] != null) {
      if (json['customer'] is String) {
        customerId = json['customer'];
      } else if (json['customer'] is Map<String, dynamic>) {
        customerId = json['customer']['_id'];
      }
    }

    return UserRequest(
      id: json['_id'] ?? '',
      serviceName: json['serviceType'] ?? 'Unknown Service',
      averagePrice: (json['price'] ?? 0).toDouble(),
      date: scheduledDate ?? DateTime.now(),
      time: '14:00',
      imagePath: provider?.businessLogo?.url,
      status: json['status'] ?? 'pending',
      problemDescription: json['problem'] ?? '',
      provider: provider,
      address: address,
      requestedServices: requestedServices,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      scheduledDate: scheduledDate,
      price: (json['price'] ?? 0).toDouble(),
      estimatedHours: (json['estimatedHours'] ?? 0).toInt(),
      commission: commission,
      review: review,
      customerId: customerId,
      providerName: provider?.fullName,
      providerImage: provider?.businessLogo?.url,
      providerRating: provider?.rating,
    );
  }

  factory UserRequest.fromBundleJson(Map<String, dynamic> json) {
    // Parse provider
    Provider? provider;
    if (json['provider'] != null && json['provider'] is Map<String, dynamic>) {
      provider = Provider.fromJson(json['provider']);
    }

    // Parse bundle services
    List<BundleService> bundleServices = [];
    if (json['services'] is List) {
      for (var service in json['services']) {
        bundleServices.add(BundleService.fromJson(service));
      }
    }

    // Get address from bundle
    String address = '';
    if (json['address'] != null && json['address'] is Map<String, dynamic>) {
      final addr = json['address'];
      address = '${addr['street'] ?? ''}, ${addr['city'] ?? ''}, ${addr['state'] ?? ''} ${addr['aptSuite'] ?? ''}';
    }

    // Parse service date
    DateTime? serviceDate;
    if (json['serviceDate'] != null) {
      try {
        serviceDate = DateTime.parse(json['serviceDate']);
      } catch (e) {
        serviceDate = DateTime.now();
      }
    }

    // Parse expires at
    DateTime? expiresAt;
    if (json['expiresAt'] != null) {
      try {
        expiresAt = DateTime.parse(json['expiresAt']);
      } catch (e) {
        expiresAt = null;
      }
    }

    // Calculate total price from pricing
    double finalPrice = 0.0;
    if (json['pricing'] != null && json['pricing'] is Map<String, dynamic>) {
      finalPrice = (json['pricing']['finalPrice'] ?? 0).toDouble();
    }

    // Get service names
    String serviceName = json['title'] ?? 'Bundle Service';
    if (bundleServices.isNotEmpty) {
      serviceName = bundleServices.map((s) => s.name).join(', ');
    }

    return UserRequest(
      id: json['_id'] ?? '',
      serviceName: serviceName,
      averagePrice: finalPrice,
      date: serviceDate ?? DateTime.now(),
      time: '${json['serviceTimeStart'] ?? '09:00'}',
      imagePath: provider?.businessLogo?.url,
      status: json['status'] ?? 'pending',
      problemDescription: json['description'] ?? '',
      provider: provider,
      address: address,
      requestedServices: [],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      scheduledDate: serviceDate,
      price: finalPrice,
      estimatedHours: bundleServices.fold(0, (sum, s) => sum + s.estimatedHours),
      isBundle: true,
      bundleTitle: json['title'] ?? '',
      bundleDescription: json['description'] ?? '',
      bundleCategory: json['category'] ?? '',
      maxParticipants: json['maxParticipants'] ?? 0,
      currentParticipants: json['currentParticipants'] ?? 0,
      expiresAt: expiresAt,
      bundleServices: bundleServices,
      providerName: provider?.fullName,
      providerImage: provider?.businessLogo?.url,
      providerRating: provider?.rating,
    );
  }

  // Demo data factories for testing
  factory UserRequest.demoPendingAppliance() {
    return UserRequest(
      id: "1",
      serviceName: "Appliance Repairs",
      averagePrice: 63.0,
      date: DateTime(2025, 1, 18),
      time: "14:00",
      imagePath: "assets/images/repares.png",
      status: "pending",
      problemDescription: "Dishwasher not draining properly, making strange noises",
      provider: Provider(
        id: "1",
        firstName: "Mike's",
        lastName: "Repair Service",
        rating: 4.8,
      ),
      address: "123 Oak Street, Springfield, IL 62704",
      requestedServices: [],
      createdAt: DateTime.now(),
      price: 75,
      estimatedHours: 2,
      providerName: "Mike's Repair Service",
      providerImage: "assets/images/jane.png",
      providerRating: 4.8,
      providerReviewCount: 42,
    );
  }

  factory UserRequest.demoAcceptedAppliance() {
    return UserRequest(
      id: "2",
      serviceName: "Appliance Repairs",
      averagePrice: 63.0,
      date: DateTime(2025, 1, 17),
      time: "14:00",
      imagePath: "assets/images/repares.png",
      status: "accepted",
      problemDescription: "Washing machine not spinning, water leaking",
      provider: Provider(
        id: "2",
        firstName: "Quick Fix",
        lastName: "Solutions",
        rating: 4.2,
      ),
      address: "456 Pine Street, Springfield, IL 62704",
      requestedServices: [],
      createdAt: DateTime.now(),
      price: 75,
      estimatedHours: 2,
      providerName: "Quick Fix Solutions",
      providerImage: "assets/images/ethan.png",
      providerRating: 4.2,
      providerReviewCount: 18,
    );
  }

  factory UserRequest.demoCancelledCleaning() {
    return UserRequest(
      id: "3",
      serviceName: "House Cleaning",
      averagePrice: 45.0,
      date: DateTime(2025, 1, 16),
      time: "10:30",
      imagePath: "assets/images/cleaning.png",
      status: "cancelled",
      problemDescription: "Deep cleaning required for 3-bedroom house",
      provider: Provider(
        id: "3",
        firstName: "Clean Pro",
        lastName: "Services",
        rating: 4.6,
      ),
      address: "789 Elm Street, Springfield, IL 62704",
      requestedServices: [],
      createdAt: DateTime.now(),
      price: 75,
      estimatedHours: 2,
      isTeamService: true,
      bundleType: "2-Person Team",
      teamMembers: ["Emma Davis", "John Miller"],
      cancellationReason: "The service was no longer required due to unforeseen circumstances.",
      cancellationTime: DateTime(2025, 1, 16, 13, 44),
      providerName: "Clean Pro Services",
      providerImage: "assets/images/maria.png",
      providerRating: 4.6,
      providerReviewCount: 31,
    );
  }

  factory UserRequest.demoDoneWindow() {
    return UserRequest(
      id: "4",
      serviceName: "Window Washing",
      averagePrice: 50.0,
      date: DateTime(2025, 1, 15),
      time: "11:00",
      imagePath: "assets/images/cleaning.png",
      status: "completed",
      problemDescription: "Exterior window cleaning for 2-story house",
      provider: Provider(
        id: "4",
        firstName: "Crystal Clear",
        lastName: "Windows",
        rating: 4.7,
      ),
      address: "369 Walnut Street, Springfield, IL 62704",
      requestedServices: [],
      createdAt: DateTime.now(),
      price: 75,
      estimatedHours: 2,
      isTeamService: true,
      bundleType: "2-Person Team",
      teamMembers: ["John Miller", "Sarah Wilson"],
      providerName: "Crystal Clear Windows",
      providerImage: "assets/images/maria.png",
      providerRating: 4.7,
      providerReviewCount: 28,
    );
  }

  // Static method to get all demo requests
  static List<UserRequest> getAllDemoRequests() {
    return [
      UserRequest.demoPendingAppliance(),
      UserRequest.demoAcceptedAppliance(),
      UserRequest.demoCancelledCleaning(),
      UserRequest.demoDoneWindow(),
    ];
  }

  String get statusText {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'cancelled':
        return 'Cancelled';
      case 'completed':
        return 'Completed';
      case 'done':
        return 'Done';
      default:
        return 'Pending';
    }
  }

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFF6B35);
      case 'accepted':
        return const Color(0xFF0E7A60);
      case 'cancelled':
        return const Color(0xFFF44336);
      case 'completed':
      case 'done':
        return const Color(0xFF4CAF50);
      default:
        return const Color(0xFFFF6B35);
    }
  }

  String get formattedDate {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  bool get isOpen {
    return status.toLowerCase() == 'pending' || status.toLowerCase() == 'accepted';
  }

  bool get isClosed {
    return status.toLowerCase() == 'cancelled' ||
        status.toLowerCase() == 'completed' ||
        status.toLowerCase() == 'done';
  }
}

class Provider {
  final String id;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? businessNameRegistered;
  final double rating;
  final ProfileImage? profileImage;
  final BusinessLogo? businessLogo;

  Provider({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.businessNameRegistered,
    required this.rating,
    this.profileImage,
    this.businessLogo,
  });

  factory Provider.fromJson(Map<String, dynamic> json) {
    return Provider(
      id: json['_id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      phone: json['phone'],
      businessNameRegistered: json['businessNameRegistered'],
      rating: (json['rating'] ?? 0).toDouble(),
      profileImage: json['profileImage'] != null ? ProfileImage.fromJson(json['profileImage']) : null,
      businessLogo: json['businessLogo'] != null ? BusinessLogo.fromJson(json['businessLogo']) : null,
    );
  }

  String get fullName => '$firstName $lastName';
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

class RequestedService {
  final String name;
  final String status;
  final double price;
  final int estimatedHours;

  RequestedService({
    required this.name,
    required this.status,
    required this.price,
    required this.estimatedHours,
  });

  factory RequestedService.fromJson(Map<String, dynamic> json) {
    return RequestedService(
      name: json['name'] ?? '',
      status: json['status'] ?? 'pending',
      price: (json['price'] ?? 0).toDouble(),
      estimatedHours: (json['estimatedHours'] ?? 0).toInt(),
    );
  }
}

class BundleService {
  final String name;
  final double hourlyRate;
  final int estimatedHours;

  BundleService({
    required this.name,
    required this.hourlyRate,
    required this.estimatedHours,
  });

  factory BundleService.fromJson(Map<String, dynamic> json) {
    return BundleService(
      name: json['name'] ?? '',
      hourlyRate: (json['hourlyRate'] ?? 0).toDouble(),
      estimatedHours: (json['estimatedHours'] ?? 0).toInt(),
    );
  }
}

class Commission {
  final double rate;
  final double amount;
  final double providerAmount;

  Commission({
    required this.rate,
    required this.amount,
    required this.providerAmount,
  });

  factory Commission.fromJson(Map<String, dynamic> json) {
    return Commission(
      rate: (json['rate'] ?? 0).toDouble(),
      amount: (json['amount'] ?? 0).toDouble(),
      providerAmount: (json['providerAmount'] ?? 0).toDouble(),
    );
  }
}
class Service {
  final String id;
  final String name;
  final String image;
  final double hourlyRate;
  final String description;
  final bool isActive;

  Service({
    required this.id,
    required this.name,
    required this.image,
    required this.hourlyRate,
    required this.description,
    required this.isActive,
  });
}
class Review {
  final int? rating;
  final String? comment;
  final DateTime createdAt;

  Review({
    this.rating,
    this.comment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      rating: json['rating'],
      comment: json['comment'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}