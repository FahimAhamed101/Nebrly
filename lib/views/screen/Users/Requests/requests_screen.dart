// views/screen/Users/Request/request_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:naibrly/utils/app_colors.dart';
import 'package:naibrly/utils/enums.dart';
import 'package:naibrly/views/base/AppText/appText.dart';
import 'package:naibrly/widgets/request_filter_tabs.dart';
import 'package:naibrly/widgets/user_request_card.dart';
import 'package:naibrly/views/screen/Users/Request/user_request_inbox_screen.dart';
import 'package:naibrly/widgets/payment_confirmation_bottom_sheet.dart';

import '../../../../controller/Customer/request_controller.dart';
import '../../../../models/user_request1.dart';

class RequestScreen extends StatelessWidget {
  RequestScreen({super.key});

  final RequestController controller = Get.find<RequestController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.White,
      appBar: AppBar(
        backgroundColor: AppColors.White,
        elevation: 0,
        title: const AppText(
          'My Requests',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.Black,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: AppColors.Black,
              size: 20,
            ),
            onPressed: () => controller.refreshRequests(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.allRequests.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (controller.errorMessage.isNotEmpty && controller.allRequests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppText(
                  'Error loading requests',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.DarkGray,
                ),
                const SizedBox(height: 8),
                AppText(
                  controller.errorMessage.value,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.DarkGray,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => controller.refreshRequests(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Filter tabs
            RequestFilterTabs(
              currentFilter: controller.currentFilter.value,
              onFilterChanged: (filter) => controller.changeFilter(filter),
              openCount: controller.openCount,
              closedCount: controller.closedCount,
            ),

            // Requests list
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await controller.refreshRequests();
                },
                child: controller.filteredRequests.isEmpty
                    ? _buildEmptyState()
                    : NotificationListener<ScrollNotification>(
                  onNotification: (scrollNotification) {
                    if (scrollNotification.metrics.pixels ==
                        scrollNotification.metrics.maxScrollExtent) {
                      controller.loadMore();
                    }
                    return false;
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: controller.filteredRequests.length +
                        (controller.hasMore.value ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == controller.filteredRequests.length) {
                        return controller.isLoading.value
                            ? const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                            : const SizedBox();
                      }

                      final request = controller.filteredRequests[index];
                      return UserRequestCard(
                        request: request,
                        onTap: () => _handleRequestTap(context, request),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: AppColors.DarkGray.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          const AppText(
            'No requests found',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.DarkGray,
          ),
          const SizedBox(height: 4),
          Obx(() {
            final filterText = controller.currentFilter.value == RequestFilter.open
                ? 'open'
                : 'closed';
            return AppText(
              'You don\'t have any $filterText requests yet',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.DarkGray,
            );
          }),
        ],
      ),
    );
  }

  void _handleRequestTap(BuildContext context, UserRequest request) {
    if (request.status.toLowerCase() == 'pending') {
      _showPendingRequestBottomSheet(context, request);
    } else {
      _navigateToRequestInbox(context, request);
    }
  }

  void _navigateToRequestInbox(BuildContext context, UserRequest request) {
    // Extract IDs from the request
    String? bundleId = request.isBundle ? request.id : null;
    String? requestId = !request.isBundle ? request.id : null;
    String? customerId = request.provider?.id;

    // Navigate to UserRequestInboxScreen with IDs
    Get.to(() => UserRequestInboxScreen(
      request: request,
      bundleId: bundleId,
      requestId: requestId,
      customerId: customerId,
    ));
  }

  void _showPendingRequestBottomSheet(BuildContext context, UserRequest request) {
    showPendingRequestBottomSheet(context, timeLimit: "16:30");
  }
}