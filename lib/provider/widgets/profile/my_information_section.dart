// widgets/profile/my_information_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../../models/user_model_provider.dart';
import '../../controllers/ProviderProfileController.dart';

import '../../screens/profile/update_information_screen.dart';

class MyInformationSection extends StatelessWidget {
  const MyInformationSection({super.key});

  @override
  Widget build(BuildContext context) {
    final ProviderProfileController controller = Get.find<ProviderProfileController>();

    return Obx(() {
      final user = controller.user.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, "My Information", "Edit"),
          const SizedBox(height: 15),

          if (controller.isLoading.value && user == null)
            ..._buildLoadingInfoItems()
          else if (user != null)
            ..._buildUserInfoItems(context, user)
          else
            _buildErrorState(context),
        ],
      );
    });
  }

  List<Widget> _buildUserInfoItems(BuildContext context, UserModel user) {
    return [
      _buildInfoWithSvg(context, 'assets/profile/person.svg', user.fullName),
      _buildInfoWithSvg(context, 'assets/profile/person.svg', user.businessNameRegistered),
      if (user.businessNameDBA.isNotEmpty)
        _buildInfoWithSvg(context, 'assets/profile/person.svg', "DBA: ${user.businessNameDBA}"),
      _buildInfoWithSvg(context, 'assets/profile/person.svg', user.providerRole),
      _buildInfoWithSvg(context, 'assets/profile/location.svg', user.fullAddress),
      _buildInfoWithSvg(context, 'assets/profile/phone.svg', user.phone),
      _buildInfoWithSvg(context, 'assets/profile/mail.svg', user.email),
      _buildInfoWithSvg(context, 'assets/profile/mail.svg', user.website.isNotEmpty ? user.website : "Not provided"),
      _buildInfoWithSvg(context, 'assets/profile/mail.svg', "Service Areas: ${user.serviceAreasFormatted}"),
      _buildInfoWithTimeAndSvg(
          context,
          'assets/profile/calender.svg',
          user.serviceDaysFormatted,
          user.workingHoursFormatted
      ),
      _buildInfoWithSvg(context, 'assets/profile/calender.svg', "Experience: ${user.experience} years"),
    ];
  }

  List<Widget> _buildLoadingInfoItems() {
    return List.generate(8, (index) => _buildShimmerInfo());
  }

  Widget _buildShimmerInfo() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 16,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[400]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Failed to load profile information',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.red[700],
              ),
            ),
          ),


        ],
      ),
    );
  }

  Widget _buildInfoWithSvg(BuildContext context, String svgPath, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.asset(
            svgPath,
            width: 18,
            height: 18,
            colorFilter: ColorFilter.mode(
              Colors.grey[600]!,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoWithTimeAndSvg(BuildContext context, String svgPath, String leftText, String rightText) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.asset(
            svgPath,
            width: 18,
            height: 18,
            colorFilter: ColorFilter.mode(
              Colors.grey[600]!,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  leftText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black87,
                    fontSize: 14,
                  ),
                ),
                Text(
                  rightText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black87,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const UpdateInformationScreen(),
              ),
            );
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            backgroundColor: Colors.white,
          ),
          child: Text(
            action,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}