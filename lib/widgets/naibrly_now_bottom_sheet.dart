import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naibrly/utils/app_colors.dart';
import 'package:naibrly/views/base/AppText/appText.dart';
import 'package:naibrly/views/base/pickers/custom_date_picker.dart';
import 'package:naibrly/widgets/payment_confirmation_bottom_sheet.dart';
import 'package:naibrly/services/api_service.dart';

class NaibrlyNowController extends GetxController {
  final MainApiService _apiService = Get.find<MainApiService>();

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  Future<bool> createServiceRequest({
    required String providerId,
    required String serviceType,
    required String problem,
    String? note,
    required DateTime scheduledDate,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final requestData = {
        'providerId': providerId,
        'serviceType': serviceType,
        'problem': problem,
        'note': note,
        'scheduledDate': scheduledDate.toIso8601String().split('T')[0], // Format: YYYY-MM-DD
      };

      print('📤 Creating service request with data: $requestData');

      final response = await _apiService.post(
        'service-requests',
        requestData,
      );

      print('📥 API Response: $response');

      if (response['success'] == true) {
        isLoading.value = false;
        return true;
      } else {
        errorMessage.value = response['message'] ?? 'Failed to create request';
        isLoading.value = false;
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Error creating request: $e';
      isLoading.value = false;
      print('❌ Error creating service request: $e');
      return false;
    }
  }
}

// Global helper to show the reusable "Naibrly Now" request bottom sheet
void showNaibrlyNowBottomSheet(
    BuildContext context, {
      required String serviceName,
      required String providerName,
      required String providerId,
    }) {
  final TextEditingController problemController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  final NaibrlyNowController controller = Get.put(NaibrlyNowController());
  DateTime? selectedDate;

  showCustomBottomSheet(
    context: context,
    topIcon: Image.asset(
      "assets/images/roundCross.png",
      width: 48,
      height: 48,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(
          Icons.add,
          color: Color(0xFF0E7A60),
          size: 48,
        );
      },
    ),
    title: "",
    description: "",
    primaryButtonText: "Request Sent",
    showSecondaryButton: false,
    showRating: false,
    showFeedback: false,
    primaryButtonColor: const Color(0xFF0E7A60),
    containerHeight: 600,
    customContent: StatefulBuilder(
      builder: (context, setState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Info Header
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppText(
                    'Service Request',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.Black,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.build, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppText(
                          'Service: $serviceName',
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.business, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppText(
                          'Provider: $providerName',
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Problem Field
            const AppText(
              'Problem*',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.Black,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: problemController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Describe your problem...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF0E7A60), width: 1),
                ),
                contentPadding: const EdgeInsets.all(12),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // Note Field
            const AppText(
              'Note',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.Black,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Additional notes...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF0E7A60), width: 1),
                ),
                contentPadding: const EdgeInsets.all(12),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // Date Field
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppText(
                  'Date*',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.Black,
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );

                    if (pickedDate != null) {
                      selectedDate = pickedDate;
                      setState(() {});
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        AppText(
                          selectedDate != null
                              ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                              : 'Select Date',
                          fontSize: 14,
                          color: selectedDate != null ? AppColors.Black : Colors.grey,
                        ),
                        const Spacer(),
                        if (selectedDate != null)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              selectedDate = null;
                              setState(() {});
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Loading indicator
            Obx(() {
              if (controller.isLoading.value) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return const SizedBox.shrink();
            }),

            // Error message
            Obx(() {
              if (controller.errorMessage.value.isNotEmpty) {
                return Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppText(
                          controller.errorMessage.value,
                          fontSize: 12,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        );
      },
    ),
    onPrimaryButtonTap: () async {
      // Validate inputs
      if (problemController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please describe your problem'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a date'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Submit request
      final success = await controller.createServiceRequest(
        providerId: providerId,
        serviceType: serviceName,
        problem: problemController.text.trim(),
        note: noteController.text.trim().isNotEmpty ? noteController.text.trim() : null,
        scheduledDate: selectedDate!,
      );

      if (success) {
        Navigator.of(context).pop();
        showRequestSuccessBottomSheet(context);
      } else {
        // Error is already shown via controller.errorMessage
        return;
      }
    },
  );
}