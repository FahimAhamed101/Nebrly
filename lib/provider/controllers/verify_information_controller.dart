// verify_information_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/api_service.dart';
import '../models/provider_model.dart';

class VerifyInformationController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  var isLoading = false.obs;
  var errorMessage = ''.obs;
  var verificationSuccess = false.obs;

  // File paths
  var insuranceDocumentPath = ''.obs;
  var idCardFrontPath = ''.obs;
  var idCardBackPath = ''.obs;

  // Set file paths
  void setInsuranceDocument(String path) => insuranceDocumentPath.value = path;
  void setIdCardFront(String path) => idCardFrontPath.value = path;
  void setIdCardBack(String path) => idCardBackPath.value = path;

  Future<void> verifyInformation({
    required String einNumber,
    required String firstName,
    required String lastName,
    required String businessRegisteredState,
  }) async {
    try {
      isLoading(true);
      errorMessage('');

      // Validate required fields
      if (einNumber.isEmpty ||
          firstName.isEmpty ||
          lastName.isEmpty ||
          businessRegisteredState.isEmpty ||
          insuranceDocumentPath.isEmpty ||
          idCardFrontPath.isEmpty ||
          idCardBackPath.isEmpty) {
        errorMessage('Please fill all required fields and upload all documents');
        isLoading(false);
        return;
      }

      final request = VerifyInformationRequest(
        einNumber: einNumber,
        firstName: firstName,
        lastName: lastName,
        businessRegisteredState: businessRegisteredState,
      );

      final response = await _apiService.verifyInformation(
        request,
        insuranceDocumentPath: insuranceDocumentPath.value,
        idCardFrontPath: idCardFrontPath.value,
        idCardBackPath: idCardBackPath.value,
      );

      if (response.success) {
        verificationSuccess(true);
        Get.snackbar(
          'Success',
          response.message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        errorMessage(response.message);
        Get.snackbar(
          'Error',
          response.message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      errorMessage('Verification failed: $e');
      Get.snackbar(
        'Error',
        'Verification failed: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading(false);
    }
  }

  void clearData() {
    insuranceDocumentPath('');
    idCardFrontPath('');
    idCardBackPath('');
    errorMessage('');
    verificationSuccess(false);
  }
}