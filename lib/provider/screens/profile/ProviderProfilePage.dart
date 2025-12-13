// screens/profile/provider_profile_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_advanced_switch/flutter_advanced_switch.dart';

import '../../controllers/ProviderProfileController.dart' show ProfileController, ProviderProfileController;
import '../../widgets/profile/address_change_section.dart';
import '../../widgets/profile/my_information_section.dart';
import '../../widgets/profile/my_services_section.dart';
import '../../widgets/profile/payout_information_section.dart';
import '../../widgets/profile/profile_header.dart';
import '../../widgets/profile/service_area_section.dart';
import '../../widgets/profile/settings_section.dart';

class ProviderProfilePage extends StatefulWidget {
  const ProviderProfilePage({super.key});

  @override
  State<ProviderProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProviderProfilePage> {
  final ProviderProfileController profileController = Get.find<ProviderProfileController>();
  bool _notificationsExpanded = false;
  final ValueNotifier<bool> _textMsgController = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _emailController = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _onScreenController = ValueNotifier<bool>(true);

  @override
  void initState() {
    super.initState();
    // Refresh profile when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      profileController.refreshProfile();
    });
  }

  @override
  void dispose() {
    _textMsgController.dispose();
    _emailController.dispose();
    _onScreenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await profileController.refreshProfile();
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Your Profile",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 20),

                const ProfileHeader(),

                const SizedBox(height: 30),
                const MyInformationSection(),

                const SizedBox(height: 30),
                const MyServicesSection(),

                const SizedBox(height: 30),
                const ServiceAreaSection(),

                const SizedBox(height: 30),
                const PayoutInformationSection(),

                const SizedBox(height: 30),
                const AddressChangeSection(),

                const SizedBox(height: 20),

                // Notifications expandable section
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Notifications',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  trailing: AnimatedRotation(
                    turns: _notificationsExpanded ? 0.25 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: Colors.black,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      _notificationsExpanded = !_notificationsExpanded;
                    });
                  },
                ),
                if (_notificationsExpanded) ...[
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Text message',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    trailing: AdvancedSwitch(
                      activeColor: Colors.green,
                      inactiveColor: Colors.grey.shade300,
                      width: 44,
                      height: 22,
                      controller: _textMsgController,
                      borderRadius: BorderRadius.circular(77),
                    ),
                  ),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Email',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    trailing: AdvancedSwitch(
                      activeColor: Colors.green,
                      inactiveColor: Colors.grey.shade300,
                      width: 44,
                      height: 22,
                      controller: _emailController,
                      borderRadius: BorderRadius.circular(77),
                    ),
                  ),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'On-screen',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    trailing: AdvancedSwitch(
                      activeColor: Colors.green,
                      inactiveColor: Colors.grey.shade300,
                      width: 44,
                      height: 22,
                      controller: _onScreenController,
                      borderRadius: BorderRadius.circular(77),
                    ),
                  ),
                ],

                const SettingsSection(),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}