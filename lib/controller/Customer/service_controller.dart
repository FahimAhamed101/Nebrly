// controllers/service_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:naibrly/services/api_service.dart';

import '../../models/service_model.dart';

class ServiceController extends GetxController {
  final MainApiService _apiService = Get.find<MainApiService>();

  final RxList<Service> services = <Service>[].obs;
  final RxList<Service> popularServices = <Service>[].obs;
  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAllServices();
  }

  /// Fetch all services
  Future<void> fetchAllServices() async {
    try {
      isLoading.value = true;
      error.value = '';

      final response = await _apiService.get(
        'categories/services',
      );

      if (response['success'] == true) {
        final List<dynamic> servicesData = response['data']['services'] ?? [];

        services.assignAll(
          servicesData.map((data) => Service.fromJson(data)).toList(),
        );

        // You can also filter popular services if needed
        popularServices.assignAll(
          services.where((service) => service.isActive).toList(),
        );
      } else {
        error.value = response['message'] ?? 'Failed to load services';
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
      error.value = 'Error loading services: $e';
      Get.snackbar(
        'Error',
        'Failed to load services',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh services
  Future<void> refreshServices() async {
    await fetchAllServices();
  }

  /// Get service by ID
  Service? getServiceById(String serviceId) {
    try {
      return services.firstWhere((service) => service.id == serviceId);
    } catch (e) {
      return null;
    }
  }

  /// Get services by category
  List<Service> getServicesByCategory(String categoryId) {
    return services.where((service) => service.category?['_id'] == categoryId).toList();
  }

  /// Get services by category type
  List<Service> getServicesByCategoryType(String categoryTypeId) {
    return services.where((service) => service.categoryType?['_id'] == categoryTypeId).toList();
  }
}