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
      print("🚀 Joining bundle with ID: $bundleId");

      final response = await _apiService.post(
        'bundles/$bundleId/join',
        {},
      );

      print("📥 Join bundle response: ${response.toString()}");

      if (response['success'] == true) {
        print("✅ Successfully joined bundle: $bundleId");

        // Refresh the bundles list to get updated participant count
        await getNaibrlyBundle(context);

        // Use ScaffoldMessenger instead of Get.snackbar
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully joined bundle!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.all(16),
            ),
          );
        }
      } else {
        print("❌ Failed to join bundle: ${response['message']}");

        // Check if user is already part of the bundle
        final message = response['message'] ?? 'Failed to join bundle';
        final isAlreadyMember = message.toLowerCase().contains('already part');

        // Use ScaffoldMessenger instead of Get.snackbar
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isAlreadyMember ? 'You are already part of this bundle!' : message),
              backgroundColor: isAlreadyMember ? Colors.orange : Colors.red,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    } catch (e) {
      print("💥 Exception joining bundle: $e");

      // Use ScaffoldMessenger instead of Get.snackbar
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceFirst('ApiException: ', '')}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      loadingBundleId.value = '';
    }
  }

  Future<bool> createBundle(Map<String, dynamic> bundleData, BuildContext context) async {
    try {
      isLoading.value = true;
      error.value = '';

      print("📤 Sending create bundle request...");
      final response = await _apiService.post('bundles/create', bundleData);
      print("📥 Create bundle response: ${response.toString()}");

      if (response['success'] == true) {
        // Refresh bundles list
        await getNaibrlyBundle(context);

        // Use ScaffoldMessenger with context
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bundle created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }

        return true; // Success
      } else {
        error.value = response['message'] ?? 'Failed to create bundle';

        // Use ScaffoldMessenger with context
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.value),
              backgroundColor: Colors.red,
            ),
          );
        }

        return false; // Failed
      }
    } catch (e) {
      error.value = 'Error creating bundle: $e';
      print("❌ Create bundle error: $e");

      // Use ScaffoldMessenger with context
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.value),
            backgroundColor: Colors.red,
          ),
        );
      }

      return false; // Failed
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshBundles() async {
    // You need to pass context or use Get.context
    final context = Get.context;
    if (context != null) {
      await getNaibrlyBundle(context);
    }
  }
}