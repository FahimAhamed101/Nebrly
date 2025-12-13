// models/service_request_model.dart
class ServiceRequest {
  final String id;
  final String serviceType;
  final String problem;
  final String note;
  final DateTime scheduledDate;
  final String status;
  final double price;
  final int estimatedHours;
  final Commission commission;
  final Customer customer;
  final DateTime createdAt;
  final String providerNotes;

  ServiceRequest({
    required this.id,
    required this.serviceType,
    required this.problem,
    required this.note,
    required this.scheduledDate,
    required this.status,
    required this.price,
    required this.estimatedHours,
    required this.commission,
    required this.customer,
    required this.createdAt,
    required this.providerNotes,
  });

  factory ServiceRequest.fromJson(Map<String, dynamic> json) {
    return ServiceRequest(
      id: json['_id'] ?? '',
      serviceType: json['serviceType'] ?? '',
      problem: json['problem'] ?? '',
      note: json['note'] ?? '',
      scheduledDate: DateTime.parse(json['scheduledDate'] ?? DateTime.now().toString()),
      status: json['status'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      estimatedHours: json['estimatedHours'] ?? 0,
      commission: Commission.fromJson(json['commission'] ?? {}),
      customer: Customer.fromJson(json['customer'] ?? {}),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toString()),
      providerNotes: json['providerNotes'] ?? '',
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

class Customer {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final ProfileImage? profileImage;
  final Address address;

  Customer({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    this.profileImage,
    required this.address,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['_id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      profileImage: json['profileImage'] != null ? ProfileImage.fromJson(json['profileImage']) : null,
      address: Address.fromJson(json['address'] ?? {}),
    );
  }

  String get fullName => '$firstName $lastName';
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
      url: json['url'] ?? '',
      publicId: json['publicId'] ?? '',
    );
  }
}

class Address {
  final String street;
  final String city;
  final String state;
  final String zipCode;
  final String aptSuite;

  Address({
    required this.street,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.aptSuite,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      street: json['street'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      zipCode: json['zipCode'] ?? '',
      aptSuite: json['aptSuite'] ?? '',
    );
  }

  String get formattedAddress {
    final parts = [street, aptSuite.isNotEmpty ? 'Apt $aptSuite' : null, '$city, $state $zipCode'];
    return parts.where((part) => part != null).join(' ');
  }
}