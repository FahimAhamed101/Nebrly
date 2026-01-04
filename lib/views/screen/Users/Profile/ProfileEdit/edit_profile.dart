
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_intl_phone_field/flutter_intl_phone_field.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:naibrly/utils/app_icon.dart';

import '../../../../../controller/Customer/profileController/EditProfileController.dart';
import '../../../../../controller/Customer/profileController/profileController.dart';
import '../../../../../utils/app_colors.dart';
import '../../../../base/AppText/appText.dart';
import '../../../../base/Ios_effect/iosTapEffect.dart';
import '../../../../base/appTextfield/appTextfield.dart';
import '../../../../base/primaryButton/primary_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final EditProfileController _controller = Get.put(EditProfileController());
  final ProfileController _profileController = Get.find<ProfileController>();

  // Initialize controllers
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController phoneController;
  late TextEditingController streetController;
  late TextEditingController cityController;
  late TextEditingController stateController;
  late TextEditingController zipCodeController;
  late TextEditingController aptSuiteController;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    firstNameController = TextEditingController();
    lastNameController = TextEditingController();
    phoneController = TextEditingController();
    streetController = TextEditingController();
    cityController = TextEditingController();
    stateController = TextEditingController();
    zipCodeController = TextEditingController();
    aptSuiteController = TextEditingController();

    // Load user data
    _loadUserData();
  }

  void _loadUserData() {
    final user = _profileController.profileInfo.value;
    if (user != null) {
      firstNameController.text = user.firstName;
      lastNameController.text = user.lastName;
      phoneController.text = user.phone;
      streetController.text = user.address.street;
      cityController.text = user.address.city;
      stateController.text = user.address.state;
      zipCodeController.text = user.address.zipCode;
      aptSuiteController.text = user.address.aptSuite;
      _controller.userProfileImageUrl.value = user.profileImage.url;
    }
  }

  @override
  void dispose() {
    // Dispose controllers
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    streetController.dispose();
    cityController.dispose();
    stateController.dispose();
    zipCodeController.dispose();
    aptSuiteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.White,
      appBar: AppBar(
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        backgroundColor: AppColors.White,
        elevation: 0,
        centerTitle: true,
        leading: IosTapEffect(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SvgPicture.asset(
              "assets/icons/icon/arrow-left.svg",
              height: 20,
              width: 20,
            ),
          ),
          onTap: () {
            Get.back();
          },
        ),
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: const AppText(
          "Edit Profile",
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.Black,
        ),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[];
        },
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.01),

              /// Profile Image
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Obx(() {
                      return Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.LightGray,
                            width: 1,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 56,
                          backgroundImage: _controller.selectedImageEDT.value != null
                              ? FileImage(_controller.selectedImageEDT.value!)
                              : NetworkImage(
                            _controller.userProfileImageUrl.value.isNotEmpty
                                ? _controller.userProfileImageUrl.value
                                : 'https://media.istockphoto.com/id/1682296067/photo/happy-studio-portrait-or-professional-man-real-estate-agent-or-asian-businessman-smile-for.jpg?s=612x612&w=0&k=20&c=9zbG2-9fl741fbTWw5fNgcEEe4ll-JegrGlQQ6m54rg=',
                          ) as ImageProvider,
                        ),
                      );
                    }),

                    /// Edit Icon
                    Positioned(
                      bottom: -2,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          _controller.pickImage(ImageSource.gallery);
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.White,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.LightGray,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: SvgPicture.asset(
                              AppIcons.edit,
                              width: 24,
                              height: 24,
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.01),

              const Align(
                alignment: Alignment.center,
                child: AppText(
                  'Upload Profile Photo',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.Black,
                ),
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.03),

              /// First Name
              const AppText(
                "First Name",
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: AppColors.black,
              ),
              const SizedBox(height: 10),
              AppTextField1(
                controller: firstNameController,
                hint: "John",
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.02),

              /// Last Name
              const AppText(
                "Last Name",
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: AppColors.black,
              ),
              const SizedBox(height: 10),
              AppTextField1(
                controller: lastNameController,
                hint: "Doe",
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.02),

              /// Phone
              const AppText(
                "Phone Number",
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: AppColors.black,
              ),
              const SizedBox(height: 10),
              IntlPhoneField(
                controller: phoneController,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.LightGray, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.DarkGray, width: 1),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.red, width: 1),
                  ),
                ),
                initialCountryCode: 'US',
                onChanged: (phone) {
                  print(phone.completeNumber);
                },
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.02),

              /// Street Address
              const AppText(
                "Street",
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: AppColors.black,
              ),
              const SizedBox(height: 10),
              AppTextField1(
                controller: streetController,
                hint: "789 Updated Street",
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.02),

              /// City
              const AppText(
                "City",
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: AppColors.black,
              ),
              const SizedBox(height: 10),
              AppTextField1(
                controller: cityController,
                hint: "Updated City",
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.02),

              /// State
              const AppText(
                "State",
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: AppColors.black,
              ),
              const SizedBox(height: 10),
              AppTextField1(
                controller: stateController,
                hint: "UC",
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.02),

              /// Zip Code
              const AppText(
                "Zip Code",
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: AppColors.black,
              ),
              const SizedBox(height: 10),
              AppTextField1(
                keyboardType: TextInputType.number,
                controller: zipCodeController,
                hint: "54321",
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.02),

              /// Apartment/Suite
              const AppText(
                "Apartment/Suite",
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: AppColors.black,
              ),
              const SizedBox(height: 10),
              AppTextField1(
                controller: aptSuiteController,
                hint: "Suite 100",
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.02),

              ///----- Save Button ------///
              PrimaryButton(
                text: "Save Changes",
                onTap: () {
                  HapticFeedback.lightImpact();
                  _controller.updateProfile(
                    firstName: firstNameController.text.trim(),
                    lastName: lastNameController.text.trim(),
                    phone: phoneController.text.trim(),
                    street: streetController.text.trim(),
                    city: cityController.text.trim(),
                    state: stateController.text.trim(),
                    zipCode: zipCodeController.text.trim(),
                    aptSuite: aptSuiteController.text.trim(),
                    profileImage: _controller.selectedImageEDT.value,
                  );
                },
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.080),
            ],
          ),
        ),
      ),
    );
  }
}