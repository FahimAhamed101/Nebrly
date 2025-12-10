import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:naibrly/utils/app_colors.dart';
import 'package:naibrly/views/base/AppText/appText.dart';
import 'package:naibrly/views/base/Ios_effect/iosTapEffect.dart';
import 'package:naibrly/widgets/bundle_card.dart';
import 'package:naibrly/services/mock_data_service.dart';
import 'package:naibrly/views/screen/Users/Home/create_bundle_bottomsheet.dart';
import '../../../../controller/Customer/bundlesController/createBundle.dart';

class BundelsScreen extends StatefulWidget {
  const BundelsScreen({super.key});

  @override
  State<BundelsScreen> createState() => _BundelsScreenState();
}
class _BundelsScreenState extends State<BundelsScreen> {
  List<Map<String, dynamic>> categories = [];
  String selectedCategory = 'All';
  String selectedFilter1 = 'Interior';
  String selectedFilter2 = 'Home...';
  final CreateBundleController controller = Get.put(CreateBundleController());
  int? expandedIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.getNaibrlyBundle(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.White,
      appBar: AppBar(
        backgroundColor: AppColors.White,
        elevation: 0,
        title: const AppText(
          "Naibrly Bundles",
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              // Handle search action
            },
            icon: const Icon(Icons.search, color: Colors.black),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final bundleList = controller.bundles;

        if (bundleList.isEmpty) {
          return const Center(
            child: AppText(
              "No bundles available",
              fontSize: 16,
              color: Colors.grey,
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search bar
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          width: 0.8,
                          color: AppColors.textcolor.withOpacity(0.25),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        children: [
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              decoration: const InputDecoration(
                                hintText: "Home Repairs",
                                border: InputBorder.none,
                                isCollapsed: true,
                              ),
                              style: TextStyle(color: AppColors.textcolor),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 30,
                            color: AppColors.textcolor.withOpacity(0.4),
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          SvgPicture.asset("assets/icons/location.svg"),
                          Expanded(
                            child: TextFormField(
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: "Zip code",
                                border: InputBorder.none,
                                isCollapsed: true,
                                hintStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.black.withOpacity(0.50),
                                ),
                              ),
                              style: TextStyle(color: AppColors.textcolor),
                            ),
                          ),
                          Container(
                            width: 45,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                            ),
                            child: Center(
                              child: SvgPicture.asset("assets/icons/search-normal.svg"),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildFilterSection(),
                    const SizedBox(height: 20),

                    // Bundle Cards List
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: bundleList.length,
                      itemBuilder: (context, index) {
                        final bundle = bundleList[index];

                        final List<Map<String, dynamic>> participantList =
                        bundle.participants.map((participant) {
                          final customer = participant.customer;
                          return {
                            'name': '${customer.firstName} ${customer.lastName}',
                            'avatar': customer.profileImage.url,
                            'location': '${customer.address.city}, ${customer.address.state}',
                          };
                        }).toList();

                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index < bundleList.length - 1 ? 12 : 0,
                          ),
                          child: BundleCard(
                            bundleId: bundle.id,
                            loadingBundleId: controller.loadingBundleId,
                            serviceTitle: bundle.title,
                            originalPrice: '\$${(bundle.finalPrice / (1 - bundle.bundleDiscount / 100)).toStringAsFixed(0)}',
                            discountedPrice: '\$${bundle.finalPrice.toStringAsFixed(0)}',
                            savings: '-${(bundle.finalPrice * bundle.bundleDiscount / 100).toStringAsFixed(0)}',
                            providers: participantList,
                            benefits: bundle.services.map((s) => s.name).toList(),
                            participants: bundle.currentParticipants,
                            maxParticipants: bundle.maxParticipants,
                            serviceDate: bundle.serviceDate.toIso8601String().split('T').first,
                            discountPercentage: bundle.bundleDiscount,
                            publishedText: 'Published ${DateTime.now().difference(bundle.createdAt).inHours}hr ago',
                            isExpanded: expandedIndex == index,
                            onToggleExpansion: () {
                              setState(() {
                                expandedIndex = expandedIndex == index ? null : index;
                              });
                            },
                            onJoinBundle: () {
                              print("🎯 Join bundle button clicked for: ${bundle.id}");
                              print("Bundle title: ${bundle.title}");
                              print("Current participants: ${bundle.currentParticipants}/${bundle.maxParticipants}");
                              controller.joinNaibrlyBundle(context, bundle.id);
                            },
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // Create Bundle Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            useSafeArea: true,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => const CreateBundleBottomSheet(),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0E7A60),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          "Create Bundle",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildFilterSection() {
    return Row(
      children: [
        const AppText(
          "Naibrly Bundles",
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
        const Spacer(),
        Container(
          width: 100,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedFilter1,
              isDense: true,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.black),
              items: const [
                DropdownMenuItem(value: 'Interior', child: Text('Interior', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: 'Exterior', child: Text('Exterior', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: 'Maintenance', child: Text('Maintenance', style: TextStyle(fontSize: 12))),
              ],
              onChanged: (value) {
                setState(() {
                  selectedFilter1 = value!;
                });
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 100,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedFilter2,
              isDense: true,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.black),
              items: const [
                DropdownMenuItem(value: 'Home...', child: Text('Home...', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: 'Office', child: Text('Office', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: 'Commercial', child: Text('Commercial', style: TextStyle(fontSize: 12))),
              ],
              onChanged: (value) {
                setState(() {
                  selectedFilter2 = value!;
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}