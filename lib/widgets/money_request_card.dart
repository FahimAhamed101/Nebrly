import 'package:flutter/material.dart';
import 'package:naibrly/models/money_request_model.dart';
import 'package:naibrly/utils/app_colors.dart';
import 'package:naibrly/views/base/AppText/appText.dart';

class MoneyRequestCard extends StatelessWidget {
  final MoneyRequest moneyRequest;
  final VoidCallback onAccept;
  final VoidCallback onCancel;

  const MoneyRequestCard({
    Key? key,
    required this.moneyRequest,
    required this.onAccept,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine the service title based on bundle or serviceRequest
    String serviceTitle = '';
    if (moneyRequest.bundle != null) {
      serviceTitle = moneyRequest.bundle!.title;
    } else if (moneyRequest.serviceRequest != null) {
      serviceTitle = moneyRequest.serviceRequest!.serviceType;
    } else {
      serviceTitle = 'Service Payment';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textcolor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with business name
          AppText(
            "${moneyRequest.provider.businessNameRegistered}'s request.",
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.textcolor.withOpacity(0.7),
          ),
          const SizedBox(height: 12),

          // Service title and price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: AppText(
                  serviceTitle,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
              AppText(
                '\$${moneyRequest.totalAmount.toInt()}',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Provider info
          Row(
            children: [
              // Provider logo
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.textcolor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: ClipOval(
                  child: moneyRequest.provider.businessLogo.url.isNotEmpty
                      ? Image.network(
                    moneyRequest.provider.businessLogo.url,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.primary.withOpacity(0.1),
                        child: Icon(
                          Icons.business,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      );
                    },
                  )
                      : Container(
                    color: AppColors.primary.withOpacity(0.1),
                    child: Icon(
                      Icons.business,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Business name and rating
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      moneyRequest.provider.businessNameRegistered,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.black,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 14,
                          color: Colors.amber[600],
                        ),
                        const SizedBox(width: 4),
                        const AppText(
                          '5.0 (55 reviews)',
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textcolor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Task description
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.textcolor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppText(
                  'Task: Accept Request from Jacob',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.black,
                ),
                const SizedBox(height: 4),
                AppText(
                  moneyRequest.description,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textcolor,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: Colors.red.shade400,
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Accept & pay',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
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

  static Widget fromMoneyRequest({
    required MoneyRequest moneyRequest,
    required VoidCallback onAccept,
    required VoidCallback onCancel,
  }) {
    return MoneyRequestCard(
      moneyRequest: moneyRequest,
      onAccept: onAccept,
      onCancel: onCancel,
    );
  }
}