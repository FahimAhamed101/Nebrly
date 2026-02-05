import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/payout_controller.dart';


class PayoutInformationScreen extends StatelessWidget {
  PayoutInformationScreen({super.key});

  final PayoutController controller = Get.put(PayoutController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          "Payout Information",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () => controller.fetchPayoutInformation(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF0E7A60),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Update payout information.",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                "Updating banking information requires admin approval.",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),

              _buildTextField(
                label: "Account Holder Name",
                controller: TextEditingController(text: controller.accountHolderName.value),
                onChanged: (value) => controller.accountHolderName.value = value,
              ),
              const SizedBox(height: 20),

              _buildBankDropdown(),
              const SizedBox(height: 20),

              _buildTextField(
                label: "Enter Your Bank Account Number",
                controller: TextEditingController(text: controller.accountNumber.value),
                onChanged: (value) => controller.accountNumber.value = value,
              ),
              const SizedBox(height: 20),

              _buildTextField(
                label: "Routing Number",
                controller: TextEditingController(text: controller.routingNumber.value),
                onChanged: (value) => controller.routingNumber.value = value,
              ),
              const SizedBox(height: 32),

              _buildSecurityBox(),
              const SizedBox(height: 32),

              _buildCurrentInformation(),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: Obx(() => ElevatedButton(
                  onPressed: controller.isUpdating.value
                      ? null
                      : () => controller.updatePayoutInformation(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0E7A60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    disabledBackgroundColor: Colors.grey[400],
                  ),
                  child: controller.isUpdating.value
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    "Update Request",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                )),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF0E7A60)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildBankDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Bank Name",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: controller.selectedBank.value.isEmpty
              ? null
              : controller.selectedBank.value,
          decoration: InputDecoration(
            hintText: "Choose your bank",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF0E7A60)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          items: const [
            DropdownMenuItem(value: "Bank of America", child: Text("Bank of America")),
            DropdownMenuItem(value: "JPMorgan Chase", child: Text("JPMorgan Chase")),
            DropdownMenuItem(value: "Wells Fargo", child: Text("Wells Fargo")),
            DropdownMenuItem(value: "Citibank", child: Text("Citibank")),
            DropdownMenuItem(value: "U.S. Bank", child: Text("U.S. Bank")),
            DropdownMenuItem(value: "PNC Bank", child: Text("PNC Bank")),
            DropdownMenuItem(value: "Capital One", child: Text("Capital One")),
            DropdownMenuItem(value: "TD Bank", child: Text("TD Bank")),
            DropdownMenuItem(value: "Other", child: Text("Other")),
          ],
          onChanged: (value) => controller.selectedBank.value = value ?? "",
        ),
      ],
    );
  }

  Widget _buildSecurityBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.people,
              color: Color(0xFF4CAF50),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Your information is secure.",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "We use bank-level encryption and Stripe to protect your payment information.",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentInformation() {
    if (controller.payoutInfo.value == null) return const SizedBox();

    final info = controller.payoutInfo.value!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Current Information",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow("Status", info.verificationStatus.toUpperCase(),
              info.isVerified ? Colors.green : Colors.orange),
          const SizedBox(height: 8),
          _buildInfoRow("Bank", info.bankName, Colors.black),
          const SizedBox(height: 8),
          _buildInfoRow("Account Holder", info.accountHolderName, Colors.black),
          const SizedBox(height: 8),
          _buildInfoRow("Account Type", info.accountType.toUpperCase(), Colors.black),
          const SizedBox(height: 8),
          _buildInfoRow("Last Updated",
              "${info.updatedAt.day}/${info.updatedAt.month}/${info.updatedAt.year}",
              Colors.grey),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}