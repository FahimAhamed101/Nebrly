// views/screen/auth/sign_up.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:naibrly/utils/app_colors.dart';
import 'package:naibrly/views/base/AppText/appText.dart';
import 'package:naibrly/views/base/appTextfield/appTextfield.dart';
import 'package:naibrly/views/base/primaryButton/primary_button.dart';
import '../../../controller/auth_controller.dart';
import '../../../utils/app_icon.dart';
import '../Users/auth/base/countryTextfield.dart';


class SignUp extends StatefulWidget {
  SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final AuthController controller = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    controller.clearControllers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.White,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Column(
          children: [
            SizedBox(height: 45),
            Align(
              alignment: Alignment.center,
              child: Image.asset("assets/images/Frame 2147226486.png", width: 155, height: 48),
            ),
            SizedBox(height: 25),

            // Role Selection
            _buildRoleSelection(),
            SizedBox(height: 20),

            // Profile Image
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
                SizedBox(width: 8),
                UploadImage(),
              ],
            ),
            SizedBox(height: 12),

            // Personal Information
            Row(
              children: [
                Expanded(child: AppTextField(controller: controller.firstname, hint: "First Name")),
                SizedBox(width: 10),
                Expanded(child: AppTextField(controller: controller.lastname, hint: "Last Name")),
              ],
            ),
            SizedBox(height: 10),
            AppTextField(controller: controller.emailController, hint: "Email Address"),
            SizedBox(height: 10),
            Obx(() => AppTextField(
              obscure: !controller.showHide.value,
              keyboardType: TextInputType.text,
              controller: controller.passwordController,
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
            )),
            SizedBox(height: 10),
            Obx(() => AppTextField(
              obscure: !controller.showHide1.value,
              keyboardType: TextInputType.text,
              controller: controller.confirmPasswordController,
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
            )),
            SizedBox(height: 16),

            // Provider-specific fields
            Obx(() {
              if (controller.userRole.value == 'provider') {
                return Column(
                  children: [
                    AppTextField(controller: controller.businessName, hint: "Business Name"),
                    SizedBox(height: 10),
                    AppTextField(controller: controller.providerRole, hint: "Service Role (e.g., Plumber, Electrician)"),
                    SizedBox(height: 10),
                    AppTextField(controller: controller.experience, hint: "Years of Experience", keyboardType: TextInputType.number),
                    SizedBox(height: 10),
                    AppTextField(controller: controller.serviceDescription, hint: "Service Description"),
                    SizedBox(height: 10),
                  ],
                );
              }
              return SizedBox();
            }),

            CustomCountryCodePicker(
              countryCodeController: controller.phoneNumber,
              initialCountryCode: "",
            ),
            SizedBox(height: 5),
            AppTextField(controller: controller.streetName, hint: "Street Number and Name"),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: AppTextField(controller: controller.state, hint: "State")),
                SizedBox(width: 10),
                Expanded(child: AppTextField(controller: controller.zipCode, hint: "Zip Code", keyboardType: TextInputType.number)),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: AppTextField(controller: controller.city, hint: "City")),
                SizedBox(width: 10),
                Expanded(child: AppTextField(controller: controller.aptSuite, hint: "Apt / Suite")),
              ],
            ),
            SizedBox(height: 10),

            // Terms and Conditions
            Row(
              children: [
                Obx(() => Transform.scale(
                  scale: 1.1,
                  child: Checkbox(
                    value: controller.privacy.value,
                    onChanged: (val) {
                      controller.privacy.value = val ?? false;
                    },
                    activeColor: AppColors.primary,
                    checkColor: Colors.white,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    side: BorderSide(
                      color: Theme.of(context).textTheme.titleSmall?.color ?? Colors.grey,
                      width: 0.8,
                    ),
                  ),
                )),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.black87,
                        fontSize: 14,
                      ),
                      children: [
                        TextSpan(text: "I agree to the ", style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.black)),
                        TextSpan(
                          text: "Terms of Service & Privacy Policy",
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Get.toNamed('/privacyPolicy');
                            },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Sign Up Button
            Obx(() {
              return PrimaryButton(
                loading: controller.isLoading.value,
                text: "Sign Up",
                onTap: () async {
                  if (controller.userRole.value == 'customer') {
                    await controller.signUpCustomer(context);
                  } else {
                    await controller.signUpProvider(context);
                  }
                },
              );
            }),
            SizedBox(height: 20),
            orDivided(),
            SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 50,
                  width: 50,
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xffeeeeee),
                        offset: Offset(0, 3),
                        blurRadius: 5,
                      )
                    ],
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: SvgPicture.asset(AppIcons.google),
                ),
                SizedBox(width: 10),
                Container(
                  height: 50,
                  width: 50,
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
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
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSelection() {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(

        borderRadius: BorderRadius.circular(12),

      ),
      child: Row(
        children: [
          Expanded(
            child: Obx(() => GestureDetector(
              onTap: () => controller.setUserRole('customer'),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: controller.userRole.value == 'customer'
                      ? AppColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    "Customer",
                    style: TextStyle(
                      color: controller.userRole.value == 'customer'
                          ? Colors.white
                          : Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            )),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Obx(() => GestureDetector(
              onTap: () => controller.setUserRole('provider'),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: controller.userRole.value == 'provider'
                      ? AppColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    "Service Provider",
                    style: TextStyle(
                      color: controller.userRole.value == 'provider'
                          ? Colors.white
                          : Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            )),
          ),
        ],
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: AppText("Or continue with", fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.black),
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
    final AuthController controller = Get.find();
    return GestureDetector(
      onTap: () {
        controller.pickProfileImage();
      },
      child: Container(
        height: 45,
        padding: EdgeInsets.symmetric(horizontal: 10),
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
            AppText(
              "Upload Image",
              color: AppColors.black,
              fontSize: 14,
            ),
            SizedBox(width: 8),
            SvgPicture.asset("assets/icons/elements (4).svg"),
          ],
        ),
      ),
    );
  }
}