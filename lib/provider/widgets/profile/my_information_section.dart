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

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              offset: const Offset(0, 2),
              blurRadius: 15,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, "My Information", "Edit"),
            const SizedBox(height: 20),

            if (controller.isLoading.value && user == null)
              ..._buildLoadingInfoItems()
            else if (user != null)
              ..._buildUserInfoItems(context, user)
            else
              _buildErrorState(context),
          ],
        ),
      );
    });
  }

  List<Widget> _buildUserInfoItems(BuildContext context, UserModel user) {
    return [
      // Full Name
      if (user.fullName.isNotEmpty)
        _buildInfoRowWithIcon(
          context,
          Icons.person_outline,
          user.fullName,
        ),

      // Business Name
      if (user.businessNameRegistered.isNotEmpty)
        _buildInfoRowWithIcon(
          context,
          Icons.business_outlined,
          user.businessNameRegistered,
        ),

      // DBA Name (if available)
      if (user.businessNameDBA.isNotEmpty)
        _buildInfoRowWithIcon(
          context,
          Icons.business_outlined,
          "DBA: ${user.businessNameDBA}",
        ),

      // Role
      if (user.providerRole.isNotEmpty)
        _buildInfoRowWithIcon(
          context,
          Icons.work_outline,
          user.providerRole,
        ),

      // Address
      if (user.fullAddress.isNotEmpty)
        _buildInfoRowWithIcon(
          context,
          Icons.location_on_outlined,
          user.fullAddress,
        ),

      // Phone
      if (user.phone.isNotEmpty)
        _buildInfoRowWithIcon(
          context,
          Icons.phone_outlined,
          user.phone,
        ),

      // Email
      if (user.email.isNotEmpty)
        _buildInfoRowWithIcon(
          context,
          Icons.email_outlined,
          user.email,
        ),

      // Website (if available)
      if (user.website.isNotEmpty)
        _buildInfoRowWithIcon(
          context,
          Icons.language_outlined,
          user.website,
        ),

      // Service Areas
      if (user.serviceAreasFormatted.isNotEmpty)
        _buildInfoRowWithIcon(
          context,
          Icons.location_searching_outlined,
          "Service Area zip: ${user.serviceAreasFormatted}",
        ),

      // Working Hours
      if (user.serviceDaysFormatted.isNotEmpty || user.workingHoursFormatted.isNotEmpty)
        _buildWorkingHoursRow(
          context,
          user.serviceDaysFormatted.isNotEmpty ? user.serviceDaysFormatted : "Not specified",
          user.workingHoursFormatted.isNotEmpty ? user.workingHoursFormatted : "Not specified",
        ),

      // Experience
      if (user.experience > 0)
        _buildInfoRowWithIcon(
          context,
          Icons.calendar_today_outlined,
          "Joined: ${user.experience}",
        ),

      // Separator at the end
      const SizedBox(height: 8),
    ];
  }

  List<Widget> _buildLoadingInfoItems() {
    return List.generate(8, (index) => _buildShimmerInfo()).toList();
  }

  Widget _buildShimmerInfo() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
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
        border: Border.all(color: Colors.red[100]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[400], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Failed to load profile information',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.red[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Please try again later',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.red[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRowWithIcon(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.black87,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkingHoursRow(BuildContext context, String days, String hours) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.access_time_outlined,
            size: 20,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  days,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  hours,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
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
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                offset: const Offset(0, 1),
                blurRadius: 4,
              ),
            ],
          ),
          child: TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UpdateInformationScreen(),
                ),
              );
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              backgroundColor: Colors.white,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: Colors.grey[700],
                ),
                const SizedBox(width: 6),
                Text(
                  action,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Alternative version with SVG icons instead of Material icons
class MyInformationSectionSVG extends StatelessWidget {
  const MyInformationSectionSVG({super.key});

  @override
  Widget build(BuildContext context) {
    final ProviderProfileController controller = Get.find<ProviderProfileController>();

    return Obx(() {
      final user = controller.user.value;

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              offset: const Offset(0, 2),
              blurRadius: 15,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, "My Information", "Edit"),
            const SizedBox(height: 20),

            if (controller.isLoading.value && user == null)
              ..._buildLoadingInfoItems()
            else if (user != null)
              ..._buildUserInfoItems(context, user)
            else
              _buildErrorState(context),
          ],
        ),
      );
    });
  }

  List<Widget> _buildUserInfoItems(BuildContext context, UserModel user) {
    return [
      // Full Name
      if (user.fullName.isNotEmpty)
        _buildInfoRowWithSVG(
          context,
          'assets/profile/person.svg',
          user.fullName,
        ),

      // Business Name
      if (user.businessNameRegistered.isNotEmpty)
        _buildInfoRowWithSVG(
          context,
          'assets/profile/person.svg',
          user.businessNameRegistered,
        ),

      // DBA Name
      if (user.businessNameDBA.isNotEmpty)
        _buildInfoRowWithSVG(
          context,
          'assets/profile/person.svg',
          "DBA: ${user.businessNameDBA}",
        ),

      // Role
      if (user.providerRole.isNotEmpty)
        _buildInfoRowWithSVG(
          context,
          'assets/profile/person.svg',
          user.providerRole,
        ),

      // Address
      if (user.fullAddress.isNotEmpty)
        _buildInfoRowWithSVG(
          context,
          'assets/profile/location.svg',
          user.fullAddress,
        ),

      // Phone
      if (user.phone.isNotEmpty)
        _buildInfoRowWithSVG(
          context,
          'assets/profile/phone.svg',
          user.phone,
        ),

      // Email
      if (user.email.isNotEmpty)
        _buildInfoRowWithSVG(
          context,
          'assets/profile/mail.svg',
          user.email,
        ),

      // Website
      if (user.website.isNotEmpty)
        _buildInfoRowWithSVG(
          context,
          'assets/profile/mail.svg',
          user.website,
        ),

      // Service Areas
      if (user.serviceAreasFormatted.isNotEmpty)
        _buildInfoRowWithSVG(
          context,
          'assets/profile/mail.svg',
          "Service Area zip: ${user.serviceAreasFormatted}",
        ),

      // Working Hours
      if (user.serviceDaysFormatted.isNotEmpty || user.workingHoursFormatted.isNotEmpty)
        _buildWorkingHoursRowWithSVG(
          context,
          user.serviceDaysFormatted.isNotEmpty ? user.serviceDaysFormatted : "Not specified",
          user.workingHoursFormatted.isNotEmpty ? user.workingHoursFormatted : "Not specified",
        ),

      // Experience/Joined Date
      if (user.experience > 0)
        _buildInfoRowWithSVG(
          context,
          'assets/profile/calender.svg',
          "Joined: ${user.experience}",
        ),

      const SizedBox(height: 8),
    ];
  }

  Widget _buildInfoRowWithSVG(BuildContext context, String svgPath, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: SvgPicture.asset(
              svgPath,
              width: 16,
              height: 16,
              colorFilter: ColorFilter.mode(
                Colors.grey[600]!,
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.black87,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkingHoursRowWithSVG(BuildContext context, String days, String hours) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: SvgPicture.asset(
              'assets/profile/calender.svg',
              width: 16,
              height: 16,
              colorFilter: ColorFilter.mode(
                Colors.grey[600]!,
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  days,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  hours,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
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
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UpdateInformationScreen(),
                ),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/profile/edit.svg',
                    width: 14,
                    height: 14,
                    colorFilter: ColorFilter.mode(
                      Colors.grey[700]!,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    action,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildLoadingInfoItems() {
    return List.generate(8, (index) => _buildShimmerInfo()).toList();
  }

  Widget _buildShimmerInfo() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
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
        border: Border.all(color: Colors.red[100]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[400], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Failed to load profile information',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.red[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}