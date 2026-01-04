import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/user_model_provider.dart';
import '../../controllers/ProviderProfileController.dart';

class ProfileHeader extends StatelessWidget {
  final VoidCallback onWithdrawPressed;

  // Add a parameter to control which image to show first
  final bool showBusinessLogoFirst;

  const ProfileHeader({
    super.key,
    required this.onWithdrawPressed,
    this.showBusinessLogoFirst = true, // Default to showing business logo first
  });

  @override
  Widget build(BuildContext context) {
    final ProviderProfileController controller = Get.find<ProviderProfileController>();

    return Obx(() {
      final user = controller.user.value;
      final hasBusinessLogo = user?.businessLogo != null && user!.businessLogo!.isNotEmpty;
      final hasProfileImage = user?.profileImage != null && user!.profileImage!.isNotEmpty;

      // Determine which image to show
      final primaryImageUrl = showBusinessLogoFirst && hasBusinessLogo
          ? user.businessLogo
          : (hasProfileImage ? user.profileImage : null);

      final secondaryImageUrl = showBusinessLogoFirst && hasBusinessLogo
          ? (hasProfileImage ? user.profileImage : null)
          : (hasBusinessLogo ? user.businessLogo : null);

      return Center(
        child: Column(
          children: [
            // Business Logo & Profile Image Stack
            if (primaryImageUrl != null || secondaryImageUrl != null)
              _buildImageStack(
                context: context,
                primaryImageUrl: primaryImageUrl,
                secondaryImageUrl: secondaryImageUrl,
                user: user,
                showBusinessLogoFirst: showBusinessLogoFirst,
              )
            else
            // Fallback when no images
              _buildPlaceholderImage(context),

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

            // Show image indicator if both logo and profile image exist
            if (hasBusinessLogo && hasProfileImage)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            showBusinessLogoFirst ? Icons.business : Icons.person,
                            size: 12,
                            color: Colors.green[600],
                          ),
                          const SizedBox(width: 4),

                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Rest of your existing code...
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

                // Withdraw Button
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

            // Pending Balance
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

  // Helper method to build the image stack
  Widget _buildImageStack({
    required BuildContext context,
    required String? primaryImageUrl,
    required String? secondaryImageUrl,
    required UserModel? user,
    required bool showBusinessLogoFirst,
  }) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Primary Image (Business Logo or Profile)
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
          child: ClipOval(
            child: Image.network(
              primaryImageUrl!,
              width: 84,
              height: 84,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback to secondary image if primary fails
                return secondaryImageUrl != null
                    ? Image.network(
                  secondaryImageUrl,
                  width: 84,
                  height: 84,
                  fit: BoxFit.cover,
                )
                    : _buildPlaceholderIcon();
              },
            ),
          ),
        ),

        // Secondary Image Badge (if both images exist)
        if (secondaryImageUrl != null)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.green[300]!,
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: Image.network(
                  secondaryImageUrl,
                  width: 28,
                  height: 28,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Icon(
                        showBusinessLogoFirst ? Icons.person : Icons.business,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

        // Edit Icon

      ],
    );
  }

  // Placeholder when no images
  Widget _buildPlaceholderImage(BuildContext context) {
    return Container(
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
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business,
              size: 30,
              color: Colors.grey[500],
            ),
            const SizedBox(height: 4),
            Text(
              "No Logo",
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fallback icon
  Widget _buildPlaceholderIcon() {
    return Center(
      child: Icon(
        Icons.person,
        size: 40,
        color: Colors.grey[500],
      ),
    );
  }
}