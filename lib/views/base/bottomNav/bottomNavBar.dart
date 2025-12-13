import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';

import '../../../utils/app_colors.dart';

class IosStyleBottomNavigations extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final String? userRole; // Add userRole parameter

  IosStyleBottomNavigations({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.userRole = 'customer', // Default to customer
  });

  Color _getColor(int index) => index == currentIndex ? AppColors.black : AppColors.black50;

  // Different icons for customer and provider
  List<String> get _icons {
    if (userRole == 'provider') {
      return [
        "assets/icons/elements.svg", // Home for provider
        "assets/icons/orders.svg", // Orders icon
        "assets/icons/notification.svg", // Notifications icon
        "assets/icons/user.svg", // Profile
      ];
    } else {
      return [
        "assets/icons/elements.svg", // Home for customer
        "assets/icons/people.svg", // Bundles
        "assets/icons/Icon (3).svg", // Requests
        "assets/icons/user.svg", // Profile
      ];
    }
  }

  List<String> get _labels {
    if (userRole == 'provider') {
      return [
        'Home',
        'Orders',
        'Notification',
        'Profile',
      ];
    } else {
      return [
        'Home',
        'Bundles',
        'Requests',
        'Profile',
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(36),
          topLeft: Radius.circular(36),
        ),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 0.5,
        ),
      ),
      child: SafeArea(
        child: Container(
          color: Colors.transparent,
          height: 80,
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
                _labels.length,
                    (index) => _buildNavItem(index)
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact(); // iOS-style feedback
        onTap(index);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              curve: Curves.fastOutSlowIn,
              duration: const Duration(milliseconds: 200),
              child: SvgPicture.asset(
                _icons[index],
                height: 26.0,
                width: 26.0,
                color: _getColor(index),
              ),
            ),
            SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              curve: Curves.fastOutSlowIn,
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: isSelected ? 12 : 11,
                letterSpacing: 0,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: _getColor(index),
              ),
              child: Text(_labels[index]),
            ),
          ],
        ),
      ),
    );
  }
}