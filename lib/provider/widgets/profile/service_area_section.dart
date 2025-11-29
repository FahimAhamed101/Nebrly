// widgets/profile/service_area_section.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/ProviderProfileController.dart';

import '../../screens/profile/service_area_screen.dart';

class ServiceAreaSection extends StatelessWidget {
  const ServiceAreaSection({super.key});

  @override
  Widget build(BuildContext context) {
    final ProviderProfileController controller = Get.find<ProviderProfileController>();

    return Obx(() {
      final user = controller.user.value;
      final serviceAreas = user?.serviceAreas ?? [];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, "Service Area (Zip code)", "Edit"),
          const SizedBox(height: 15),

          if (controller.isLoading.value && user == null)
            _buildServiceAreasShimmer()
          else if (serviceAreas.isEmpty)
            _buildEmptyState(context)
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: serviceAreas.map((area) => ZipTag(area.zipCode)).toList(),
            ),
        ],
      );
    });
  }

  Widget _buildServiceAreasShimmer() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(3, (index) => const ZipShimmer()),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),

      ),
      child: Center(
        child: Text(
          "No service areas added",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
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
                builder: (context) => const ServiceAreaScreen(),
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

class ZipTag extends StatelessWidget {
  final String label;
  const ZipTag(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class ZipShimmer extends StatelessWidget {
  const ZipShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Container(
        width: 50,
        height: 12,
        color: Colors.grey[300],
      ),
    );
  }
}