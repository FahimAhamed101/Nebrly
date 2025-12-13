
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:naibrly/utils/app_colors.dart';
import 'package:naibrly/views/base/AppText/appText.dart';
import 'package:naibrly/views/base/appTextfield/appTextfield.dart';
import 'package:naibrly/views/base/primaryButton/primary_button.dart';
import 'package:naibrly/views/base/bottomNav/bottomNavWrapper.dart';

import '../../../../controller/setnewPassController.dart';



class SetNewPassword extends StatefulWidget {
  final String email;

  const SetNewPassword({super.key, required this.email});

  @override
  State<SetNewPassword> createState() => _SetNewPasswordState();
}

class _SetNewPasswordState extends State<SetNewPassword> {
  late final SetNewPasswordController controller;
  late final TextEditingController passwordController;
  late final TextEditingController confirmController;

  @override
  void initState() {
    super.initState();
    controller = Get.put(SetNewPasswordController());
    passwordController = TextEditingController();
    confirmController = TextEditingController();
  }

  @override
  void dispose() {
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.White,
      appBar: AppBar(
        backgroundColor: AppColors.White,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (controller.isLoading.value) {
              Get.snackbar(
                'Please Wait',
                'Password reset in progress...',
                backgroundColor: Colors.orange,
                colorText: Colors.white,
                duration: const Duration(seconds: 2),
              );
            } else {
              Get.back();
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const AppText(
                "Enter New Password",
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
              const SizedBox(height: 10),
              const AppText(
                "Set a strong password to protect your account",
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.secondary,
              ),
              const SizedBox(height: 30),

              // Password Field
              ReusablePasswordField(
                title: "Password",
                controller: passwordController,
                showHide: controller.showhide,
                toggleVisibility: controller.passwordToggle,
                hint: "Enter new password",
                onTextChanged: (_) => controller.clearError(),
              ),
              const SizedBox(height: 20),

              // Confirm Password Field
              ReusablePasswordField(
                title: "Re-Type Password",
                controller: confirmController,
                showHide: controller.showhideConfirm,
                toggleVisibility: controller.confirmPasswordToggle,
                hint: "Confirm password",
                onTextChanged: (_) => controller.clearError(),
              ),

              // Error Message Display
              Obx(() {
                if (controller.errorMessage.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              controller.errorMessage.value,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),

              // Password Requirements
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppText(
                      "Password must contain:",
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(height: 8),
                    _buildRequirement("At least 6 characters"),
                    _buildRequirement("Letters and numbers"),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Set New Password Button
              Obx(() {
                return PrimaryButton(
                  text: controller.isLoading.value
                      ? "Updating..."
                      : "Set New Password",
                  onTap: () {
                    if (!controller.isLoading.value) {
                      _setNewPassword();
                    }
                  },
                );
              }),
              const SizedBox(height: 24),

              // Footer Links
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () {
                      // Navigate to help/support
                    },
                    child: const AppText(
                      "Need Help",
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.black,
                    ),
                  ),
                  Container(
                    height: 20,
                    width: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    color: AppColors.black.withOpacity(0.3),
                  ),
                  InkWell(
                    onTap: () {
                      // Navigate to FAQ
                    },
                    child: const AppText(
                      "FAQ",
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.black,
                    ),
                  ),
                  Container(
                    height: 20,
                    width: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    color: AppColors.black.withOpacity(0.3),
                  ),
                  InkWell(
                    onTap: () {
                      // Navigate to Terms of Use
                    },
                    child: const AppText(
                      "Terms Of Use",
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequirement(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: AppColors.secondary.withOpacity(0.7),
          ),
          const SizedBox(width: 6),
          AppText(
            text,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.secondary,
          ),
        ],
      ),
    );
  }

  void _setNewPassword() {
    final password = passwordController.text.trim();
    final confirmPassword = confirmController.text.trim();

    // Basic validation
    if (password.isEmpty || confirmPassword.isEmpty) {
      controller.errorMessage.value = 'Please fill in all fields';
      return;
    }

    if (password != confirmPassword) {
      controller.errorMessage.value = 'Passwords do not match';
      return;
    }

    if (password.length < 6) {
      controller.errorMessage.value = 'Password must be at least 6 characters';
      return;
    }

    // Call API to reset password
    controller.resetPassword(
      email: widget.email,
      password: password,
      confirmPassword: confirmPassword,
      onSuccess: () {
        // Show success message
        Get.snackbar(
          'Success',
          'Password reset successfully!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
          snackPosition: SnackPosition.BOTTOM,
        );

        // Navigate to main app
        Future.delayed(const Duration(milliseconds: 800), () {
          Get.offAll(() => const BottomMenuWrappers());
        });
      },
    );
  }
}

// Reusable Password Field Widget
class ReusablePasswordField extends StatelessWidget {
  final String title;
  final String hint;
  final TextEditingController controller;
  final RxBool showHide;
  final VoidCallback toggleVisibility;
  final Function(String)? onTextChanged;

  const ReusablePasswordField({
    super.key,
    required this.title,
    required this.controller,
    required this.showHide,
    required this.toggleVisibility,
    this.hint = "Enter password",
    this.onTextChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          title,
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: AppColors.textprimaruy,
        ),
        const SizedBox(height: 8),
        Obx(
              () => AppTextField(
            obscure: showHide.value,
            controller: controller,
            hint: hint,
            keyboardType: TextInputType.visiblePassword,
            suffix: IconButton(
              icon: Icon(
                showHide.value ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                color: Colors.black.withOpacity(0.5),
              ),
              onPressed: toggleVisibility,
            ),
          ),
        ),
      ],
    );
  }
}