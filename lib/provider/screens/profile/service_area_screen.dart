import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/service_area_controller.dart';
import '../../models/service_area_model.dart';


class ServiceAreaScreen extends StatelessWidget {
  ServiceAreaScreen({super.key});

  final ServiceAreaController controller = Get.put(ServiceAreaController());
  final TextEditingController _textEditingController = TextEditingController();

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
          "Service Area",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          Obx(() => TextButton(
            onPressed: controller.isSaving.value ? null : () => Get.back(),
            child: Text(
              "Save",
              style: TextStyle(
                color: controller.isSaving.value
                    ? Colors.grey
                    : const Color(0xFF0E7A60),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          )),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return _buildLoadingState();
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              // Zip Code Input Section
              _buildInputSection(),

              // Selected Areas List
              if (controller.serviceAreas.isNotEmpty)
                _buildSelectedAreasSection(),

              // Map Representation
              _buildMapSection(),

              const SizedBox(height: 20),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Color(0xFF0E7A60),
          ),
          SizedBox(height: 16),
          Text(
            "Loading service areas...",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Add Service Area",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _textEditingController,
            onChanged: (value) {
              controller.zipCodeInput(value);
              controller.searchZipCodes(value);
            },
            decoration: InputDecoration(
              hintText: "Enter zip code",
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
              suffixIcon: const Icon(
                Icons.search,
                color: Colors.grey,
              ),
            ),
          ),

          // Suggestions Dropdown
          Obx(() {
            if (!controller.showSuggestions.value) return const SizedBox();

            return Container(
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: controller.suggestions.map((suggestion) {
                  return ListTile(
                    title: Text(
                      '${suggestion.zipCode} - ${suggestion.city.isNotEmpty ? "${suggestion.city}, ${suggestion.state}" : suggestion.zipCode}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      onPressed: () => controller.selectSuggestion(suggestion),
                    ),
                    onTap: () => controller.selectSuggestion(suggestion),
                  );
                }).toList(),
              ),
            );
          }),

          // Add Button
          const SizedBox(height: 16),
          Obx(() => SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: controller.isSaving.value || controller.zipCodeInput.isEmpty
                  ? null
                  : () => controller.addServiceArea(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0E7A60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                disabledBackgroundColor: Colors.grey[400],
              ),
              child: controller.isSaving.value
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Text(
                "Add Zip Code",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSelectedAreasSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Selected Service Areas",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E7A60).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${controller.totalAreas.value} areas",
                  style: const TextStyle(
                    color: Color(0xFF0E7A60),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: controller.serviceAreas.map((area) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: area.isActive
                      ? const Color(0xFF0E7A60)
                      : const Color(0xFF6B7280),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    area.isActive
                        ? const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 14,
                    )
                        : const Icon(
                      Icons.pending,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      area.city.isNotEmpty
                          ? '${area.zipCode} - ${area.city}, ${area.state}'
                          : area.zipCode,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _showDeleteConfirmation(area),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    return Container(
      height: 300,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          // Map Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  "Service Coverage Map",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: controller.activeAreas.value > 0
                        ? const Color(0xFF0E7A60).withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "${controller.activeAreas.value} active",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: controller.activeAreas.value > 0
                          ? const Color(0xFF0E7A60)
                          : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Map Content
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map,
                    size: 64,
                    color: controller.serviceAreas.isNotEmpty
                        ? const Color(0xFF0E7A60).withOpacity(0.6)
                        : Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    controller.serviceAreas.isNotEmpty
                        ? "Service Areas: ${controller.serviceAreas.length}"
                        : "No Service Areas",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    controller.serviceAreas.isNotEmpty
                        ? controller.getCoverageSummary()
                        : "Add zip codes to define your service area",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (controller.serviceAreas.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0E7A60).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF0E7A60).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        "Green areas indicate your service coverage",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(ServiceAreaModel area) {
    Get.defaultDialog(
      title: "Remove Service Area",
      titleStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      content: Column(
        children: [
          Text(
            "Are you sure you want to remove ${area.zipCode}${area.city.isNotEmpty ? ' - ${area.city}, ${area.state}' : ''} from your service areas?",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          if (!area.isActive)
            const Text(
              "This area is currently inactive.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
      confirm: ElevatedButton(
        onPressed: () {
          Get.back();
          controller.removeServiceArea(area.id);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          "Remove",
          style: TextStyle(color: Colors.white),
        ),
      ),
      cancel: OutlinedButton(
        onPressed: () => Get.back(),
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text("Cancel"),
      ),
    );
  }
}