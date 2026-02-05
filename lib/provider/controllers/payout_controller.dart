// controllers/payout_controller.dart
import 'package:get/get.dart';
import '../models/payout_information_model.dart';
import '../repositories/payout_repository.dart';

class PayoutController extends GetxController {
  final PayoutRepository _repository = PayoutRepository();

  final RxBool isLoading = false.obs;
  final RxBool isUpdating = false.obs;
  final Rx<PayoutInformationModel?> payoutInfo = Rx<PayoutInformationModel?>(null);
  final RxBool hasPayoutSetup = false.obs;

  final RxString selectedBank = ''.obs;

  // For editing
  final accountHolderName = ''.obs;
  final accountNumber = ''.obs;
  final routingNumber = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPayoutInformation();
  }

  Future<void> fetchPayoutInformation() async {
    try {
      isLoading(true);
      final response = await _repository.getPayoutInformation();
      hasPayoutSetup(response.data.hasPayoutSetup);

      if (response.data.hasPayoutSetup) {
        payoutInfo(response.data.payoutInformation);
        // Set form values
        accountHolderName(response.data.payoutInformation.accountHolderName);
        selectedBank(response.data.payoutInformation.bankName);
        accountNumber(response.data.payoutInformation.accountNumber);
        routingNumber(response.data.payoutInformation.routingNumber);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to fetch payout information: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> updatePayoutInformation() async {
    if (selectedBank.isEmpty) {
      Get.snackbar(
        'Error',
        'Please select a bank',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (accountHolderName.isEmpty ||
        accountNumber.isEmpty ||
        routingNumber.isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill all fields',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isUpdating(true);
      await _repository.updatePayoutInformation(
        accountHolderName: accountHolderName.value,
        bankName: selectedBank.value,
        accountNumber: accountNumber.value,
        routingNumber: routingNumber.value,
      );

      Get.snackbar(
        'Success',
        'Payout information updated successfully',
        snackPosition: SnackPosition.BOTTOM,

      );

      // Refresh data
      await fetchPayoutInformation();

      // Navigate back
      Get.back();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update payout information: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isUpdating(false);
    }
  }
}