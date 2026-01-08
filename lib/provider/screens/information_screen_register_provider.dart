import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/provider_controller.dart';
import '../screens/verify_information_screen.dart';
import '../widgets/button.dart';
import '../widgets/colors.dart';
import '../widgets/textfield.dart';
import '../widgets/upload_card.dart';
import '../widgets/business_hours_bottom_sheet.dart';
import '../widgets/custom_multi_select_dropdown.dart';
import '../widgets/custom_single_select_dropdown.dart';

class YourInformationScreen extends StatefulWidget {
  const YourInformationScreen({super.key});

  @override
  State<YourInformationScreen> createState() => _YourInformationScreenState();
}

class _YourInformationScreenState extends State<YourInformationScreen> {
  final ProviderController providerController = Get.find<ProviderController>();
  final ImagePicker _imagePicker = ImagePicker();

  String selectedCountryCode = "+1";

  final List<String> roleOptions = ["owner", "manager", "operator"];
  List<String> selectedServices = [];
  final List<String> availableServices = [
    "Home Repairs & Maintenance",
    "Cleaning & Organization",
    "Renovations & Upgrades",
    "Electrical Services",
    "Plumbing Services",
    "HVAC Services",
  ];

  // Text Editing Controllers
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController businessNameRegisteredController = TextEditingController();
  final TextEditingController businessNameDBAController = TextEditingController();
  final TextEditingController businessPhoneController = TextEditingController();
  final TextEditingController websiteController = TextEditingController();
  final TextEditingController hourlyRateController = TextEditingController(text: "30");
  final TextEditingController businessAddressStreetController = TextEditingController();
  final TextEditingController businessAddressCityController = TextEditingController();
  final TextEditingController businessAddressStateController = TextEditingController();
  final TextEditingController businessAddressZipCodeController = TextEditingController();
  final TextEditingController experienceController = TextEditingController(text: "5");

  // Business hours state
  List<DayHours> businessHours = [
    DayHours(dayName: "Sunday", isOpen: false),
    DayHours(dayName: "Monday", isOpen: false),
    DayHours(dayName: "Tuesday", isOpen: false),
    DayHours(dayName: "Wednesday", isOpen: false),
    DayHours(dayName: "Thursday", isOpen: false),
    DayHours(dayName: "Friday", isOpen: false),
    DayHours(dayName: "Saturday", isOpen: false),
  ];

  @override
  void initState() {
    super.initState();
    _setupControllerListeners();
  }

  void _setupControllerListeners() {
    // Listen for registration success
    ever(providerController.registrationSuccess, (success) {
      if (success) {
        Get.off(() => const VerifyInformationScreen());
      }
    });
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneController.dispose();
    businessNameRegisteredController.dispose();
    businessNameDBAController.dispose();
    businessPhoneController.dispose();
    websiteController.dispose();
    hourlyRateController.dispose();
    businessAddressStreetController.dispose();
    businessAddressCityController.dispose();
    businessAddressStateController.dispose();
    businessAddressZipCodeController.dispose();
    experienceController.dispose();
    super.dispose();
  }

  // Pick image from gallery - only for business logo
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image != null) {
        providerController.setBusinessLogo(image.path);
        Get.snackbar(
          'Success',
          'Business logo selected successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
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

  // Extract business hours from DayHours list
  Map<String, dynamic> _extractBusinessHours() {
    final openDays = businessHours.where((day) => day.isOpen).toList();

    if (openDays.isEmpty) {
      return {
        'businessServiceStart': '',
        'businessServiceEnd': '',
        'businessHoursStart': '',
        'businessHoursEnd': ''
      };
    }

    // Sort days by their index
    openDays.sort((a, b) {
      final days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
      return days.indexOf(a.dayName).compareTo(days.indexOf(b.dayName));
    });

    final firstDay = openDays.first.dayName.substring(0, 3).toLowerCase();
    final lastDay = openDays.last.dayName.substring(0, 3).toLowerCase();

    // Format time
    String formatTime(TimeOfDay time) {
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      final period = time.hour < 12 ? 'am' : 'pm';
      final hour12 = time.hourOfPeriod;
      return '$hour12:$minute $period';
    }

    final startTime = formatTime(openDays.first.startTime);
    final endTime = formatTime(openDays.first.endTime);

    return {
      'businessServiceStart': firstDay,
      'businessServiceEnd': lastDay,
      'businessHoursStart': startTime,
      'businessHoursEnd': endTime
    };
  }

  // Prepare and submit form data
  void _submitForm() {
    // Validate required fields
    if (firstNameController.text.isEmpty ||
        lastNameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty ||
        phoneController.text.isEmpty ||
        businessNameRegisteredController.text.isEmpty ||
        businessAddressStreetController.text.isEmpty ||
        businessAddressCityController.text.isEmpty ||
        businessAddressStateController.text.isEmpty ||
        businessAddressZipCodeController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill all required fields',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      Get.snackbar(
        'Error',
        'Passwords do not match',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Extract business hours
    final hours = _extractBusinessHours();

    // Update controller values from text fields
    providerController.firstName(firstNameController.text.trim());
    providerController.lastName(lastNameController.text.trim());
    providerController.email(emailController.text.trim());
    providerController.password(passwordController.text);
    providerController.confirmPassword(confirmPasswordController.text);
    providerController.phone('$selectedCountryCode${phoneController.text.trim()}');
    providerController.businessNameRegistered(businessNameRegisteredController.text.trim());
    providerController.businessNameDBA(businessNameDBAController.text.trim());
    providerController.businessPhone(businessPhoneController.text.trim());
    providerController.website(websiteController.text.trim());
    providerController.servicesProvided(selectedServices.join(','));
    providerController.businessServiceStart(hours['businessServiceStart']);
    providerController.businessServiceEnd(hours['businessServiceEnd']);
    providerController.businessHoursStart(hours['businessHoursStart']);
    providerController.businessHoursEnd(hours['businessHoursEnd']);
    providerController.hourlyRate(hourlyRateController.text.trim());
    providerController.businessAddressStreet(businessAddressStreetController.text.trim());
    providerController.businessAddressCity(businessAddressCityController.text.trim());
    providerController.businessAddressState(businessAddressStateController.text.trim());
    providerController.businessAddressZipCode(businessAddressZipCodeController.text.trim());
    providerController.experience(experienceController.text.trim());

    // Call registration
    providerController.registerProvider();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KoreColors.background,
      appBar: AppBar(
        backgroundColor: KoreColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          "Your Information",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subtext
              const Text(
                "We need to collect your personal business information.",
                style: TextStyle(
                  color: Color(0xFF1C1C1C),
                  fontSize: 13,
                ),
                textAlign: TextAlign.start,
              ),

              const SizedBox(height: 20),

              // Upload Business Logo
              const Text(
                "Upload Business Logo",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Obx(() => KoreUploadCard(
                label: "Upload Your Business Logo",
                hint: providerController.businessLogoPath.value.isNotEmpty
                    ? "Logo selected"
                    : "Max 3 MB",
                icon: Icons.cloud_upload_outlined,
                onTap: _pickImage,
              )),
              const SizedBox(height: 24),

              // Business Name (Registered)
              KoreTextField(
                label: "Business Name (AS REGISTERED)",
                hint: "e.g., JM Home Services LLC",
                controller: businessNameRegisteredController,
              ),
              const SizedBox(height: 16),

              // Business Name (DBA)
              KoreTextField(
                label: "Business Name (DBA)",
                hint: "e.g., JM Home Services",
                controller: businessNameDBAController,
              ),
              const SizedBox(height: 16),

              // First Name
              KoreTextField(
                label: "First Name",
                hint: "Jacob",
                controller: firstNameController,
              ),
              const SizedBox(height: 16),

              // Last Name
              KoreTextField(
                label: "Last Name",
                hint: "Meikle",
                controller: lastNameController,
              ),
              const SizedBox(height: 16),

              // Email
              KoreTextField(
                label: "Email",
                hint: "your@email.com",
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Password
              KoreTextField(
                label: "Password",
                hint: "Enter your password",
                controller: passwordController,
                isPassword: true,
              ),
              const SizedBox(height: 16),

              // Confirm Password
              KoreTextField(
                label: "Confirm Password",
                hint: "Confirm your password",
                controller: confirmPasswordController,
                isPassword: true,
              ),
              const SizedBox(height: 16),

              // Role dropdown
              const Text(
                "Role",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              CustomSingleSelectDropdown(
                hint: "Select your role",
                items: roleOptions,
                selectedItem: providerController.providerRole.value,
                onChanged: (value) {
                  if (value != null) {
                    providerController.providerRole(value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Business Address Street
              KoreTextField(
                label: "Business Address Street",
                hint: "123 Main Street",
                controller: businessAddressStreetController,
              ),
              const SizedBox(height: 16),

              // Business Address City, State, Zip Code Row
              Row(
                children: [
                  Expanded(
                    child: KoreTextField(
                      label: "City",
                      hint: "New York",
                      controller: businessAddressCityController,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: KoreTextField(
                      label: "State",
                      hint: "NY",
                      controller: businessAddressStateController,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: KoreTextField(
                      label: "Zip Code",
                      hint: "10001",
                      controller: businessAddressZipCodeController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Phone number row
              const Text(
                "Phone Number",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  // Country code dropdown
                  Container(
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedCountryCode,
                        isDense: true,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: "+1", child: Text("+1")),
                          DropdownMenuItem(value: "+44", child: Text("+44")),
                          DropdownMenuItem(value: "+91", child: Text("+91")),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedCountryCode = value!;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Phone number input
                  Expanded(
                    child: TextField(
                      controller: phoneController,
                      decoration: InputDecoration(
                        hintText: "Phone Number",
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF0E7A60)),
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Business Phone
              KoreTextField(
                label: "Business Phone",
                hint: "+12395550110",
                controller: businessPhoneController,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // Business Website
              KoreTextField(
                label: "Business Website",
                hint: "www.quickfixrepairs.com",
                controller: websiteController,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 24),

              // Business Hours
              const Text(
                "Business Hours",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () {
                  _showBusinessHoursBottomSheet();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Set Your Business Hours",
                              style: TextStyle(
                                color: Color(0xFF1C1C1C),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getBusinessHoursSummary(),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Colors.grey.shade400),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Services Provided
              const Text(
                "Services Provided",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              CustomMultiSelectDropdown(
                hint: "Select Services",
                items: availableServices,
                selectedItems: selectedServices,
                onChanged: (selected) {
                  setState(() {
                    selectedServices = selected;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Experience
              KoreTextField(
                label: "Years of Experience",
                hint: "5",
                controller: experienceController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),

              // Hourly Rate Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E7A60).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF0E7A60), width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF0E7A60),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          "Enter Your Hourly Rate",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1C1C1C),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Padding(
                      padding: EdgeInsets.only(left: 18),
                      child: Text(
                        "Set how much you charge per hour",
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1C1C1C),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text(
                                "\$",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF888888),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: hourlyRateController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: "30",
                                hintStyle: TextStyle(
                                  color: Color(0xFF888888),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1C1C1C),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),

      bottomNavigationBar: SafeArea(
        top: false,
        left: false,
        right: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Obx(() => KoreButton(
            text: providerController.isLoading.value ? "Registering..." : "Next",
            onPressed: providerController.isLoading.value ? null : _submitForm,
          )),
        ),
      ),
    );
  }

  void _showBusinessHoursBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BusinessHoursBottomSheet(
        initialHours: businessHours,
        onSave: (hours) {
          setState(() {
            businessHours = hours;
          });
        },
      ),
    );
  }

  String _getBusinessHoursSummary() {
    final openDays = businessHours.where((day) => day.isOpen).toList();
    if (openDays.isEmpty) {
      return "No hours set";
    }

    final firstDay = openDays.first.dayName.substring(0, 3);
    final lastDay = openDays.last.dayName.substring(0, 3);

    final sampleTime = "${_formatTime(openDays.first.startTime)} - ${_formatTime(openDays.first.endTime)}";
    bool allSameHours = openDays.every((day) =>
    day.startTime.hour == openDays.first.startTime.hour &&
        day.startTime.minute == openDays.first.startTime.minute &&
        day.endTime.hour == openDays.first.endTime.hour &&
        day.endTime.minute == openDays.first.endTime.minute
    );

    if (allSameHours && openDays.length == 7 - businessHours.where((day) => !day.isOpen).length) {
      return "$firstDay - $lastDay • $sampleTime";
    }

    return "${openDays.length} days configured";
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}