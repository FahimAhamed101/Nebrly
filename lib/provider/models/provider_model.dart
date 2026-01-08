// provider_model.dart
class ProviderRegisterRequest {
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String confirmPassword;
  final String phone;
  final String businessNameRegistered;
  final String businessNameDBA;
  final String providerRole;
  final String businessPhone;
  final String website;
  final String servicesProvided;
  final String businessServiceStart;
  final String businessServiceEnd;
  final String businessHoursStart;
  final String businessHoursEnd;
  final String hourlyRate;
  final String businessAddressStreet;
  final String businessAddressCity;
  final String businessAddressState;
  final String businessAddressZipCode;
  final String experience;

  ProviderRegisterRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.phone,
    required this.businessNameRegistered,
    required this.businessNameDBA,
    required this.providerRole,
    required this.businessPhone,
    required this.website,
    required this.servicesProvided,
    required this.businessServiceStart,
    required this.businessServiceEnd,
    required this.businessHoursStart,
    required this.businessHoursEnd,
    required this.hourlyRate,
    required this.businessAddressStreet,
    required this.businessAddressCity,
    required this.businessAddressState,
    required this.businessAddressZipCode,
    required this.experience,
  });

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'password': password,
      'confirmPassword': confirmPassword,
      'phone': phone,
      'businessNameRegistered': businessNameRegistered,
      'businessNameDBA': businessNameDBA,
      'providerRole': providerRole,
      'businessPhone': businessPhone,
      'website': website,
      'servicesProvided': servicesProvided,
      'businessServiceStart': businessServiceStart,
      'businessServiceEnd': businessServiceEnd,
      'businessHoursStart': businessHoursStart,
      'businessHoursEnd': businessHoursEnd,
      'hourlyRate': hourlyRate,
      'businessAddressStreet': businessAddressStreet,
      'businessAddressCity': businessAddressCity,
      'businessAddressState': businessAddressState,
      'businessAddressZipCode': businessAddressZipCode,
      'experience': experience,
    };
  }
}

class ProviderRegisterResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  ProviderRegisterResponse({
    required this.success,
    required this.message,
    this.data,
  });

  String? get token => data?['token'];
  Map<String, dynamic>? get user => data?['user'];
  String? get userId => user?['id'];

  factory ProviderRegisterResponse.fromJson(Map<String, dynamic> json) {
    return ProviderRegisterResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'],
    );
  }
}

// Verify Information Models
class VerifyInformationRequest {
  final String einNumber;
  final String firstName;
  final String lastName;
  final String businessRegisteredCountry;

  VerifyInformationRequest({
    required this.einNumber,
    required this.firstName,
    required this.lastName,
    required this.businessRegisteredCountry,
  });

  Map<String, dynamic> toJson() {
    return {
      'einNumber': einNumber,
      'firstName': firstName,
      'lastName': lastName,
      'businessRegisteredCountry': businessRegisteredCountry,
    };
  }
}

class VerifyInformationResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  VerifyInformationResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory VerifyInformationResponse.fromJson(Map<String, dynamic> json) {
    return VerifyInformationResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'],
    );
  }
}