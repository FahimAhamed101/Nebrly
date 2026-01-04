import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';
import '../../controllers/orders_controller.dart';
import '../../models/order.dart';
import '../../widgets/orders/order_card.dart';
import '../../widgets/orders/filter_tabs.dart';
import 'package:naibrly/widgets/payment_confirmation_bottom_sheet.dart';
import '../../widgets/colors.dart';
import 'package:naibrly/provider/widgets/naibrly_request_bottom_sheet.dart';
import '../../screens/order_inbox_screen.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<OrdersController>(
      init: OrdersController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: KoreColors.background,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                color: Colors.black,
                size: 20,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Your Orders',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.black,
                fontSize: 18,
              ),
            ),
            centerTitle: false,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: ElevatedButton(
                  onPressed: () => _showNaibrlyRequestBottomSheet(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0E7A60),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Naibrly Request',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Obx(() {
            if (controller.isLoading.value) {
              return _buildLoadingState(context);
            }

            if (controller.errorMessage.value.isNotEmpty) {
              return _buildErrorState(context, controller);
            }

            return RefreshIndicator(
              onRefresh: () => controller.refreshOrders(),
              child: Column(
                children: [
                  // Filter tabs
                  Obx(() => FilterTabs(
                    currentFilter: controller.currentFilter.value,
                    onFilterChanged: (filter) => controller.setFilter(filter),
                    openCount: controller.openOrdersCount,
                    closedCount: controller.closedOrdersCount,
                  )),

                  // Orders list
                  Expanded(
                    child: Obx(() {
                      final orders = controller.orders;

                      if (orders.isEmpty) {
                        return _buildEmptyState(context, controller);
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          return OrderCard(
                            order: order,
                            onTap: () => _showOrderDetails(context, order, controller),
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),
            );
          }),
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
            Text('Loading orders...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, OrdersController controller) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading orders',
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
            onPressed: () => controller.loadOrders(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, OrdersController controller) {
    final filterText = controller.currentFilter.value == OrderFilter.open
        ? 'open'
        : 'closed';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: KoreColors.textLight.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'No orders found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: KoreColors.textLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'You don\'t have any $filterText orders yet',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: KoreColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(BuildContext context, Order order, OrdersController controller) {
    if (order.status == OrderStatus.pending) {
      showOrderDetailsBottomSheet(
        context,
        orderData: {
          'id': order.id,
          'status': order.status.toString().split('.').last,
          'customer': order.clientName,
          'service': order.serviceName,
          'amount': order.averagePrice.toString(),
          'date': order.date.toString(),
          'notes': order.problemDescription,
        },
      );
    } else if (order.status == OrderStatus.accepted ||
        order.status == OrderStatus.cancelled ||
        order.status == OrderStatus.completed) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => OrderInboxScreen(order: order),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order details for ${order.serviceName} (${order.statusText})'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showNaibrlyRequestBottomSheet(BuildContext context) {
    showNaibrlyRequestBottomSheet(
      context,
      initialLocationEnabled: false,
      initialSelectedMiles: 3,
      onLocationChanged: (value) {},
      onMilesChanged: (value) {},
      onSend: () {},
    );
  }
}