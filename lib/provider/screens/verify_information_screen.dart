import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:naibrly/provider/screens/select_service_area_screen.dart';

import '../controllers/verify_information_controller.dart';
import '../widgets/button.dart';
import '../widgets/colors.dart';
import '../widgets/textfield.dart';
import '../widgets/upload_card.dart';
import '../widgets/custom_single_select_dropdown.dart';

class VerifyInformationScreen extends StatefulWidget {
  const VerifyInformationScreen({super.key});

  @override
  State<VerifyInformationScreen> createState() => _VerifyInformationScreenState();
}

class _VerifyInformationScreenState extends State<VerifyInformationScreen> {
  final VerifyInformationController controller = Get.find<VerifyInformationController>();
  final ImagePicker _imagePicker = ImagePicker();

  final TextEditingController einController = TextEditingController();
  final TextEditingController ownerFirstNameController = TextEditingController();
  final TextEditingController ownerLastNameController = TextEditingController();

  bool isDifferentOwner = false;
  final List<String> countryOptions = ["USA"];
  String? selectedCountry;

  Future<void> _pickImage(ImageType imageType) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        switch (imageType) {
          case ImageType.insurance:
            controller.setInsuranceDocument(image.path);
            break;
          case ImageType.idFront:
            controller.setIdCardFront(image.path);
            break;
          case ImageType.idBack:
            controller.setIdCardBack(image.path);
            break;
        }

        Get.snackbar(
          'Success',
          'File selected successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick image: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    controller.clearData();
    selectedCountry = "USA";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KoreColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Verify Your Information",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 2),
            Text(
              "We need to verify your business details.",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Obx(() => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // EIN Number
            KoreTextField(
              label: "EIN Number",
              hint: "Enter your 9-digit EIN (e.g., 12-3456789)",
              controller: einController,
            ),
            const SizedBox(height: 8),
            const Text(
              "An Employer Identification Number (EIN) is a federal tax ID for businesses",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 20),

            // Business Registered Country
            const Text(
              "Business is registered in",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            CustomSingleSelectDropdown(
              hint: "Select country",
              items: countryOptions,
              selectedItem: selectedCountry,
              onChanged: (value) {
                setState(() {
                  selectedCountry = value;
                });
              },
            ),
            const SizedBox(height: 20),

            // Upload Insurance Document
            const Text(
              "Upload proof of insurance coverage",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Obx(() => KoreUploadCard(
              label: "Upload proof of insurance coverage",
              hint: controller.insuranceDocumentPath.value.isNotEmpty
                  ? "Insurance document selected"
                  : "Acceptable formats: JPG, PNG, PDF (Max 10MB)",
              icon: Icons.cloud_upload_outlined,
              onTap: () => _pickImage(ImageType.insurance),
            )),

            // Insurance Preview
            Obx(() => controller.insuranceDocumentPath.value.isNotEmpty
                ? _buildImagePreview(
              controller.insuranceDocumentPath.value,
              "Insurance Document",
                  () => _pickImage(ImageType.insurance),
            )
                : const SizedBox()),
            const SizedBox(height: 20),

            // Different Owner Checkbox
            Row(
              children: [
                Checkbox(
                  value: isDifferentOwner,
                  onChanged: (val) {
                    setState(() {
                      isDifferentOwner = val ?? false;
                      if (!isDifferentOwner) {
                        ownerFirstNameController.clear();
                        ownerLastNameController.clear();
                        controller.setIdCardFront('');
                        controller.setIdCardBack('');
                      }
                    });
                  },
                  activeColor: KoreColors.primary,
                ),
                const Expanded(
                  child: Text(
                    "Information of the Registered Owner/Operator is different than you",
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),

            // Owner Information Section
            if (isDifferentOwner) ...[
              const SizedBox(height: 10),
              KoreTextField(
                label: "Owner Operator: First Name",
                hint: "Enter first name",
                controller: ownerFirstNameController,
              ),
              const SizedBox(height: 12),
              KoreTextField(
                label: "Owner Operator: Last Name",
                hint: "Enter last name",
                controller: ownerLastNameController,
              ),
              const SizedBox(height: 20),

              const Text(
                "Owner Operator ID Check",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 12),

              // ID Front
              const Text(
                "Front of ID Card",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              Obx(() => KoreUploadCard(
                label: "Upload ID Card Front",
                hint: controller.idCardFrontPath.value.isNotEmpty
                    ? "Front ID selected"
                    : "JPG, PNG (Max 10MB)",
                icon: Icons.credit_card,
                onTap: () => _pickImage(ImageType.idFront),
              )),

              Obx(() => controller.idCardFrontPath.value.isNotEmpty
                  ? _buildImagePreview(
                controller.idCardFrontPath.value,
                "ID Front",
                    () => _pickImage(ImageType.idFront),
              )
                  : const SizedBox()),

              const SizedBox(height: 16),

              // ID Back
              const Text(
                "Back of ID Card",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              Obx(() => KoreUploadCard(
                label: "Upload ID Card Back",
                hint: controller.idCardBackPath.value.isNotEmpty
                    ? "Back ID selected"
                    : "JPG, PNG (Max 10MB)",
                icon: Icons.credit_card,
                onTap: () => _pickImage(ImageType.idBack),
              )),

              Obx(() => controller.idCardBackPath.value.isNotEmpty
                  ? _buildImagePreview(
                controller.idCardBackPath.value,
                "ID Back",
                    () => _pickImage(ImageType.idBack),
              )
                  : const SizedBox()),
            ],

            // Error Message
            if (controller.errorMessage.value.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        controller.errorMessage.value,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 40),

            // Submit Button
            KoreButton(
              text: controller.isLoading.value ? "Verifying..." : "Next",
              onPressed: controller.isLoading.value ? null : _handleSubmit,
            ),
            const SizedBox(height: 20),
          ],
        ),
      )),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_validateForm()) {
      return;
    }

    await controller.verifyInformation(
      einNumber: einController.text.trim(),
      firstName: isDifferentOwner
          ? ownerFirstNameController.text.trim()
          : "Same as provider",
      lastName: isDifferentOwner
          ? ownerLastNameController.text.trim()
          : "Same as provider",
      businessRegisteredCountry: selectedCountry ?? 'USA',

    );

    if (controller.verificationSuccess.value) {
      Get.off(() => const SelectServiceAreaScreen());
    }
  }

  Widget _buildImagePreview(String imagePath, String label, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          "$label Preview:",
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            height: 195,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                File(imagePath),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Colors.grey[400], size: 40),
                        const SizedBox(height: 8),
                        Text(
                          'Unable to load image',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Change Image', style: TextStyle(fontSize: 12)),
          ),
        ),
      ],
    );
  }

  bool _validateForm() {
    // Clear previous error
    controller.errorMessage.value = '';

    // Validate EIN
    if (einController.text.isEmpty) {
      controller.errorMessage.value = 'Please enter EIN number';
      return false;
    }

    if (!RegExp(r'^\d{2}-?\d{7}$').hasMatch(einController.text.trim())) {
      controller.errorMessage.value = 'Please enter a valid EIN (e.g., 12-3456789 or 123456789)';
      return false;
    }

    // Validate Country
    if (selectedCountry == null || selectedCountry!.isEmpty) {
      controller.errorMessage.value = 'Please select business registration country';
      return false;
    }

    // Validate Insurance Document
    if (controller.insuranceDocumentPath.value.isEmpty) {
      controller.errorMessage.value = 'Please upload proof of insurance';
      return false;
    }

    // Validate Different Owner Section
    if (isDifferentOwner) {
      if (ownerFirstNameController.text.trim().isEmpty) {
        controller.errorMessage.value = 'Please enter owner first name';
        return false;
      }
      if (ownerLastNameController.text.trim().isEmpty) {
        controller.errorMessage.value = 'Please enter owner last name';
        return false;
      }
      if (controller.idCardFrontPath.value.isEmpty) {
        controller.errorMessage.value = 'Please upload ID card front';
        return false;
      }
      if (controller.idCardBackPath.value.isEmpty) {
        controller.errorMessage.value = 'Please upload ID card back';
        return false;
      }
    }

    return true;
  }

  @override
  void dispose() {
    einController.dispose();
    ownerFirstNameController.dispose();
    ownerLastNameController.dispose();
    super.dispose();
  }
}

enum ImageType { insurance, idFront, idBack }