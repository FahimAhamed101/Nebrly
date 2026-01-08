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
    required String businessRegisteredCountry, // Fixed: Changed from State to Country
  }) async {
    try {
      isLoading(true);
      errorMessage('');

      print('Starting verification with data:');
      print('EIN: $einNumber');
      print('First Name: $firstName');
      print('Last Name: $lastName');
      print('Country: $businessRegisteredCountry');
      print('Insurance Path: ${insuranceDocumentPath.value}');
      print('ID Front Path: ${idCardFrontPath.value}');
      print('ID Back Path: ${idCardBackPath.value}');

      // Validate required fields
      if (einNumber.isEmpty ||
          firstName.isEmpty ||
          lastName.isEmpty ||
          businessRegisteredCountry.isEmpty ||
          insuranceDocumentPath.value.isEmpty) {
        errorMessage('Please fill all required fields and upload insurance document');
        isLoading(false);
        return;
      }

      // For non-different owner, we might not need ID cards
      // Adjust this based on your API requirements
      if (idCardFrontPath.value.isEmpty || idCardBackPath.value.isEmpty) {
        // Check if this is acceptable for your API
        // If ID cards are always required, show error
        print('Warning: ID cards not uploaded');
      }

      final request = VerifyInformationRequest(
        einNumber: einNumber,
        firstName: firstName,
        lastName: lastName,
        businessRegisteredCountry: businessRegisteredCountry, // Fixed parameter
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
          duration: Duration(seconds: 3),
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