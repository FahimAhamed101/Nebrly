class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final bool isActive;
  final String role;
  final String stripeCustomerId;
  final String createdAt;
  final String updatedAt;
  final ProfileImage profileImage;
  final Address address;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.isActive,
    required this.role,
    required this.stripeCustomerId,
    required this.createdAt,
    required this.updatedAt,
    required this.profileImage,
    required this.address,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json["_id"] ?? '',
      firstName: json["firstName"] ?? '',
      lastName: json["lastName"] ?? '',
      email: json["email"] ?? '',
      phone: json["phone"] ?? '',
      isActive: json["isActive"] ?? false,
      role: json["role"] ?? '',
      stripeCustomerId: json["stripeCustomerId"] ?? '',
      createdAt: json["createdAt"] ?? '',
      updatedAt: json["updatedAt"] ?? '',
      profileImage: ProfileImage.fromJson(json["profileImage"] ?? {}),
      address: Address.fromJson(json["address"] ?? {}),
    );
  }
}

class ProfileImage {
  final String url;
  final String publicId;

  ProfileImage({required this.url, required this.publicId});

  factory ProfileImage.fromJson(Map<String, dynamic> json) {
    return ProfileImage(
      url: json["url"] ?? '',
      publicId: json["publicId"] ?? '',
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
      street: json["street"] ?? '',
      city: json["city"] ?? '',
      state: json["state"] ?? '',
      zipCode: json["zipCode"] ?? '',
      aptSuite: json["aptSuite"] ?? '',
    );
  }
}
