// lib/controllers/payment_controller.dart
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../views/screen/Users/Request/payment_service.dart';


class PaymentController extends GetxController {
  static PaymentController get to => Get.find<PaymentController>();

  final PaymentService _paymentService = PaymentService();

  // Observables
  final RxBool _hasMoneyRequest = false.obs;
  final RxBool _isCheckingMoneyRequest = true.obs;
  final RxBool _isLoadingMoneyDetails = false.obs;
  final Rx<Map<String, dynamic>?> _moneyRequestDetails = Rx<Map<String, dynamic>?>(null);
  final RxBool _isCompletingRequest = false.obs;
  final RxBool _isCreatingMoneyRequest = false.obs;

  // Getters
  bool get hasMoneyRequest => _hasMoneyRequest.value;
  bool get isCheckingMoneyRequest => _isCheckingMoneyRequest.value;
  bool get isLoadingMoneyDetails => _isLoadingMoneyDetails.value;
  Map<String, dynamic>? get moneyRequestDetails => _moneyRequestDetails.value;
  bool get isCompletingRequest => _isCompletingRequest.value;
  bool get isCreatingMoneyRequest => _isCreatingMoneyRequest.value;

  // Methods
  Future<void> checkMoneyRequests({
    String? userRole,
    String? bundleId,
    String? requestId,
    String? customerId,
  }) async {
    try {
      _isCheckingMoneyRequest.value = true;
      _hasMoneyRequest.value = false;

      if (kDebugMode) {
        print('💰 Checking for existing money requests...');
      }

      bool hasRequest = false;
      final isProvider = userRole?.toLowerCase() == 'provider';
      final isCustomer = userRole?.toLowerCase() == 'customer';

      if (isProvider) {
        if (bundleId != null && customerId != null) {
          final requests = await _paymentService.checkMoneyRequestByBundleIdForProvider(
            bundleId: bundleId,
            customerId: customerId,
          );
          hasRequest = requests.isNotEmpty;
        } else if (requestId != null) {
          final requests = await _paymentService.checkMoneyRequestByServiceRequestId(
            serviceRequestId: requestId,
          );
          hasRequest = requests.isNotEmpty;
        }
      } else if (isCustomer) {
        if (bundleId != null && customerId != null) {
          final requests = await _paymentService.checkMoneyRequestByBundleId(
            bundleId: bundleId,
            customerId: customerId,
          );
          hasRequest = requests.isNotEmpty;
        } else if (requestId != null) {
          final requests = await _paymentService.checkMoneyRequestByServiceRequestIdForCustomer(
            serviceRequestId: requestId,
          );
          if (!hasRequest) {
            final requests2 = await _paymentService.checkMoneyRequestByRequestId(
              requestId: requestId,
            );
            hasRequest = requests2.isNotEmpty;
          }
        }
      }

      _hasMoneyRequest.value = hasRequest;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking money requests: $e');
      }
      _hasMoneyRequest.value = false;
    } finally {
      _isCheckingMoneyRequest.value = false;
    }
  }

  Future<void> loadMoneyRequestDetails({
    required String serviceRequestId,
  }) async {
    try {
      _isLoadingMoneyDetails.value = true;
      final details = await _paymentService.loadMoneyRequestDetails(
        serviceRequestId: serviceRequestId,
      );
      _moneyRequestDetails.value = details;
      _hasMoneyRequest.value = details != null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading money request details: $e');
      }
      _moneyRequestDetails.value = null;
      _hasMoneyRequest.value = false;
    } finally {
      _isLoadingMoneyDetails.value = false;
    }
  }

  Future<void> createMoneyRequest({
    required double amount,
    String? bundleId,
    String? serviceRequestId,
  }) async {
    try {
      _isCreatingMoneyRequest.value = true;

      final result = await _paymentService.createMoneyRequest(
        amount: amount,
        bundleId: bundleId,
        serviceRequestId: serviceRequestId,
      );

      if (result['success'] == true) {
        // Refresh the money request details
        if (serviceRequestId != null) {
          await loadMoneyRequestDetails(serviceRequestId: serviceRequestId);
        }
      } else {
        throw Exception(result['message'] ?? 'Failed to create money request');
      }
    } catch (e) {
      rethrow;
    } finally {
      _isCreatingMoneyRequest.value = false;
    }
  }

  Future<void> cancelServiceRequest({
    required String requestId,
  }) async {
    try {
      _isCompletingRequest.value = true;
      await _paymentService.cancelServiceRequest(requestId: requestId);
    } catch (e) {
      rethrow;
    } finally {
      _isCompletingRequest.value = false;
    }
  }

  Future<void> cancelBundle({
    required String bundleId,
  }) async {
    try {
      _isCompletingRequest.value = true;
      await _paymentService.cancelBundle(bundleId: bundleId);
    } catch (e) {
      rethrow;
    } finally {
      _isCompletingRequest.value = false;
    }
  }

  Future<void> completeServiceRequest({
    required String requestId,
  }) async {
    try {
      _isCompletingRequest.value = true;
      await _paymentService.completeServiceRequest(requestId: requestId);
    } catch (e) {
      rethrow;
    } finally {
      _isCompletingRequest.value = false;
    }
  }

  Future<void> completeBundle({
    required String bundleId,
  }) async {
    try {
      _isCompletingRequest.value = true;
      await _paymentService.completeBundle(bundleId: bundleId);
    } catch (e) {
      rethrow;
    } finally {
      _isCompletingRequest.value = false;
    }
  }

  // Clear all states
  void clear() {
    _hasMoneyRequest.value = false;
    _isCheckingMoneyRequest.value = true;
    _isLoadingMoneyDetails.value = false;
    _moneyRequestDetails.value = null;
    _isCompletingRequest.value = false;
    _isCreatingMoneyRequest.value = false;
  }
}