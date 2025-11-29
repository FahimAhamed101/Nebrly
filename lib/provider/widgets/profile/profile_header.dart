// widgets/profile/profile_header.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/ProviderProfileController.dart';


class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final ProviderProfileController controller = Get.find<ProviderProfileController>();

    return Obx(() {
      final user = controller.user.value;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),

        ),
        child: Row(
          children: [
            // Profile Image
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey[300],
              backgroundImage: user?.profileImage != null
                  ? NetworkImage(user!.profileImage!)
                  : null,
              child: user?.profileImage == null
                  ? const Icon(Icons.person, color: Colors.white, size: 30)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.businessNameRegistered ?? 'Loading...',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildBalanceCard(
                        context,
                        'Available',
                        '\$${(user?.availableBalance ?? 0).toStringAsFixed(2)}',
                        Colors.green,
                      ),
                      const SizedBox(width: 8),
                      _buildBalanceCard(
                        context,
                        'Pending',
                        '\$${(user?.pendingPayout ?? 0).toStringAsFixed(2)}',
                        Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (controller.canWithdraw)
              IconButton(
                onPressed: () => {},
                icon: const Icon(Icons.arrow_forward_ios_rounded),
                tooltip: 'Withdraw',
              ),
          ],
        ),
      );
    });
  }

  Widget _buildBalanceCard(BuildContext context, String title, String amount, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              amount,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }




}