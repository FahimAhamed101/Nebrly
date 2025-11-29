import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naibrly/models/service_request_model.dart';
import 'package:naibrly/services/api_service.dart';

class ServiceRequestController extends GetxController {
  final MainApiService _apiService = Get.find<MainApiService>();

  final RxList<ServiceRequest> serviceRequests = <ServiceRequest>[].obs;
  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;

  @override
  void onInit() {
    super.onInit();
    fetchServiceRequests();
  }

  /// Fetch all service requests for the provider
  Future<void> fetchServiceRequests({int page = 1}) async {
    try {
      isLoading.value = true;
      error.value = '';

      final response = await _apiService.get(
        'service-requests/customer/my-requests',
        queryParams: {'page': page.toString()},
      );

      if (response['success'] == true) {
        final List<dynamic> requestsData = response['data']['serviceRequests'] ?? [];

        if (page == 1) {
          // Replace list if first page
          serviceRequests.assignAll(
            requestsData.map((data) => ServiceRequest.fromJson(data)).toList(),
          );
        } else {
          // Add to list if loading more pages
          serviceRequests.addAll(
            requestsData.map((data) => ServiceRequest.fromJson(data)).toList(),
          );
        }

        // Update pagination info
        final pagination = response['data']['pagination'];
        if (pagination != null) {
          currentPage.value = pagination['current'] ?? 1;
          totalPages.value = pagination['pages'] ?? 1;
        }
      } else {
        error.value = response['message'] ?? 'Failed to load service requests';
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
      error.value = 'Error loading service requests: $e';
      Get.snackbar(
        'Error',
        'Failed to load service requests',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh the service requests list
  Future<void> refreshServiceRequests() async {
    await fetchServiceRequests(page: 1);
  }

  /// Get pending service requests
  List<ServiceRequest> get pendingRequests {
    return serviceRequests
        .where((request) => request.status == 'pending')
        .toList();
  }

  /// Get accepted service requests
  List<ServiceRequest> get acceptedRequests {
    return serviceRequests
        .where((request) => request.status == 'accepted')
        .toList();
  }

  /// Get completed service requests
  List<ServiceRequest> get completedRequests {
    return serviceRequests
        .where((request) => request.status == 'completed')
        .toList();
  }

  /// Get cancelled service requests
  List<ServiceRequest> get cancelledRequests {
    return serviceRequests
        .where((request) => request.status == 'cancelled')
        .toList();
  }

  /// Accept a service request
  Future<void> acceptServiceRequest(String requestId) async {
    try {
      // Show loading indicator
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final response = await _apiService.post(
        'service-requests/$requestId/accept',
        {},
      );

      // Close loading dialog
      Get.back();

      if (response['success'] == true) {
        // Update the local state
        final index = serviceRequests.indexWhere((req) => req.id == requestId);
        if (index != -1) {
          serviceRequests[index] = ServiceRequest.fromJson(response['data']);
        }

        Get.snackbar(
          'Success',
          'Service request accepted!',
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade900,
          icon: const Icon(Icons.check_circle, color: Colors.green),
        );
      } else {
        Get.snackbar(
          'Error',
          response['message'] ?? 'Failed to accept service request',
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
        'Failed to accept service request',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        icon: const Icon(Icons.error, color: Colors.red),
      );
    }
  }

  /// Cancel/Decline a service request
  Future<void> cancelServiceRequest(String requestId) async {
    try {
      // Show confirmation dialog
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Decline Request'),
          content: const Text('Are you sure you want to decline this service request?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Yes, Decline'),
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
        'service-requests/$requestId/cancel',
        {},
      );

      // Close loading dialog
      Get.back();

      if (response['success'] == true) {
        // Remove from local list or update status
        serviceRequests.removeWhere((req) => req.id == requestId);

        Get.snackbar(
          'Declined',
          'Service request declined',
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade900,
          icon: const Icon(Icons.info, color: Colors.orange),
        );
      } else {
        Get.snackbar(
          'Error',
          response['message'] ?? 'Failed to decline service request',
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
        'Failed to decline service request',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        icon: const Icon(Icons.error, color: Colors.red),
      );
    }
  }

  /// Complete a service request
  Future<void> completeServiceRequest(String requestId) async {
    try {
      // Show loading indicator
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final response = await _apiService.post(
        'service-requests/$requestId/complete',
        {},
      );

      // Close loading dialog
      Get.back();

      if (response['success'] == true) {
        // Update the local state
        final index = serviceRequests.indexWhere((req) => req.id == requestId);
        if (index != -1) {
          serviceRequests[index] = ServiceRequest.fromJson(response['data']);
        }

        Get.snackbar(
          'Success',
          'Service marked as completed!',
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade900,
          icon: const Icon(Icons.check_circle, color: Colors.green),
        );
      } else {
        Get.snackbar(
          'Error',
          response['message'] ?? 'Failed to complete service request',
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
        'Failed to complete service request',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        icon: const Icon(Icons.error, color: Colors.red),
      );
    }
  }

  /// Get service request by ID
  ServiceRequest? getRequestById(String requestId) {
    try {
      return serviceRequests.firstWhere((req) => req.id == requestId);
    } catch (e) {
      return null;
    }
  }
}