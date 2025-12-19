// views/screen/Users/Home/popular_service.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:naibrly/utils/app_colors.dart';
import 'package:naibrly/views/base/AppText/appText.dart';
import 'package:naibrly/views/base/Ios_effect/iosTapEffect.dart';
import 'package:naibrly/views/screen/Users/Home/details/details__screen.dart';
import 'package:naibrly/models/service_model.dart';
import '../../../../../controller/Customer/service_controller.dart';

class Popularservice extends StatelessWidget {
  Popularservice({super.key});

  final ServiceController serviceController = Get.find<ServiceController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (serviceController.isLoading.value) {
        return _buildLoadingState();
      }

      if (serviceController.error.value.isNotEmpty) {
        return _buildErrorState();
      }

      if (serviceController.services.isEmpty) {
        return _buildEmptyState();
      }

      return _buildServicesList();
    });
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      itemCount: 5,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppColors.White,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF000000).withOpacity(0.06),
                offset: const Offset(0, 1),
                blurRadius: 15,
              )
            ],
            border: Border.all(
              width: 0.8,
              color: const Color(0xFF000000).withOpacity(0.10),
            ),
          ),
          child: Row(
            children: [
              // Loading placeholder for image
              Container(
                height: 60,
                width: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade300,
                ),
                child: const Icon(Icons.image, color: Colors.grey),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Loading placeholder for title
                    Container(
                      height: 16,
                      width: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.grey.shade300,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Loading placeholder for price
                    Container(
                      height: 12,
                      width: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.grey.shade300,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.White,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withOpacity(0.06),
            offset: const Offset(0, 1),
            blurRadius: 15,
          )
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 8),
          AppText(
            'Failed to load services',
            color: AppColors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 8),
          AppText(
            serviceController.error.value,
            color: Colors.grey,
            fontSize: 14,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          IosTapEffect(
            onTap: () => serviceController.refreshServices(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: AppText(
                'Try Again',
                color: AppColors.White,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.White,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withOpacity(0.06),
            offset: const Offset(0, 1),
            blurRadius: 15,
          )
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off, color: Colors.grey, size: 48),
          const SizedBox(height: 8),
          AppText(
            'No Services Available',
            color: AppColors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 8),
          AppText(
            'Check back later for available services',
            color: Colors.grey,
            fontSize: 14,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildServicesList() {
    return ListView.builder(
      itemCount: serviceController.services.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final service = serviceController.services[index];

        return IosTapEffect(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailsScreen(
                  service: service,
                  // Add these parameters if you have them
                  providerId: service.providerId, // Add this to your Service model
                  selectedServiceName: service.name,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.White,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF000000).withOpacity(0.06),
                  offset: const Offset(0, 1),
                  blurRadius: 15,
                )
              ],
              border: Border.all(
                width: 0.8,
                color: const Color(0xFF000000).withOpacity(0.10),
              ),
            ),
            child: Row(
              children: [
                // Service Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: service.image.isNotEmpty
                      ? Image.network(
                    service.image,
                    height: 60,
                    width: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildImagePlaceholder();
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return _buildImagePlaceholder();
                    },
                  )
                      : _buildImagePlaceholder(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        service.name, // Use service.name instead of service.title
                        color: AppColors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (service.categoryType?['name'] != null)
                        AppText(
                          service.categoryType!['name'] ?? '',
                          color: Colors.grey,
                          fontSize: 12,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 5),
                      RichText(
                        text: TextSpan(
                          text: "Avg. price: ",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                          ),
                          children: [
                            TextSpan(
                              text: "\$${service.minPrice.toStringAsFixed(0)} - \$${service.maxPrice.toStringAsFixed(0)}",
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      AppText(
                        "\$${service.hourlyRate.toStringAsFixed(0)}/hour",
                        color: Colors.green,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 60,
      width: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade300,
      ),
      child: const Icon(Icons.home_repair_service, color: Colors.grey),
    );
  }
}