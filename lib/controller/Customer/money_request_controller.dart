import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naibrly/models/money_request_model.dart';
import 'package:naibrly/services/api_service.dart';

class MoneyRequestController extends GetxController {
  final MainApiService _apiService = Get.find<MainApiService>();

  final RxList<MoneyRequest> moneyRequests = <MoneyRequest>[].obs;
  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;

  @override
  void onInit() {
    super.onInit();
    fetchMoneyRequests();
  }

  /// Fetch all money requests for the customer
  Future<void> fetchMoneyRequests({int page = 1}) async {
    try {
      isLoading.value = true;
      error.value = '';

      final response = await _apiService.get(
        'money-requests/customer',
        queryParams: {'page': page.toString()},
      );

      if (response['success'] == true) {
        final List<dynamic> requestsData = response['data']['moneyRequests'] ?? [];

        if (page == 1) {
          // Replace list if first page
          moneyRequests.assignAll(
            requestsData.map((data) => MoneyRequest.fromJson(data)).toList(),
          );
        } else {
          // Add to list if loading more pages
          moneyRequests.addAll(
            requestsData.map((data) => MoneyRequest.fromJson(data)).toList(),
          );
        }

        // Update pagination info
        final pagination = response['data']['pagination'];
        if (pagination != null) {
          currentPage.value = pagination['current'] ?? 1;
          totalPages.value = pagination['pages'] ?? 1;
        }
      } else {
        error.value = response['message'] ?? 'Failed to load money requests';
        Get.snackbar(
          'Error',
          error.value,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900,
        );
      }
    } on ApiException catch (e) {
      error.value = e.message;
      Get.snackbar(
        'Error',
        e.message,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
    } catch (e) {
      error.value = 'Error loading money requests: $e';
      Get.snackbar(
        'Error',
        'Failed to load money requests',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh the money requests list
  Future<void> refreshMoneyRequests() async {
    await fetchMoneyRequests(page: 1);
  }

  /// Get pending money requests
  List<MoneyRequest> get pendingRequests {
    return moneyRequests
        .where((request) => request.status == 'pending')
        .toList();
  }

  /// Get accepted money requests
  List<MoneyRequest> get acceptedRequests {
    return moneyRequests
        .where((request) => request.status == 'accepted')
        .toList();
  }

  /// Get paid money requests
  List<MoneyRequest> get paidRequests {
    return moneyRequests
        .where((request) => request.status == 'paid')
        .toList();
  }

  /// Get cancelled money requests
  List<MoneyRequest> get cancelledRequests {
    return moneyRequests
        .where((request) => request.status == 'cancelled')
        .toList();
  }

  /// Accept a money request and pay
  Future<void> acceptAndPayMoneyRequest(String requestId) async {
    try {
      // Show loading indicator
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final response = await _apiService.post(
        'money-requests/$requestId/accept',
        {},
      );

      // Close loading dialog
      Get.back();

      if (response['success'] == true) {
        // Update the local state
        final index = moneyRequests.indexWhere((req) => req.id == requestId);
        if (index != -1) {
          moneyRequests[index] = MoneyRequest.fromJson(response['data']);
        }

        Get.snackbar(
          'Success',
          'Payment processed successfully!',
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade900,
          icon: const Icon(Icons.check_circle, color: Colors.green),
        );
      } else {
        Get.snackbar(
          'Error',
          response['message'] ?? 'Failed to process payment',
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900,
          icon: const Icon(Icons.error, color: Colors.red),
        );
      }
    } on ApiException catch (e) {
      Get.back(); // Close loading dialog
      Get.snackbar(
        'Error',
        e.message,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        icon: const Icon(Icons.error, color: Colors.red),
      );
    } catch (e) {
      Get.back(); // Close loading dialog
      Get.snackbar(
        'Error',
        'Failed to process payment',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        icon: const Icon(Icons.error, color: Colors.red),
      );
    }
  }

  /// Cancel/Decline a money request
  Future<void> cancelMoneyRequest(String requestId) async {
    try {
      // Show confirmation dialog
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Cancel Request'),
          content: const Text('Are you sure you want to cancel this payment request?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Yes, Cancel'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Show loading indicator
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final response = await _apiService.post(
        'money-requests/$requestId/cancel',
        {},
      );

      // Close loading dialog
      Get.back();

      if (response['success'] == true) {
        // Remove from local list or update status
        moneyRequests.removeWhere((req) => req.id == requestId);

        Get.snackbar(
          'Cancelled',
          'Payment request cancelled',
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade900,
          icon: const Icon(Icons.info, color: Colors.orange),
        );
      } else {
        Get.snackbar(
          'Error',
          response['message'] ?? 'Failed to cancel payment request',
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900,
          icon: const Icon(Icons.error, color: Colors.red),
        );
      }
    } on ApiException catch (e) {
      Get.back(); // Close loading dialog
      Get.snackbar(
        'Error',
        e.message,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        icon: const Icon(Icons.error, color: Colors.red),
      );
    } catch (e) {
      Get.back(); // Close loading dialog
      Get.snackbar(
        'Error',
        'Failed to cancel payment request',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        icon: const Icon(Icons.error, color: Colors.red),
      );
    }
  }

  /// Get money request by ID
  MoneyRequest? getRequestById(String requestId) {
    try {
      return moneyRequests.firstWhere((req) => req.id == requestId);
    } catch (e) {
      return null;
    }
  }
}