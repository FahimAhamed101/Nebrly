// models/payout_information_model.dart
class PayoutInformationModel {
  final String id;
  final String accountHolderName;
  final String bankName;
  final String? bankCode;
  final String routingNumber;
  final String accountType;
  final String lastFourDigits;
  final String accountNumber;
  final String verificationStatus;
  final bool isVerified;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  PayoutInformationModel({
    required this.id,
    required this.accountHolderName,
    required this.bankName,
    required this.bankCode,
    required this.routingNumber,
    required this.accountType,
    required this.lastFourDigits,
    required this.accountNumber,
    required this.verificationStatus,
    required this.isVerified,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PayoutInformationModel.fromJson(Map<String, dynamic> json) {
    return PayoutInformationModel(
      id: json['id'] ?? '',
      accountHolderName: json['accountHolderName'] ?? '',
      bankName: json['bankName'] ?? '',
      bankCode: json['bankCode'],
      routingNumber: json['routingNumber'] ?? '',
      accountType: json['accountType'] ?? 'checking',
      lastFourDigits: json['lastFourDigits'] ?? '',
      accountNumber: json['accountNumber'] ?? '',
      verificationStatus: json['verificationStatus'] ?? 'pending',
      isVerified: json['isVerified'] ?? false,
      isActive: json['isActive'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accountHolderName': accountHolderName,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'routingNumber': routingNumber,
    };
  }
}

class PayoutInformationResponse {
  final bool success;
  final PayoutInformationData data;

  PayoutInformationResponse({
    required this.success,
    required this.data,
  });

  factory PayoutInformationResponse.fromJson(Map<String, dynamic> json) {
    return PayoutInformationResponse(
      success: json['success'] ?? false,
      data: PayoutInformationData.fromJson(json['data']),
    );
  }
}

class PayoutInformationData {
  final bool hasPayoutSetup;
  final PayoutInformationModel payoutInformation;

  PayoutInformationData({
    required this.hasPayoutSetup,
    required this.payoutInformation,
  });

  factory PayoutInformationData.fromJson(Map<String, dynamic> json) {
    return PayoutInformationData(
      hasPayoutSetup: json['hasPayoutSetup'] ?? false,
      payoutInformation: PayoutInformationModel.fromJson(json['payoutInformation']),
    );
  }
}