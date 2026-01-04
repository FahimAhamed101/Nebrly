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
  final UpdateprofileController _controller = Get.find<UpdateprofileController>();

  final TextEditingController _businessNameRegisteredController = TextEditingController();
  final TextEditingController _businessNameDBAController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _locksmithRateController = TextEditingController();
  final TextEditingController _plumberRateController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();

  String _selectedRole = "";
  String _selectedStartDay = "mon";
  String _selectedEndDay = "fri";
  String _selectedStartTime = "9.00pm";
  String _selectedEndTime = "10.00am";
  String _selectedCountryCode = "1+";

  List<String> _selectedServices = ["Plumbing", "Locksmith"];
  final List<String> _availableServices = [
    "Electrical", "Appliance Repairs", "Carpet Cleaning",
    "Concrete & Masonry", "Plumbing", "Locksmith"
  ];

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

      // Load basic user info
      _businessNameRegisteredController.text = user.businessNameRegistered ?? "";
      _businessNameDBAController.text = user.businessNameDBA ?? "";
      _firstNameController.text = user.firstName ?? "";
      _lastNameController.text = user.lastName ?? "";
      _emailController.text = user.email ?? "";
      _phoneController.text = user.phone ?? "";
      _websiteController.text = user.website ?? "";
      _descriptionController.text = user.description ?? "";
      _experienceController.text = user.experience.toString() ?? "0";

      // Set role from providerRole
      _selectedRole = user.providerRole ?? "";

      // Load address from businessAddress
      _addressController.text = _getUserAddress(user);

      // Load service days
      _selectedStartDay = user.businessServiceDays!.start.toLowerCase();
      _selectedEndDay = user.businessServiceDays!.end.toLowerCase();
    
      // Load business hours
      _selectedStartTime = user.businessHours!.start;
      _selectedEndTime = user.businessHours!.end;
    
      // Load hourly rates
      if (user.locksmithRate != null && user.locksmithRate! > 0) {
        _locksmithRateController.text = user.locksmithRate!.toStringAsFixed(2);
      }
      if (user.plumberRate != null && user.plumberRate! > 0) {
        _plumberRateController.text = user.plumberRate!.toStringAsFixed(2);
      }

      // Load services provided
      if (user.servicesProvided.isNotEmpty) {
        _selectedServices = user.servicesProvided.map((service) => service.name).toList();
      } else if (user.selectedServices != null) {
        _selectedServices = List<String>.from(user.selectedServices!);
      }
    }
  }

  String _getUserAddress(UserModel user) {
    final address = user.businessAddress!;
    final parts = [
      address.street,
      address.city,
      if (address.state.isNotEmpty) address.state,
      if (address.zipCode.isNotEmpty) address.zipCode,
    ].where((part) => part.isNotEmpty).toList();
    return parts.join(', ');
      return user.address ?? "123 Main Street, New York, NY";
  }

  @override
  void dispose() {
    _businessNameRegisteredController.dispose();
    _businessNameDBAController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _locksmithRateController.dispose();
    _plumberRateController.dispose();
    _descriptionController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    try {
      // Prepare data for update
      final List<Map<String, dynamic>> servicesToAdd = _selectedServices.map((service) {
        double hourlyRate = 0;

        // Set rate based on service type
        if (service.toLowerCase().contains('locksmith')) {
          hourlyRate = double.tryParse(_locksmithRateController.text.trim()) ?? 0;
        } else if (service.toLowerCase().contains('plumbing') ||
            service.toLowerCase().contains('plumber')) {
          hourlyRate = double.tryParse(_plumberRateController.text.trim()) ?? 0;
        } else {
          // Default rate for other services
          hourlyRate = 50.0;
        }

        return {
          'name': service,
          'hourlyRate': hourlyRate,
        };
      }).toList();

      // Check if we have existing services to remove
      final List<Map<String, dynamic>> servicesToRemove = [];
      if (_controller.user.value?.servicesProvided != null) {
        final existingServices = _controller.user.value!.servicesProvided;
        for (var existing in existingServices) {
          if (!_selectedServices.contains(existing.name)) {
            servicesToRemove.add({
              '_id': existing.id,
              'name': existing.name,
            });
          }
        }
      }

      // Update the profile
      final success = await _controller.updateProviderProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.trim(),
        businessNameRegistered: _businessNameRegisteredController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : "Professional service provider",
        experience: _experienceController.text.trim().isNotEmpty
            ? _experienceController.text.trim()
            : "5",
        maxBundleCapacity: "10",
        servicesToRemove: servicesToRemove.isNotEmpty ? servicesToRemove : null,
        servicesToAdd: servicesToAdd,
      );

      if (success) {
        Get.back();
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

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: "First Name",
                      controller: _firstNameController,
                      hintText: "Enter first name",
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      label: "Last Name",
                      controller: _lastNameController,
                      hintText: "Enter last name",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildTextField(
                label: "Email",
                controller: _emailController,
                hintText: "Enter email address",
                readOnly: true, // Email is usually not editable
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
                    items: const ["owner", "manager", "employee"],
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
                hintText: "Business address",
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              _buildPhoneNumberFields(),
              const SizedBox(height: 16),

              _buildTextField(
                label: "Business Website",
                controller: _websiteController,
                hintText: "https://example.com",
              ),
              const SizedBox(height: 16),

              _buildTextField(
                label: "Years of Experience",
                controller: _experienceController,
                hintText: "Enter years of experience",
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),

              _buildServiceDaysSection(),
              const SizedBox(height: 16),

              _buildBusinessHoursSection(),
              const SizedBox(height: 20),

              _buildServicesSection(),
              const SizedBox(height: 16),

              // Selected Services Chips
              if (_selectedServices.isNotEmpty)
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
                    "Update Profile",
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

  // Build methods remain mostly the same with small improvements
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    bool readOnly = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
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
          keyboardType: keyboardType,
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

            filled: true,
            fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
          ),
        ),
      ],
    );
  }

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
                initialValue: _selectedCountryCode,
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
                  DropdownMenuItem(value: "1+", child: Text("1+ (US)")),
                  DropdownMenuItem(value: "44+", child: Text("44+ (UK)")),
                  DropdownMenuItem(value: "91+", child: Text("91+ (IN)")),
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
                initialValue: _selectedStartDay,
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
                  DropdownMenuItem(value: "mon", child: Text("Monday")),
                  DropdownMenuItem(value: "tue", child: Text("Tuesday")),
                  DropdownMenuItem(value: "wed", child: Text("Wednesday")),
                  DropdownMenuItem(value: "thu", child: Text("Thursday")),
                  DropdownMenuItem(value: "fri", child: Text("Friday")),
                  DropdownMenuItem(value: "sat", child: Text("Saturday")),
                  DropdownMenuItem(value: "sun", child: Text("Sunday")),
                ],
                onChanged: (value) => setState(() => _selectedStartDay = value ?? "mon"),
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
                initialValue: _selectedEndDay,
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
                  DropdownMenuItem(value: "mon", child: Text("Monday")),
                  DropdownMenuItem(value: "tue", child: Text("Tuesday")),
                  DropdownMenuItem(value: "wed", child: Text("Wednesday")),
                  DropdownMenuItem(value: "thu", child: Text("Thursday")),
                  DropdownMenuItem(value: "fri", child: Text("Friday")),
                  DropdownMenuItem(value: "sat", child: Text("Saturday")),
                  DropdownMenuItem(value: "sun", child: Text("Sunday")),
                ],
                onChanged: (value) => setState(() => _selectedEndDay = value ?? "fri"),
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
                initialValue: _selectedStartTime,
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
                  DropdownMenuItem(value: "9.00am", child: Text("9:00 AM")),
                  DropdownMenuItem(value: "10.00am", child: Text("10:00 AM")),
                  DropdownMenuItem(value: "11.00am", child: Text("11:00 AM")),
                  DropdownMenuItem(value: "12.00pm", child: Text("12:00 PM")),
                  DropdownMenuItem(value: "1.00pm", child: Text("1:00 PM")),
                  DropdownMenuItem(value: "2.00pm", child: Text("2:00 PM")),
                  DropdownMenuItem(value: "3.00pm", child: Text("3:00 PM")),
                  DropdownMenuItem(value: "4.00pm", child: Text("4:00 PM")),
                  DropdownMenuItem(value: "5.00pm", child: Text("5:00 PM")),
                  DropdownMenuItem(value: "6.00pm", child: Text("6:00 PM")),
                  DropdownMenuItem(value: "7.00pm", child: Text("7:00 PM")),
                  DropdownMenuItem(value: "8.00pm", child: Text("8:00 PM")),
                  DropdownMenuItem(value: "9.00pm", child: Text("9:00 PM")),
                ],
                onChanged: (value) => setState(() => _selectedStartTime = value ?? "9.00am"),
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
                initialValue: _selectedEndTime,
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
                  DropdownMenuItem(value: "9.00am", child: Text("9:00 AM")),
                  DropdownMenuItem(value: "10.00am", child: Text("10:00 AM")),
                  DropdownMenuItem(value: "11.00am", child: Text("11:00 AM")),
                  DropdownMenuItem(value: "12.00pm", child: Text("12:00 PM")),
                  DropdownMenuItem(value: "1.00pm", child: Text("1:00 PM")),
                  DropdownMenuItem(value: "2.00pm", child: Text("2:00 PM")),
                  DropdownMenuItem(value: "3.00pm", child: Text("3:00 PM")),
                  DropdownMenuItem(value: "4.00pm", child: Text("4:00 PM")),
                  DropdownMenuItem(value: "5.00pm", child: Text("5:00 PM")),
                  DropdownMenuItem(value: "6.00pm", child: Text("6:00 PM")),
                  DropdownMenuItem(value: "7.00pm", child: Text("7:00 PM")),
                  DropdownMenuItem(value: "8.00pm", child: Text("8:00 PM")),
                  DropdownMenuItem(value: "9.00pm", child: Text("9:00 PM")),
                  DropdownMenuItem(value: "10.00pm", child: Text("10:00 PM")),
                ],
                onChanged: (value) => setState(() => _selectedEndTime = value ?? "5.00pm"),
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
          items: _availableServices.map((service) {
            return DropdownMenuItem(
              value: service,
              child: Text(service),
            );
          }).toList(),
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
                  decoration: const BoxDecoration(
                    color: Color(0xFF0E7A60),
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
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
        )
    );
  }
}