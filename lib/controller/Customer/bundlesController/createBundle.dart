import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naibrly/models/bundle_model.dart';


import '../../../provider/services/api_service.dart';
import '../../../services/api_service.dart';

class CreateBundleController extends GetxController {
  final MainApiService _apiService = Get.find<MainApiService>();

  final RxList<Bundle> bundles = <Bundle>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxString loadingBundleId = ''.obs;

  Future<void> getNaibrlyBundle(BuildContext context) async {
    try {
      isLoading.value = true;
      error.value = '';

      final response = await _apiService.get('bundles/customer/nearby');
      print('Bundle API Response: ${response['success']}');
      print('Found ${response['data']?['bundles']?.length ?? 0} bundles');

      if (response['success'] == true) {
        final List<dynamic> bundlesData = response['data']['bundles'] ?? [];
        print('Processing ${bundlesData.length} bundles');

        final List<Bundle> parsedBundles = [];

        for (var bundleData in bundlesData) {
          try {
            final bundle = Bundle.fromJson(bundleData);
            parsedBundles.add(bundle);
            print('✅ Parsed bundle: ${bundle.id} - ${bundle.title}');
          } catch (e) {
            print('❌ Error parsing bundle: $e');
            print('Problematic bundle data: $bundleData');
          }
        }

        bundles.assignAll(parsedBundles);
        print('🎉 Successfully loaded ${bundles.length} bundles');
      } else {
        error.value = response['message'] ?? 'Failed to fetch bundles';
        print('Bundle API Error: ${error.value}');
      }
    } catch (e) {
      error.value = 'Error fetching bundles: $e';
      print('Bundle Controller Exception: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> joinNaibrlyBundle(BuildContext context, String bundleId) async {
    try {
      loadingBundleId.value = bundleId;

      final response = await _apiService.post(
        'bundles/$bundleId/join',
        {},
      );

      if (response['success'] == true) {
        // Refresh the bundles list
        await getNaibrlyBundle(context);

        Get.snackbar(
          'Success',
          'Successfully joined bundle!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          response['message'] ?? 'Failed to join bundle',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to join bundle: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      loadingBundleId.value = '';
    }
  }

  Future<void> createBundle(Map<String, dynamic> bundleData) async {
    try {
      isLoading.value = true;
      error.value = '';

      final response = await _apiService.post('bundles', bundleData);

      if (response['success'] == true) {
        // Refresh bundles list
        await getNaibrlyBundle(Get.context!);

        Get.snackbar(
          'Success',
          'Bundle created successfully!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        error.value = response['message'] ?? 'Failed to create bundle';
        Get.snackbar(
          'Error',
          error.value,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      error.value = 'Error creating bundle: $e';
      Get.snackbar(
        'Error',
        error.value,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshBundles() async {
    await getNaibrlyBundle(Get.context!);
  }
}