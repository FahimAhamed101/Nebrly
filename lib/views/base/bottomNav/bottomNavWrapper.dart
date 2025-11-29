// views/base/bottomNav/bottomNavWrapper.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naibrly/utils/app_colors.dart';
import 'package:naibrly/views/screen/Users/Bundles/bundels_screen.dart';
import 'package:naibrly/views/screen/Users/Home/home_screen.dart';
import 'package:naibrly/views/screen/Users/Profile/profile_screen.dart';
import 'package:naibrly/views/screen/Users/Request/request_screen.dart';
import '../../../controller/BottomController/bottomController.dart';
import '../../../provider/screens/profile/ProviderProfilePage.dart';
import '../../../provider/views/home/home_screen.dart' as provider_home;
import '../../../utils/tokenService.dart';
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

  // Customer pages
  final List<Widget> _customerPages = [
    HomeScreen(),
    BundelsScreen(),
    RequestScreen(),
    ProfileScreen(),
  ];

  // Provider pages
  final List<Widget> _providerPages = [
    provider_home.ProviderHomeScreen(),
    BundelsScreen(),
    RequestScreen(),
    ProviderProfilePage(),
  ];

  List<Widget> get _pages {
    return userRole == 'provider' ? _providerPages : _customerPages;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
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
          ),
        ),
      ),
    ));
  }
}