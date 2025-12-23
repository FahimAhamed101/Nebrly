import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/user_model_provider.dart' show UserModel;
import '../../controllers/updateprofile_controller.dart';
import '../../widgets/custom_single_select_dropdown.dart';

class UpdateInformationScreen extends StatefulWidget {
  const UpdateInformationScreen({super.key});

  @override
  State<UpdateInformationScreen> createState() => _UpdateInformationScreenState();
}

class _UpdateInformationScreenState extends State<UpdateInformationScreen> {
  final ProfileController _controller = Get.find<ProfileController>();

  final TextEditingController _businessNameRegisteredController = TextEditingController();
  final TextEditingController _businessNameDBAController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _locksmithRateController = TextEditingController();
  final TextEditingController _plumberRateController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedRole = "";
  String _selectedStartDay = "Mon";
  String _selectedEndDay = "Fri";
  String _selectedStartTime = "9:00 am";
  String _selectedEndTime = "5:00 pm";
  String _selectedCountryCode = "1+";

  List<String> _selectedServices = ["Plumbing", "Locksmith"];
  List<Map<String, dynamic>> _existingServices = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  void _loadUserData() {
    if (_controller.user.value != null) {
      final user = _controller.user.value!;
      _businessNameRegisteredController.text = user.businessNameRegistered ?? "";
      _businessNameDBAController.text = user.businessNameDBA ?? "";

      // Use fallback for address
      _addressController.text = _getUserAddress(user);

      _phoneController.text = user.phone ?? "";
      _websiteController.text = user.website ?? "";
      _descriptionController.text = user.description ?? "";

      // Set rates if they exist
      if (user.locksmithRate != null) {
        _locksmithRateController.text = "\$${user.locksmithRate!.toStringAsFixed(2)}";
      }
      if (user.plumberRate != null) {
        _plumberRateController.text = "\$${user.plumberRate!.toStringAsFixed(2)}";
      }

      // Load existing services
      if (user.selectedServices != null) {
        _selectedServices = List<String>.from(user.selectedServices!);
      }
    }
  }

  String _getUserAddress(UserModel user) {
    // Check different possible field names for address
    if (user.address != null && user.address!.isNotEmpty) {
      return user.address!;
    }
    return "123 Oak Street Springfield, IL 62704"; // Fallback
  }

  @override
  void dispose() {
    _businessNameRegisteredController.dispose();
    _businessNameDBAController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _locksmithRateController.dispose();
    _plumberRateController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    try {
      // Parse rates
      double locksmithRate = double.tryParse(
          _locksmithRateController.text.replaceAll('\$', '').trim()) ?? 0.0;
      double plumberRate = double.tryParse(
          _plumberRateController.text.replaceAll('\$', '').trim()) ?? 0.0;

      // Prepare services data - match the API format from your documentation
      List<Map<String, dynamic>> servicesToAdd = _selectedServices.map((service) {
        return {
          'name': service,
          'hourlyRate': service.toLowerCase().contains('locksmith')
              ? locksmithRate
              : plumberRate,
        };
      }).toList();

      final success = await _controller.updateProviderProfile(
        firstName: _businessNameRegisteredController.text.split(' ').first,
        lastName: _businessNameRegisteredController.text.split(' ').length > 1
            ? _businessNameRegisteredController.text.split(' ').last
            : '',
        phone: _phoneController.text,
        businessNameRegistered: _businessNameRegisteredController.text,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : "Professional service provider",
        experience: "5", // Default or from a field
        maxBundleCapacity: "10", // Default or from a field
        servicesToAdd: servicesToAdd,
      );

      if (success) {
        Get.back(); // Go back to previous screen
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update profile: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Rest of your widget code remains the same...
  // Keep all the _build methods exactly as you had them

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: Column(
          children: [
            const Text(
              "Update Your Information",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              "Keep Your Details Up to Date",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        if (_controller.isLoading.value && _controller.user.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUploadSection(),
              const SizedBox(height: 20),

              _buildTextField(
                label: "Business Name (AS REGISTERED)",
                controller: _businessNameRegisteredController,
                hintText: "Enter registered business name",
              ),
              const SizedBox(height: 16),

              _buildTextField(
                label: "Business Name (DBA)",
                controller: _businessNameDBAController,
                hintText: "Enter Doing Business As name",
              ),
              const SizedBox(height: 16),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Select your role",
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CustomSingleSelectDropdown(
                    hint: "Select your role",
                    items: const ["Owner", "Manager", "Employee"],
                    selectedItem: _selectedRole.isEmpty ? null : _selectedRole,
                    onChanged: (value) => setState(() => _selectedRole = value ?? ""),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildTextField(
                label: "Description",
                controller: _descriptionController,
                hintText: "Describe your business",
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                label: "Address",
                controller: _addressController,
                readOnly: true,
              ),
              const SizedBox(height: 16),

              _buildPhoneNumberFields(),
              const SizedBox(height: 16),

              _buildTextField(
                label: "Business Website",
                controller: _websiteController,
                hintText: "https://example.com",
              ),
              const SizedBox(height: 20),

              _buildServiceDaysSection(),
              const SizedBox(height: 16),

              _buildBusinessHoursSection(),
              const SizedBox(height: 20),

              _buildServicesSection(),
              const SizedBox(height: 16),

              // Service chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedServices.map((service) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8DC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFA500),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          service,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedServices.remove(service);
                            });
                          },
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Hourly Rate Cards
              _buildHourlyRateCard(
                icon: Icons.lock_outline,
                title: "Enter Your Hourly Rate as a Locksmith",
                subtitle: "Set how much you charge per hour",
                controller: _locksmithRateController,
              ),
              const SizedBox(height: 12),

              _buildHourlyRateCard(
                icon: Icons.plumbing_outlined,
                title: "Enter Your Hourly Rate as a Plumber",
                subtitle: "Set how much you charge per hour",
                controller: _plumberRateController,
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await _updateProfile();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0E7A60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  child: _controller.isLoading.value
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    "Update",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      }),
    );
  }

  // Add the missing _buildTextField method with maxLines parameter
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    bool readOnly = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 13,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          style: const TextStyle(fontSize: 14),
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF0E7A60), width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            filled: true,
            fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
          ),
        ),
      ],
    );
  }

  // Keep all other _build methods exactly as they were
  Widget _buildUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Upload Business Logo",
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 13,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            _controller.pickBusinessLogo();
          },
          child: Obx(() {
            return Container(
              width: double.infinity,
              height: 110,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1.5,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: _controller.businessLogo.value != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  _controller.businessLogo.value!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              )
                  : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.file_upload_outlined,
                    size: 36,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Upload Your Business Logo",
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Max 3 MB",
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  // ... Keep all other _build methods exactly as they were in your original code
  Widget _buildPhoneNumberFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Phone Number",
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 13,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                value: _selectedCountryCode,
                style: const TextStyle(fontSize: 14, color: Colors.black),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF0E7A60), width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: const [
                  DropdownMenuItem(value: "1+", child: Text("1+")),
                  DropdownMenuItem(value: "44+", child: Text("44+")),
                  DropdownMenuItem(value: "91+", child: Text("91+")),
                ],
                onChanged: (value) => setState(() => _selectedCountryCode = value ?? "1+"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 4,
              child: TextField(
                controller: _phoneController,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF0E7A60), width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildServiceDaysSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Business Service Days",
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 13,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedStartDay,
                style: const TextStyle(fontSize: 14, color: Colors.black),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF0E7A60), width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: const [
                  DropdownMenuItem(value: "Mon", child: Text("Mon")),
                  DropdownMenuItem(value: "Tue", child: Text("Tue")),
                  DropdownMenuItem(value: "Wed", child: Text("Wed")),
                  DropdownMenuItem(value: "Thu", child: Text("Thu")),
                  DropdownMenuItem(value: "Fri", child: Text("Fri")),
                  DropdownMenuItem(value: "Sat", child: Text("Sat")),
                  DropdownMenuItem(value: "Sun", child: Text("Sun")),
                ],
                onChanged: (value) => setState(() => _selectedStartDay = value ?? "Mon"),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                "to",
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedEndDay,
                style: const TextStyle(fontSize: 14, color: Colors.black),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF0E7A60), width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: const [
                  DropdownMenuItem(value: "Mon", child: Text("Mon")),
                  DropdownMenuItem(value: "Tue", child: Text("Tue")),
                  DropdownMenuItem(value: "Wed", child: Text("Wed")),
                  DropdownMenuItem(value: "Thu", child: Text("Thu")),
                  DropdownMenuItem(value: "Fri", child: Text("Fri")),
                  DropdownMenuItem(value: "Sat", child: Text("Sat")),
                  DropdownMenuItem(value: "Sun", child: Text("Sun")),
                ],
                onChanged: (value) => setState(() => _selectedEndDay = value ?? "Fri"),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBusinessHoursSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Business Hours",
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 13,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedStartTime,
                style: const TextStyle(fontSize: 14, color: Colors.black),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF0E7A60), width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: const [
                  DropdownMenuItem(value: "9:00 am", child: Text("9:00 am")),
                  DropdownMenuItem(value: "10:00 am", child: Text("10:00 am")),
                  DropdownMenuItem(value: "11:00 am", child: Text("11:00 am")),
                  DropdownMenuItem(value: "12:00 pm", child: Text("12:00 pm")),
                ],
                onChanged: (value) => setState(() => _selectedStartTime = value ?? "9:00 am"),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                "to",
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedEndTime,
                style: const TextStyle(fontSize: 14, color: Colors.black),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF0E7A60), width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: const [
                  DropdownMenuItem(value: "5:00 pm", child: Text("5:00 pm")),
                  DropdownMenuItem(value: "6:00 pm", child: Text("6:00 pm")),
                  DropdownMenuItem(value: "7:00 pm", child: Text("7:00 pm")),
                  DropdownMenuItem(value: "8:00 pm", child: Text("8:00 pm")),
                ],
                onChanged: (value) => setState(() => _selectedEndTime = value ?? "5:00 pm"),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildServicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Services Provided",
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 13,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          style: const TextStyle(fontSize: 14, color: Colors.black),
          decoration: InputDecoration(
            hintText: "Select services",
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF0E7A60), width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          items: const [
            DropdownMenuItem(value: "Plumbing", child: Text("Plumbing")),
            DropdownMenuItem(value: "Locksmith", child: Text("Locksmith")),
            DropdownMenuItem(value: "Electrical", child: Text("Electrical")),
            DropdownMenuItem(value: "Carpentry", child: Text("Carpentry")),
          ],
          onChanged: (value) {
            if (value != null && !_selectedServices.contains(value)) {
              setState(() {
                _selectedServices.add(value);
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildHourlyRateCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required TextEditingController controller,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5F1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD0E8E1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF0E7A60),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 8, right: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.attach_money,
                        size: 18,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ServiceTag extends StatelessWidget {
  final String text;
  final Color color;
  final Color dotColor;

  const ServiceTag(
      this.text, {
        super.key,
        required this.color,
        required this.dotColor,
      });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}