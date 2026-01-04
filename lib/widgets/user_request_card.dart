// widgets/user_request_card.dart
import 'package:flutter/material.dart';
import 'package:naibrly/models/user_request1.dart';
import 'package:naibrly/utils/app_colors.dart';
import 'package:naibrly/views/base/AppText/appText.dart';

class UserRequestCard extends StatelessWidget {
  final UserRequest request;
  final VoidCallback onTap;

  const UserRequestCard({
    super.key,
    required this.request,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final providerName = request.provider?.fullName ??
        request.providerName ??
        'Provider';
    final providerImage = request.providerImage ??
        request.provider?.businessLogo?.url ??
        request.imagePath ??
        'assets/images/default_avatar.png';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: request.isBundle ? const Color(0xFF0E7A60).withOpacity(0.3) : Colors.grey[200]!,
            width: request.isBundle ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Bundle Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (request.isBundle)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0E7A60),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                color: Colors.white,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              AppText(
                                'Bundle',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: AppText(
                          request.serviceName,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.Black,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: request.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: request.statusColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: AppText(
                    request.statusText,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: request.statusColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Provider Info
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: providerImage.startsWith('http')
                      ? NetworkImage(providerImage)
                      : AssetImage(providerImage) as ImageProvider,
                  onBackgroundImageError: (exception, stackTrace) {
                    // Handle error
                  },
                  child: providerImage.startsWith('http')
                      ? null
                      : const Icon(Icons.person, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        providerName,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.Black,
                      ),
                      if (request.providerRating != null || request.provider?.rating != null)
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 12),
                            const SizedBox(width: 2),
                            AppText(
                              '${request.providerRating ?? request.provider?.rating ?? 0.0}',
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: AppColors.DarkGray,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                AppText(
                  '\$${request.averagePrice.toStringAsFixed(0)}',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0E7A60),
                ),
              ],
            ),

            // Bundle-specific info
            if (request.isBundle) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E7A60).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (request.bundleServices != null && request.bundleServices!.isNotEmpty) ...[
                      AppText(
                        'Services (${request.bundleServices!.length}):',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.Black,
                      ),
                      const SizedBox(height: 4),
                      ...request.bundleServices!.take(2).map((service) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, size: 12, color: Color(0xFF0E7A60)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: AppText(
                                '${service.name} (${service.estimatedHours}h)',
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                color: AppColors.DarkGray,
                              ),
                            ),
                          ],
                        ),
                      )),
                      if (request.bundleServices!.length > 2)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: AppText(
                            '+${request.bundleServices!.length - 2} more services',
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF0E7A60),
                          ),
                        ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.people_outline, size: 12, color: Color(0xFF0E7A60)),
                        const SizedBox(width: 4),
                        AppText(
                          '${request.currentParticipants}/${request.maxParticipants} joined',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.DarkGray,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 8),

            // Date and Time
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 12, color: Color(0xFF0E7A60)),
                const SizedBox(width: 4),
                AppText(
                  request.formattedDate,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.DarkGray,
                ),
                const SizedBox(width: 12),
                const Icon(Icons.access_time, size: 12, color: Color(0xFF0E7A60)),
                const SizedBox(width: 4),
                AppText(
                  request.time,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.DarkGray,
                ),
              ],
            ),

            // Address
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF0E7A60)),
                const SizedBox(width: 4),
                Expanded(
                  child: AppText(
                    request.address,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: AppColors.DarkGray,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // Team/Bundle indicator
            if (request.isTeamService || (request.isBundle && request.maxParticipants! > 1)) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people, size: 12, color: Colors.blue[700]),
                    const SizedBox(width: 4),
                    AppText(
                      request.bundleType ?? 'Group Service',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700]!,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}