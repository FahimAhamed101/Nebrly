class MoneyRequest {
  final String id;
  final Provider provider;
  final String customer;
  final double amount;
  final double tipAmount;
  final double totalAmount;
  final String description;
  final String status;
  final DateTime dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final PaymentDetails paymentDetails;
  final Commission commission;
  final Bundle? bundle;
  final ServiceRequestRef? serviceRequest;
  final List<StatusHistory> statusHistory;

  MoneyRequest({
    required this.id,
    required this.provider,
    required this.customer,
    required this.amount,
    required this.tipAmount,
    required this.totalAmount,
    required this.description,
    required this.status,
    required this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    required this.paymentDetails,
    required this.commission,
    this.bundle,
    this.serviceRequest,
    required this.statusHistory,
  });

  factory MoneyRequest.fromJson(Map<String, dynamic> json) {
    return MoneyRequest(
      id: json['_id'] ?? '',
      provider: Provider.fromJson(json['provider'] ?? {}),
      customer: json['customer'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      tipAmount: (json['tipAmount'] ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      status: json['status'] ?? 'pending',
      dueDate: DateTime.parse(json['dueDate'] ?? DateTime.now().toIso8601String()),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      paymentDetails: PaymentDetails.fromJson(json['paymentDetails'] ?? {}),
      commission: Commission.fromJson(json['commission'] ?? {}),
      bundle: json['bundle'] != null ? Bundle.fromJson(json['bundle']) : null,
      serviceRequest: json['serviceRequest'] != null
          ? ServiceRequestRef.fromJson(json['serviceRequest'])
          : null,
      statusHistory: (json['statusHistory'] as List<dynamic>?)
          ?.map((e) => StatusHistory.fromJson(e))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'provider': provider.toJson(),
      'customer': customer,
      'amount': amount,
      'tipAmount': tipAmount,
      'totalAmount': totalAmount,
      'description': description,
      'status': status,
      'dueDate': dueDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'paymentDetails': paymentDetails.toJson(),
      'commission': commission.toJson(),
      'bundle': bundle?.toJson(),
      'serviceRequest': serviceRequest?.toJson(),
      'statusHistory': statusHistory.map((e) => e.toJson()).toList(),
    };
  }
}

class Provider {
  final String id;
  final String email;
  final String phone;
  final String businessNameRegistered;
  final BusinessLogo businessLogo;

  Provider({
    required this.id,
    required this.email,
    required this.phone,
    required this.businessNameRegistered,
    required this.businessLogo,
  });

  factory Provider.fromJson(Map<String, dynamic> json) {
    return Provider(
      id: json['_id'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      businessNameRegistered: json['businessNameRegistered'] ?? '',
      businessLogo: BusinessLogo.fromJson(json['businessLogo'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'email': email,
      'phone': phone,
      'businessNameRegistered': businessNameRegistered,
      'businessLogo': businessLogo.toJson(),
    };
  }
}

class BusinessLogo {
  final String url;
  final String publicId;

  BusinessLogo({
    required this.url,
    required this.publicId,
  });

  factory BusinessLogo.fromJson(Map<String, dynamic> json) {
    return BusinessLogo(
      url: json['url'] ?? '',
      publicId: json['publicId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'publicId': publicId,
    };
  }
}

class PaymentDetails {
  final String paymentMethod;
  final String? stripeCustomerId;
  final DateTime? paidAt;
  final String? transactionId;

  PaymentDetails({
    required this.paymentMethod,
    this.stripeCustomerId,
    this.paidAt,
    this.transactionId,
  });

  factory PaymentDetails.fromJson(Map<String, dynamic> json) {
    return PaymentDetails(
      paymentMethod: json['paymentMethod'] ?? 'card',
      stripeCustomerId: json['stripeCustomerId'],
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
      transactionId: json['transactionId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paymentMethod': paymentMethod,
      'stripeCustomerId': stripeCustomerId,
      'paidAt': paidAt?.toIso8601String(),
      'transactionId': transactionId,
    };
  }
}

class Commission {
  final double amount;
  final double providerAmount;

  Commission({
    required this.amount,
    required this.providerAmount,
  });

  factory Commission.fromJson(Map<String, dynamic> json) {
    return Commission(
      amount: (json['amount'] ?? 0).toDouble(),
      providerAmount: (json['providerAmount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'providerAmount': providerAmount,
    };
  }
}

class Bundle {
  final String id;
  final String title;
  final String category;
  final double finalPrice;

  Bundle({
    required this.id,
    required this.title,
    required this.category,
    required this.finalPrice,
  });

  factory Bundle.fromJson(Map<String, dynamic> json) {
    return Bundle(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      finalPrice: (json['finalPrice'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'category': category,
      'finalPrice': finalPrice,
    };
  }
}

class ServiceRequestRef {
  final String id;
  final String serviceType;
  final DateTime scheduledDate;

  ServiceRequestRef({
    required this.id,
    required this.serviceType,
    required this.scheduledDate,
  });

  factory ServiceRequestRef.fromJson(Map<String, dynamic> json) {
    return ServiceRequestRef(
      id: json['_id'] ?? '',
      serviceType: json['serviceType'] ?? '',
      scheduledDate: DateTime.parse(json['scheduledDate'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'serviceType': serviceType,
      'scheduledDate': scheduledDate.toIso8601String(),
    };
  }
}

class StatusHistory {
  final String id;
  final String status;
  final DateTime timestamp;
  final String note;
  final String changedBy;
  final String changedByRole;

  StatusHistory({
    required this.id,
    required this.status,
    required this.timestamp,
    required this.note,
    required this.changedBy,
    required this.changedByRole,
  });

  factory StatusHistory.fromJson(Map<String, dynamic> json) {
    return StatusHistory(
      id: json['_id'] ?? '',
      status: json['status'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      note: json['note'] ?? '',
      changedBy: json['changedBy'] ?? '',
      changedByRole: json['changedByRole'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
      'note': note,
      'changedBy': changedBy,
      'changedByRole': changedByRole,
    };
  }
}