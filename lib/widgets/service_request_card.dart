import 'package:flutter/material.dart';
import 'package:naibrly/utils/app_colors.dart';
import 'package:naibrly/views/base/AppText/appText.dart';
import 'package:naibrly/views/base/Ios_effect/iosTapEffect.dart';
import 'package:naibrly/models/service_request_model.dart'; // Add this import

class ServiceRequestCard extends StatelessWidget {
  final String serviceName;
  final double pricePerHour;
  final String clientName;
  final String clientImage;
  final double clientRating;
  final int clientReviewCount;
  final String address;
  final String date;
  final String time;
  final String? problemNote;
  final VoidCallback? onAccept;
  final VoidCallback? onCancel;

  const ServiceRequestCard({
    super.key,
    required this.serviceName,
    required this.pricePerHour,
    required this.clientName,
    required this.clientImage,
    required this.clientRating,
    required this.clientReviewCount,
    required this.address,
    required this.date,
    required this.time,
    this.problemNote,
    this.onAccept,
    this.onCancel,
  });

  // Add this factory constructor
  factory ServiceRequestCard.fromServiceRequest({
    required ServiceRequest serviceRequest,
    required VoidCallback? onAccept,
    required VoidCallback? onCancel,
  }) {
    return ServiceRequestCard(
      serviceName: serviceRequest.serviceType,
      pricePerHour: serviceRequest.price / serviceRequest.estimatedHours,
      clientName: serviceRequest.customer.fullName,
      clientImage: serviceRequest.customer.profileImage?.url ?? 'assets/images/default_avatar.png',
      clientRating: 5.0, // Default rating since it's not in your API
      clientReviewCount: 55, // Default review count
      address: serviceRequest.customer.address.formattedAddress,
      date: _formatDate(serviceRequest.scheduledDate),
      time: _formatTime(serviceRequest.scheduledDate),
      problemNote: serviceRequest.problem,
      onAccept: onAccept,
      onCancel: onCancel,
    );
  }

  // Add these static helper methods
  static String _formatDate(DateTime date) {
    return '${date.day} ${_getMonthName(date.month)} ${date.year}';
  }

  static String _formatTime(DateTime date) {
    final hour = date.hour % 12;
    final period = date.hour < 12 ? 'AM' : 'PM';
    return '${hour == 0 ? 12 : hour}:${date.minute.toString().padLeft(2, '0')} $period';
  }

  static String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x080E7A60), // 3% opacity of #0E7A60
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0x4D0E7A60), // 30% opacity of #0E7A60
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service type and price
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                child: AppText(
                  serviceName,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.Black,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const AppText(
                " : ",
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.Black,
              ),
              AppText(
                '\$${pricePerHour.toInt()}/hr',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Client info
          Row(
            children: [
              _buildClientAvatar(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      clientName,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.Black,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.black, size: 14),
                        const SizedBox(width: 4),
                        AppText(
                          '$clientRating ($clientReviewCount reviews)',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.Black,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Address
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppText(
                'Address: ',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.Black,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: AppText(
                  address,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.DarkGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Date and time
          Row(
            children: [
              AppText(
                'Date: $date',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.DarkGray,
              ),
              const SizedBox(width: 16),
              AppText(
                'Time: $time',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.DarkGray,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Problem note
          if (problemNote != null && problemNote!.isNotEmpty) ...[
            const AppText(
              'Problem Note',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.Black,
            ),
            const SizedBox(height: 4),
            AppText(
              problemNote!,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.DarkGray,
            ),
            const SizedBox(height: 16),
          ],

          // Action buttons
          Row(
            children: [
              Expanded(
                child: IosTapEffect(
                  onTap: onCancel ?? () {},
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEEEEE),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFF34F4F), width: 1),
                    ),
                    child: const Center(
                      child: AppText(
                        'Cancel',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFF34F4F),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: IosTapEffect(
                  onTap: onAccept ?? () {},
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: AppText(
                        'Accept',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClientAvatar() {
    // Check if it's a network image or asset image
    if (clientImage.startsWith('http') || clientImage.startsWith('https')) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: AppColors.primary.withOpacity(0.1),
        child: ClipOval(
          child: Image.network(
            clientImage,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.person,
                color: AppColors.primary,
                size: 20,
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(8),
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              );
            },
          ),
        ),
      );
    } else {
      // Handle asset images
      try {
        return CircleAvatar(
          radius: 20,
          backgroundImage: AssetImage(clientImage),
          onBackgroundImageError: (exception, stackTrace) {
            debugPrint('Failed to load asset image: $exception');
          },
          child: clientImage.contains('default_avatar.png')
              ? const Icon(
            Icons.person,
            color: AppColors.primary,
            size: 20,
          )
              : null,
        );
      } catch (e) {
        debugPrint('Error loading asset image: $e');
        return CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: const Icon(
            Icons.person,
            color: AppColors.primary,
            size: 20,
          ),
        );
      }
    }
  }
}