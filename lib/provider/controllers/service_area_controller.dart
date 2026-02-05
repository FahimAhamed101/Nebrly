// controllers/service_area_controller.dart
import 'package:get/get.dart';
import '../models/service_area_model.dart';
import '../repositories/service_area_repository.dart';

class ServiceAreaController extends GetxController {
  final ServiceAreaRepository _repository = ServiceAreaRepository();

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool isRemoving = false.obs;

  final RxList<ServiceAreaModel> serviceAreas = <ServiceAreaModel>[].obs;
  final RxInt totalAreas = 0.obs;
  final RxInt activeAreas = 0.obs;

  // For search and suggestions
  final RxList<ServiceAreaModel> suggestions = <ServiceAreaModel>[].obs;
  final RxBool showSuggestions = false.obs;

  // For adding new area
  final RxString zipCodeInput = ''.obs;
  final RxString selectedZip = ''.obs;
  final RxString selectedCity = ''.obs;
  final RxString selectedState = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchServiceAreas();
  }

  Future<void> fetchServiceAreas() async {
    try {
      isLoading(true);
      final response = await _repository.getMyServiceAreas();
      serviceAreas(response.data.serviceAreas);
      totalAreas(response.data.totalAreas);
      activeAreas(response.data.activeAreas);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to fetch service areas: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> searchZipCodes(String query) async {
    if (query.length < 2) {
      suggestions.clear();
      showSuggestions(false);
      return;
    }

    try {
      // In a real app, you would call an API to search zip codes
      // For now, we'll simulate with local data
      await Future.delayed(const Duration(milliseconds: 300));

      // Simulated zip code data - replace with actual API call
      final simulatedData = [
        ServiceAreaModel(
          id: 'temp_${query}001',
          zipCode: '${query}01',
          city: 'City $query',
          state: 'ST',
          isActive: false,
          addedAt: DateTime.now(),
        ),
        ServiceAreaModel(
          id: 'temp_${query}002',
          zipCode: '${query}02',
          city: 'Town $query',
          state: 'ST',
          isActive: false,
          addedAt: DateTime.now(),
        ),
      ];

      suggestions(simulatedData);
      showSuggestions(suggestions.isNotEmpty);
    } catch (e) {
      suggestions.clear();
      showSuggestions(false);
    }
  }

  void selectSuggestion(ServiceAreaModel area) {
    selectedZip(area.zipCode);
    selectedCity(area.city);
    selectedState(area.state);
    zipCodeInput(area.zipCode);
    showSuggestions(false);
  }

  Future<void> addServiceArea() async {
    if (selectedZip.isEmpty || zipCodeInput.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter a valid zip code',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Check if already exists
    if (serviceAreas.any((area) => area.zipCode == selectedZip.value)) {
      Get.snackbar(
        'Notice',
        'This zip code is already in your service areas',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isSaving(true);
      await _repository.addServiceArea(
        zipCode: selectedZip.value,
        city: selectedCity.value,
        state: selectedState.value,
      );

      Get.snackbar(
        'Success',
        'Service area added successfully',
        snackPosition: SnackPosition.BOTTOM,

      );

      // Refresh the list
      await fetchServiceAreas();

      // Clear input
      clearInput();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to add service area: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSaving(false);
    }
  }

  Future<void> removeServiceArea(String areaId) async {
    try {
      isRemoving(true);
      await _repository.removeServiceArea(areaId);

      Get.snackbar(
        'Success',
        'Service area removed successfully',
        snackPosition: SnackPosition.BOTTOM,

      );

      // Refresh the list
      await fetchServiceAreas();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to remove service area: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isRemoving(false);
    }
  }

  void clearInput() {
    zipCodeInput('');
    selectedZip('');
    selectedCity('');
    selectedState('');
    suggestions.clear();
    showSuggestions(false);
  }

  String getCoverageSummary() {
    if (serviceAreas.isEmpty) return 'No service areas selected';

    final uniqueCities = serviceAreas
        .where((area) => area.city.isNotEmpty)
        .map((area) => area.city)
        .toSet();

    if (uniqueCities.isEmpty) {
      return 'Covering ${serviceAreas.length} zip codes';
    }

    final citiesList = uniqueCities.take(3).toList();
    final cityString = citiesList.join(', ');

    if (uniqueCities.length > 3) {
      return 'Covering $cityString and ${uniqueCities.length - 3} more areas';
    }

    return 'Covering $cityString';
  }
}