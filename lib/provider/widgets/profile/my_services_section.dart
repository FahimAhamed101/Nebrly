// widgets/profile/my_services_section.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/ProviderProfileController.dart' show ProviderProfileController;


class MyServicesSection extends StatelessWidget {
  const MyServicesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final ProviderProfileController controller = Get.find<ProviderProfileController>();

    return Obx(() {
      final user = controller.user.value;
      final services = user?.servicesProvided ?? [];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "My Services",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 15),

          if (controller.isLoading.value && user == null)
            _buildServicesShimmer()
          else if (services.isEmpty)
            _buildEmptyState(context)
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: services.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final service = entry.value;
                return ServiceTag("$index. ${service.name}", service.hourlyRate);
              }).toList(),
            ),
        ],
      );
    });
  }

  Widget _buildServicesShimmer() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(3, (index) => const ServiceShimmer()),
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
          "No services added yet",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }
}

class ServiceTag extends StatelessWidget {
  final String label;
  final double hourlyRate;

  const ServiceTag(this.label, this.hourlyRate, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "\$$hourlyRate/hr",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 10,
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class ServiceShimmer extends StatelessWidget {
  const ServiceShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 12,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 4),
          Container(
            width: 40,
            height: 10,
            color: Colors.grey[300],
          ),
        ],
      ),
    );
  }
}