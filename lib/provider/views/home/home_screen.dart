// screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/home_controller.dart';
import '../../widgets/colors.dart';
import '../../widgets/home/analytics_section.dart';
import '../../widgets/home/client_feedback_section.dart';
import '../../widgets/home/provider_header.dart';
import '../../widgets/home/request_card.dart';

class ProviderHomeScreen extends StatelessWidget {
  const ProviderHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProviderHomeController>(
      init: ProviderHomeController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: KoreColors.background,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () => controller.refreshData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Provider header (always show)
                    const ProviderHeader(),

                    // Loading state
                    Obx(() {
                      if (controller.isLoading.value) {
                        return _buildLoadingState(context);
                      }

                      // Error state
                      if (controller.errorMessage.value.isNotEmpty) {
                        return _buildErrorState(context, controller);
                      }

                      // Data state - show content with conditional layout
                      return Column(
                        children: [
                          // Conditional layout based on active requests
                          if (controller.activeRequests.isNotEmpty) ...[
                            // Active requests section (if there are incoming requests)
                            _buildActiveRequestsSection(context, controller),

                            // Analytics section
                            AnalyticsSection(analytics: controller.analytics.value),

                            // Accepted requests list
                            _buildAcceptedRequestsSection(context, controller),
                          ] else ...[
                            // Analytics section first (if no incoming requests)
                            AnalyticsSection(analytics: controller.analytics.value),

                            // Accepted requests list
                            _buildAcceptedRequestsSection(context, controller),
                          ],

                          // Client feedback section
                          ClientFeedbackSection(
                            feedbackList: controller.clientFeedback,
                            onToggleExpansion: (feedbackId) {
                              controller.toggleFeedbackExpansion(feedbackId);
                            },
                            onLoadMore: () {
                              controller.loadMoreFeedback();
                            },
                          ),

                          const SizedBox(height: 20),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(40),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading requests...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, ProviderHomeController controller) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading data',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            controller.errorMessage.value,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => controller.loadHomeData(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveRequestsSection(BuildContext context, ProviderHomeController controller) {
    return Obx(() {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Active Requests',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w400,
                  color: KoreColors.textDark,
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (controller.activeRequests.isEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'No active requests',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: KoreColors.textLight,
                    ),
                  ),
                ),
              )
            else
              ...controller.activeRequests.map((request) => RequestCard(
                request: request,
                onAccept: () => controller.acceptRequest(request.id),
                onCancel: () => controller.cancelRequest(request.id),
              )),
          ],
        ),
      );
    });
  }

  Widget _buildAcceptedRequestsSection(BuildContext context, ProviderHomeController controller) {
    return Obx(() {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Accepted Requests1',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w400,
                  color: KoreColors.textDark,
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (controller.acceptedRequests.isEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'No accepted requests',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: KoreColors.textLight,
                    ),
                  ),
                ),
              )
            else
              ...controller.acceptedRequests.map((request) => RequestCard(
                request: request,
                onAccept: () => controller.acceptRequest(request.id),
                onCancel: () => controller.cancelRequest(request.id),
              )),
          ],
        ),
      );
    });
  }
}