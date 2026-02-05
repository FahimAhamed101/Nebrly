import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/payout_information_model.dart';
import '../../screens/profile/payout_information_screen.dart';
import '../../controllers/payout_controller.dart';

class PayoutInformationSection extends StatelessWidget {
  const PayoutInformationSection({super.key});

  @override
  Widget build(BuildContext context) {
    final PayoutController controller = Get.find<PayoutController>();

    return Obx(() {
      if (controller.isLoading.value && !controller.hasPayoutSetup.value) {
        return _buildLoadingState();
      }

      if (!controller.hasPayoutSetup.value) {
        return _buildNoPayoutSetupState(context);
      }

      final payoutInfo = controller.payoutInfo.value;
      if (payoutInfo == null) {
        return _buildNoPayoutSetupState(context);
      }

      return _buildPayoutInfoContent(context, payoutInfo);
    });
  }

  Widget _buildLoadingState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitleLoading(),
        const SizedBox(height: 15),
        _buildPayoutInfoLoading(),
        _buildPayoutInfoLoading(),
        _buildPayoutInfoLoading(),
        _buildPayoutInfoLoading(),
      ],
    );
  }

  Widget _buildNoPayoutSetupState(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, "Payout Information", "Setup"),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: Colors.grey[400],
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                "No payout information setup",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Setup your banking information to receive payments",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPayoutInfoContent(BuildContext context, PayoutInformationModel payoutInfo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, "Payout Information", "Edit"),
        const SizedBox(height: 15),
        _buildPayoutInfo(context, "Account Holder", payoutInfo.accountHolderName),
        _buildPayoutInfo(context, "Bank Account Number",
            "••••••••${payoutInfo.lastFourDigits}"),
        _buildPayoutInfo(context, "Bank Name", payoutInfo.bankName),
        _buildPayoutInfo(context, "Routing Number", payoutInfo.routingNumber),
        _buildPayoutInfo(context, "Account Type",
            payoutInfo.accountType.capitalizeFirst ?? "Checking"),
        const SizedBox(height: 10),
        Text(
          "Updating banking information requires admin approval.",
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 15),
        _buildStatusBadge(payoutInfo.verificationStatus, payoutInfo.isVerified),
      ],
    );
  }

  Widget _buildPayoutInfo(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              "$label:",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.black87,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
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
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        TextButton(
          onPressed: () {
            Get.to(() =>  PayoutInformationScreen());
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
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitleLoading() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: 150,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        Container(
          width: 60,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }

  Widget _buildPayoutInfoLoading() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              height: 16,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
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

  Widget _buildStatusBadge(String status, bool isVerified) {
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    String statusText;
    IconData? icon;

    switch (status.toLowerCase()) {
      case 'verified':
        backgroundColor = const Color(0xFFE8F5E8);
        borderColor = const Color(0xFF4CAF50);
        textColor = const Color(0xFF2E7D32);
        statusText = "Verified";
        icon = Icons.check_circle_outline;
        break;
      case 'pending':
        backgroundColor = const Color(0xFFFFF8E1);
        borderColor = const Color(0xFFFF9800);
        textColor = const Color(0xFFF57C00);
        statusText = "Pending Approval";
        icon = Icons.access_time;
        break;
      case 'rejected':
        backgroundColor = const Color(0xFFFFEBEE);
        borderColor = const Color(0xFFF44336);
        textColor = const Color(0xFFD32F2F);
        statusText = "Rejected";
        icon = Icons.error_outline;
        break;
      default:
        backgroundColor = Colors.grey[100]!;
        borderColor = Colors.grey[400]!;
        textColor = Colors.grey[700]!;
        statusText = status.capitalizeFirst ?? status;
        icon = Icons.help_outline;
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: textColor,
                size: 16,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              statusText,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}