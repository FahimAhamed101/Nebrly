import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/tokenService.dart';
import '../../../views/screen/welcome/welcome_screen.dart';
import '../../screens/profile/contact_support_screen.dart';
import '../../screens/profile/payment_history_screen.dart';
import '../../screens/profile/terms_conditions_screen.dart';
import '../../screens/profile/privacy_policy_screen.dart';
import '../../screens/profile/faq_screen.dart';


class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(color: Colors.grey),

        _buildSettingItem(context, "Help & Support", () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const FAQScreen()));
        }),
        const Divider(color: Colors.grey),
        _buildSettingItem(context, "Privacy Policy", () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()));
        }),
        const Divider(color: Colors.grey),
        _buildSettingItem(context, "Terms & Condition", () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const TermsConditionsScreen()));
        }),
        const Divider(color: Colors.grey),
        _buildSettingItem(context, "Payment History", () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentHistoryScreen()));
        }),
        const Divider(color: Colors.grey),

        // Logout item
        _buildLogoutItem(context),
      ],
    );
  }

  Widget _buildSettingItem(BuildContext context, String title, [VoidCallback? onTap]) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        size: 16,
        color: Colors.black,
      ),
      onTap: onTap,
    );
  }

  Widget _buildLogoutItem(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(
        "Logout",
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.red,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        size: 16,
        color: Colors.red,
      ),
      onTap: () {
        _showCustomLogoutDialog(context);
      },
    );
  }

  void _showCustomLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Close button
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close, size: 20),
                  ),
                ),

                // Title
                const Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    "Log Out",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Message
                const Text(
                  "Are you sure you want to log out your account?",
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.2,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.start,
                ),

                const SizedBox(height: 20),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Cancel button
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            "Cancel",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Logout button
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          Navigator.of(context).pop(); // Close dialog
                          await _performLogout();
                        },
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            "Log Out",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _performLogout() async {
    try {
      final TokenService tokenService = Get.find<TokenService>();

      // Clear tokens
      await tokenService.removeToken();
      await tokenService.removeUserId();

      // Navigate to welcome screen and clear all routes
      // Replace '/welcome' with your actual welcome screen route
      Get.offAll(() => WelcomeScreen());

      // Show success message
      Get.snackbar(
        'Success',
        'Logged out successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      // Show error message
      Get.snackbar(
        'Error',
        'Failed to logout: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}