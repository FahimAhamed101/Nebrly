import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:naibrly/utils/app_colors.dart';
import 'package:naibrly/views/base/AppText/appText.dart';
import 'package:naibrly/views/base/appTextfield/appTextfield.dart';
import 'package:naibrly/views/base/primaryButton/primary_button.dart';
import '../../../../controller/Customer/authCustomer/signupController.dart';
import '../../../../utils/app_icon.dart';
import '../Users/auth/base/countryTextfield.dart';


class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final SignUpController controller = Get.put(SignUpController());

  // US States with 2-letter abbreviations
  final List<Map<String, String>> usStates = [
    {'code': 'AL', 'name': 'Alabama'},
    {'code': 'AK', 'name': 'Alaska'},
    {'code': 'AZ', 'name': 'Arizona'},
    {'code': 'AR', 'name': 'Arkansas'},
    {'code': 'CA', 'name': 'California'},
    {'code': 'CO', 'name': 'Colorado'},
    {'code': 'CT', 'name': 'Connecticut'},
    {'code': 'DE', 'name': 'Delaware'},
    {'code': 'FL', 'name': 'Florida'},
    {'code': 'GA', 'name': 'Georgia'},
    {'code': 'HI', 'name': 'Hawaii'},
    {'code': 'ID', 'name': 'Idaho'},
    {'code': 'IL', 'name': 'Illinois'},
    {'code': 'IN', 'name': 'Indiana'},
    {'code': 'IA', 'name': 'Iowa'},
    {'code': 'KS', 'name': 'Kansas'},
    {'code': 'KY', 'name': 'Kentucky'},
    {'code': 'LA', 'name': 'Louisiana'},
    {'code': 'ME', 'name': 'Maine'},
    {'code': 'MD', 'name': 'Maryland'},
    {'code': 'MA', 'name': 'Massachusetts'},
    {'code': 'MI', 'name': 'Michigan'},
    {'code': 'MN', 'name': 'Minnesota'},
    {'code': 'MS', 'name': 'Mississippi'},
    {'code': 'MO', 'name': 'Missouri'},
    {'code': 'MT', 'name': 'Montana'},
    {'code': 'NE', 'name': 'Nebraska'},
    {'code': 'NV', 'name': 'Nevada'},
    {'code': 'NH', 'name': 'New Hampshire'},
    {'code': 'NJ', 'name': 'New Jersey'},
    {'code': 'NM', 'name': 'New Mexico'},
    {'code': 'NY', 'name': 'New York'},
    {'code': 'NC', 'name': 'North Carolina'},
    {'code': 'ND', 'name': 'North Dakota'},
    {'code': 'OH', 'name': 'Ohio'},
    {'code': 'OK', 'name': 'Oklahoma'},
    {'code': 'OR', 'name': 'Oregon'},
    {'code': 'PA', 'name': 'Pennsylvania'},
    {'code': 'RI', 'name': 'Rhode Island'},
    {'code': 'SC', 'name': 'South Carolina'},
    {'code': 'SD', 'name': 'South Dakota'},
    {'code': 'TN', 'name': 'Tennessee'},
    {'code': 'TX', 'name': 'Texas'},
    {'code': 'UT', 'name': 'Utah'},
    {'code': 'VT', 'name': 'Vermont'},
    {'code': 'VA', 'name': 'Virginia'},
    {'code': 'WA', 'name': 'Washington'},
    {'code': 'WV', 'name': 'West Virginia'},
    {'code': 'WI', 'name': 'Wisconsin'},
    {'code': 'WY', 'name': 'Wyoming'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.White,
      body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          child: Column(
              children: [
                const SizedBox(height: 45),
                // Back Arrow
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppColors.black),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.center,
                  child: Image.asset(
                    "assets/images/Frame 2147226486.png",
                    width: 155,
                    height: 48,
                  ),
                ),
                const SizedBox(height: 25),
                Row(
                  children: [
                    Obx(() => ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Center(
                        child: controller.profileImage.value != null
                            ? Image.file(
                          controller.profileImage.value!,
                          fit: BoxFit.cover,
                          width: 50,
                          height: 50,
                        )
                            : SvgPicture.asset(
                          "assets/icons/user_color.svg",
                          width: 30,
                          height: 30,
                        ),
                      ),
                    )),
                    const SizedBox(width: 8),
                    const UploadImage(),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: AppTextField(
                            controller: controller.firstname,
                            hint: "First Name")),
                    const SizedBox(width: 10),
                    Expanded(
                        child: AppTextField(
                            controller: controller.lastname,
                            hint: "Last Name")),
                  ],
                ),
                const SizedBox(height: 10),
                AppTextField(
                    controller: controller.email, hint: "Email Address"),
                const SizedBox(height: 10),
                Obx(
                      () => AppTextField(
                    obscure: !controller.showHide.value, // ✅ Fixed: Hidden by default
                    keyboardType: TextInputType.visiblePassword,
                    controller: controller.password,
                    hint: "Password",
                    suffix: IconButton(
                      icon: Icon(
                        controller.showHide.value
                            ? CupertinoIcons.eye
                            : CupertinoIcons.eye_slash,
                        color: Colors.black.withOpacity(0.50),
                      ),
                      onPressed: () {
                        controller.passwordToggle();
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Password Requirements
                Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(() => _buildPasswordRequirement(
                        "Minimum 6 characters",
                        controller.password.text.length >= 6,
                      )),
                      Obx(() => _buildPasswordRequirement(
                        "At least 1 number",
                        controller.password.text.contains(RegExp(r'\d')),
                      )),
                      Obx(() => _buildPasswordRequirement(
                        "At least 1 capital letter",
                        controller.password.text.contains(RegExp(r'[A-Z]')),
                      )),
                      Obx(() => _buildPasswordRequirement(
                        "At least 1 special character",
                        controller.password.text
                            .contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Obx(
                      () => AppTextField(
                    obscure: !controller.showHide1.value, // ✅ Fixed: Hidden by default
                    keyboardType: TextInputType.visiblePassword,
                    controller: controller.confirmPassword,
                    hint: "Confirm Password",
                    suffix: IconButton(
                      icon: Icon(
                        controller.showHide1.value
                            ? CupertinoIcons.eye
                            : CupertinoIcons.eye_slash,
                        color: Colors.black.withOpacity(0.50),
                      ),
                      onPressed: () {
                        controller.passwordToggle1();
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                CustomCountryCodePicker(
                  countryCodeController: controller.phoneNumber,
                  initialCountryCode: "+1", // ✅ Default to USA
                ),
                const SizedBox(height: 10),
                // ✅ Reordered fields as requested
                AppTextField(
                    controller: controller.streetName,
                    hint: "Street Number and Name"),
                const SizedBox(height: 10),
                AppTextField(
                    controller: controller.aptSuite, hint: "Apt / Suite"),
                const SizedBox(height: 10),
                AppTextField(controller: controller.city, hint: "City"),
                const SizedBox(height: 10),
                AppTextField(
                  controller: controller.zipCode,
                  hint: "Zip Code", // ✅ Fixed spelling
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                // ✅ State Dropdown with 2-letter abbreviations
                Obx(
                      () => Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.black50),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text(
                          "State",
                          style: TextStyle(
                            color: AppColors.black50,
                            fontSize: 14,
                          ),
                        ),
                        value: controller.selectedState.value.isEmpty
                            ? null
                            : controller.selectedState.value,
                        items: usStates.map((state) {
                          return DropdownMenuItem<String>(
                            value: state['code'],
                            child: Text("${state['code']} - ${state['name']}"),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            controller.selectedState.value = value;
                            controller.state.text = value;
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Obx(
                          () => Transform.scale(
                        scale: 1.1,
                        child: Checkbox(
                          value: controller.privacy.value,
                          onChanged: (val) {
                            controller.privacy.value = val ?? false;
                          },
                          activeColor: AppColors.primary,
                          checkColor: Colors.white,
                          materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          side: BorderSide(
                            color: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.color ??
                                Colors.grey,
                            width: 0.8,
                          ),
                        ),
                      ),
                    ),
                    // ✅ Separate links for Terms of Service & Privacy Policy
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                            color: Colors.black87,
                            fontSize: 14,
                          ),
                          children: [
                            const TextSpan(
                                text: "I agree to the ",
                                style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.black)),
                            TextSpan(
                              text: "Terms of Service",
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  // ✅ Link to Terms of Service page
                                  Get.toNamed('/termsOfService');
                                },
                            ),
                            const TextSpan(
                                text: " & ",
                                style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.black)),
                            TextSpan(
                              text: "Privacy Policy",
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  // ✅ Link to Privacy Policy page
                                  Get.toNamed('/privacyPolicy');
                                },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Obx(() {
                  return PrimaryButton(
                    loading: controller.isLoading.value,
                    text: "Sign Up",
                    onTap: () async {
                      final firstname = controller.firstname.text.trim();
                      final lastname = controller.lastname.text.trim();
                      final email = controller.email.text.trim();
                      final password = controller.password.text;
                      final confirmPassword = controller.confirmPassword.text;
                      final phone = controller.phoneNumber.text;
                      final street = controller.streetName.text;
                      final state = controller.state.text;
                      final zipcode = controller.zipCode.text;
                      final aptsuit = controller.aptSuite.text;
                      final city = controller.city.text;

                      if (firstname.isEmpty) {
                        showError(context, "First name is required");
                        return;
                      }
                      if (lastname.isEmpty) {
                        showError(context, "Last name is required");
                        return;
                      }
                      if (email.isEmpty) {
                        showError(context, "Email is required");
                        return;
                      }
                      if (password.isEmpty) {
                        showError(context, "Password is required");
                        return;
                      }
                      // ✅ Validate password requirements
                      if (!controller.isPasswordValid()) {
                        showError(context,
                            "Password must meet all requirements");
                        return;
                      }
                      if (phone.isEmpty) {
                        showError(context, "Phone number is required");
                        return;
                      }
                      if (street.isEmpty) {
                        showError(context, "Street address is required");
                        return;
                      }
                      if (city.isEmpty) {
                        showError(context, "City is required");
                        return;
                      }
                      if (zipcode.isEmpty) {
                        showError(context, "Zip code is required");
                        return;
                      }
                      if (state.isEmpty) {
                        showError(context, "State is required");
                        return;
                      }
                      if (aptsuit.isEmpty) {
                        showError(context, "Apt/Suite is required");
                        return;
                      }
                      if (password != confirmPassword) {
                        showError(context, "Passwords do not match");
                        return;
                      }
                      if (!controller.privacy.value) {
                        showError(context,
                            "Please agree to Terms of Service & Privacy Policy");
                        return;
                      }

                      await controller.signUp(
                        context,
                        firstnames: firstname,
                        lasnames: lastname,
                        emails: email,
                        passwords: password,
                        confrimpasswords: confirmPassword,
                        phones: phone,
                        streets: street,
                        citys: city,
                        states: state,
                        zipcodes: zipcode,
                        aptSuites: aptsuit,
                      );
                    },
                  );
                }),
                const SizedBox(height: 20),
                orDivided(),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 50,
                      width: 50,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          const BoxShadow(
                            color: Color(0xffeeeeee),
                            offset: Offset(0, 3),
                            blurRadius: 5,
                          )
                        ],
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: SvgPicture.asset(AppIcons.google),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      height: 50,
                      width: 50,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          const BoxShadow(
                            color: Color(0xffeeeeee),
                            offset: Offset(0, 3),
                            blurRadius: 5,
                          )
                        ],
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: SvgPicture.asset(AppIcons.apple),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ])),
    );
  }

  Widget _buildPasswordRequirement(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: isMet ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isMet ? Colors.green : Colors.grey,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ),
    );
  }

  void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget orDivided() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.secondary,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: AppText(
            "Or continue with",
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.black,
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.secondary,
          ),
        ),
      ],
    );
  }
}

class UploadImage extends StatelessWidget {
  const UploadImage({super.key});

  @override
  Widget build(BuildContext context) {
    final SignUpController controller = Get.find();
    return GestureDetector(
      onTap: () {
        controller.pickProfileImage();
      },
      child: Container(
        height: 45,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            width: 1,
            color: AppColors.black50,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppText(
              "Upload Image",
              color: AppColors.black,
              fontSize: 14,
            ),
            const SizedBox(width: 8),
            SvgPicture.asset("assets/icons/elements (4).svg"),
          ],
        ),
      ),
    );
  }
}