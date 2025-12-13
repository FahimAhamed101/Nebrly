// controllers/orders_controller.dart
import 'package:get/get.dart';
import '../models/order.dart';
import '../services/orders_api_service.dart';

enum OrderFilter { open, closed }

class OrdersController extends GetxController {
  final RxList<Order> allOrders = <Order>[].obs;
  final Rx<OrderFilter> currentFilter = OrderFilter.open.obs;
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    print('🚀 OrdersController initialized');
    loadOrders();
  }

  // Computed properties
  List<Order> get orders {
    switch (currentFilter.value) {
      case OrderFilter.open:
        return allOrders.where((order) =>
        order.status == OrderStatus.pending ||
            order.status == OrderStatus.accepted
        ).toList();
      case OrderFilter.closed:
        return allOrders.where((order) =>
        order.status == OrderStatus.completed ||
            order.status == OrderStatus.cancelled
        ).toList();
    }
  }

  int get openOrdersCount => allOrders.where((order) =>
  order.status == OrderStatus.pending ||
      order.status == OrderStatus.accepted
  ).length;

  int get closedOrdersCount => allOrders.where((order) =>
  order.status == OrderStatus.completed ||
      order.status == OrderStatus.cancelled
  ).length;

  Future<void> loadOrders() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      print('🔄 Loading orders from API...');

      final orders = await Get.find<OrdersApiService>().getOrders();

      print('✅ API returned ${orders.length} orders');

      allOrders.assignAll(orders);

      print('✅ Orders loaded successfully');
      print('📊 Open orders: $openOrdersCount');
      print('📊 Closed orders: $closedOrdersCount');

    } catch (e) {
      errorMessage.value = 'Failed to load orders: ${e.toString()}';
      print('❌ Error loading orders: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void setFilter(OrderFilter filter) {
    print('🔄 Changing filter to: $filter');
    currentFilter.value = filter;
  }

  void updateOrderStatus(String orderId, OrderStatus newStatus) {
    final orderIndex = allOrders.indexWhere((order) => order.id == orderId);
    if (orderIndex != -1) {
      final order = allOrders[orderIndex];
      allOrders[orderIndex] = Order(
        id: order.id,
        serviceName: order.serviceName,
        averagePrice: order.averagePrice,
        date: order.date,
        time: order.time,
        imagePath: order.imagePath,
        status: newStatus,
        problemDescription: order.problemDescription,
        clientName: order.clientName,
        clientImage: order.clientImage,
        clientRating: order.clientRating,
        clientReviewCount: order.clientReviewCount,
        address: order.address,
        isTeamService: order.isTeamService,
        teamMembers: order.teamMembers,
        bundleType: order.bundleType,
      );
      print('✅ Order $orderId status updated to $newStatus');
    }
  }

  Future<void> refreshOrders() async {
    print('🔄 Refreshing orders...');
    await loadOrders();
  }
}