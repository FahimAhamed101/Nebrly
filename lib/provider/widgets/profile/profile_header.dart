// widgets/profile/profile_header.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/ProviderProfileController.dart';

class ProfileHeader extends StatelessWidget {
  final VoidCallback onWithdrawPressed;

  const ProfileHeader({
    super.key,
    required this.onWithdrawPressed,
  });

  @override
  Widget build(BuildContext context) {
    final ProviderProfileController controller = Get.find<ProviderProfileController>();

    return Obx(() {
      final user = controller.user.value;

      return Center(
        child: Column(
          children: [
            // Profile Image with Edit Icon
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[200],
                    border: Border.all(
                      color: Colors.green[300]!,
                      width: 3,
                    ),
                  ),
                  child: user?.profileImage != null
                      ? ClipOval(
                    child: Image.network(
                      user!.profileImage!,
                      width: 84,
                      height: 84,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.grey[500],
                          ),
                        );
                      },
                    ),
                  )
                      : Center(
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.edit,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Business Name
            Text(
              user?.businessNameRegistered ?? 'Jacob Brothers',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            // Owner Name
            if (user?.firstName != null && user?.lastName != null)
              const SizedBox(height: 5),
            if (user?.firstName != null && user?.lastName != null)
              Text(
                "By ${user!.firstName} ${user.lastName}",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),

            // Email (if business name not available)
            if ((user?.businessNameRegistered == null || user!.businessNameRegistered!.isEmpty) && user?.email != null)
              const SizedBox(height: 5),
            if ((user?.businessNameRegistered == null || user!.businessNameRegistered!.isEmpty) && user?.email != null)
              Text(
                user!.email,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

            const SizedBox(height: 15),

            // Balance and Withdraw Button
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Available Balance Card
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.green[300]!),
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.white,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "\$${(user?.availableBalance ?? 0).toStringAsFixed(2)}",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.green[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        "Available",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Withdraw Button (only show if can withdraw)
                if (controller.canWithdraw)
                  ElevatedButton(
                    onPressed: onWithdrawPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: Text(
                      "Withdraw",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),

            // Pending Balance (show below if exists)
            if ((user?.pendingPayout ?? 0) > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.orange[300]!),
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.orange[50],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "\$${(user?.pendingPayout ?? 0).toStringAsFixed(2)}",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "Pending Payout",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}