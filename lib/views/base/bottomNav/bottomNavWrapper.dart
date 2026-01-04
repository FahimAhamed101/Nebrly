import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naibrly/utils/app_colors.dart';

import 'package:naibrly/views/screen/Users/Home/home_screen.dart';
import 'package:naibrly/views/screen/Users/Profile/profile_screen.dart';

import '../../../controller/BottomController/bottomController.dart';
import '../../../provider/screens/notifications_screen.dart';
import '../../../provider/screens/profile/ProviderProfilePage.dart';
import '../../../provider/views/home/home_screen.dart' as provider_home;
import '../../../provider/views/orders/orders_screen.dart'; // Add provider orders screen
 // Add provider notifications screen
import '../../../utils/tokenService.dart';
import '../../screen/Users/Bundles/bundels_screen.dart';
import '../../screen/Users/Requests/requests_screen.dart';
import 'bottomNavBar.dart';

class BottomMenuWrappers extends StatefulWidget {
  const BottomMenuWrappers({super.key});

  @override
  State<BottomMenuWrappers> createState() => _BottomMenuWrappersState();
}

class _BottomMenuWrappersState extends State<BottomMenuWrappers> {
  final BottomNavController controller = Get.put(BottomNavController());
  final TokenService _tokenService = TokenService();
  String? userRole;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getUserRole();
  }

  Future<void> _getUserRole() async {
    await _tokenService.init();
    final role = _tokenService.getUserRole();
    print("🔄 User role detected: $role");

    setState(() {
      userRole = role;
      _isLoading = false;
    });
  }

  // Customer pages (same as before)
  final List<Widget> _customerPages = [
    const HomeScreen(),
    const BundelsScreen(),
    RequestScreen(),
    ProfileScreen(),
  ];

  // Provider pages - Home, Orders, Notifications, Profile
  final List<Widget> _providerPages = [
    const provider_home.ProviderHomeScreen(),
    RequestScreen(), // You need to create this screen
    const NotificationsScreen(), // You need to create this screen
    const ProviderProfilePage(),
  ];

  List<Widget> get _pages {
    return userRole == 'provider' ? _providerPages : _customerPages;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    print("🎯 Building BottomMenuWrappers for: ${userRole ?? 'customer'}");

    return Obx(() => Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        top: false,
        child: IndexedStack(
          index: controller.selectedIndex.value,
          children: _pages,
        ),
      ),
      extendBody: true,
      bottomNavigationBar: SafeArea(
        top: false,
        left: false,
        right: false,
        child: Container(
          color: AppColors.White,
          child: IosStyleBottomNavigations(
            onTap: controller.selectTab,
            currentIndex: controller.selectedIndex.value,
            userRole: userRole, // Pass userRole to bottom nav
          ),
        ),
      ),
    ));
  }
}