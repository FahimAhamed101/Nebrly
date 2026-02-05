// controllers/notification_controller.dart
import 'package:get/get.dart';
import '../models/notification.dart';
import '../repositories/notification_repository.dart';

class NotificationController extends GetxController {
  final NotificationRepository _repository = NotificationRepository();

  final RxBool isLoading = false.obs;
  final RxBool isMarkingAsRead = false.obs;
  final RxBool isMarkingAllAsRead = false.obs;

  final RxList<NotificationItem> notifications = <NotificationItem>[].obs;
  final RxInt unreadCount = 0.obs;
  final RxInt expandedIndex = (-1).obs;

  // Group notifications by date
  final RxMap<String, List<NotificationItem>> groupedNotifications =
      <String, List<NotificationItem>>{}.obs;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    try {
      isLoading(true);
      final response = await _repository.getNotifications();
      notifications(response.data);

      // Count unread notifications
      unreadCount(notifications.where((n) => !n.isRead).length);

      // Group by date
      _groupNotifications();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to fetch notifications: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading(false);
    }
  }

  void _groupNotifications() {
    final Map<String, List<NotificationItem>> groups = {};

    for (final notification in notifications) {
      final dateKey = _formatDate(notification.createdAt);
      if (!groups.containsKey(dateKey)) {
        groups[dateKey] = [];
      }
      groups[dateKey]!.add(notification);
    }

    // Sort groups by date (newest first)
    final sortedGroups = Map.fromEntries(
        groups.entries.toList()
          ..sort((a, b) => b.value.first.createdAt.compareTo(a.value.first.createdAt))
    );

    groupedNotifications(sortedGroups);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final notificationDate = DateTime(date.year, date.month, date.day);

    if (notificationDate == today) {
      return 'Today';
    } else if (notificationDate == yesterday) {
      return 'Yesterday';
    } else {
      // Format: "15 Jan, 2016"
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${date.day} ${months[date.month - 1]}, ${date.year}';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour < 12 ? 'AM' : 'PM';
    return '${hour == 0 ? 12 : hour}:$minute $period';
  }

  String getNotificationTime(NotificationItem notification) {
    final now = DateTime.now();
    final notificationDate = notification.createdAt;
    final difference = now.difference(notificationDate);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return _formatTime(notificationDate);
    } else if (difference.inDays < 2) {
      return 'Yesterday';
    } else {
      return _formatDate(notificationDate);
    }
  }

  void toggleExpand(int index) {
    if (expandedIndex.value == index) {
      expandedIndex.value = -1;
    } else {
      expandedIndex.value = index;
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      isMarkingAsRead(true);
      await _repository.markAsRead(notificationId);

      // Update local state
      final index = notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        notifications[index] = notifications[index].copyWith(isRead: true);
        unreadCount(unreadCount.value - 1);
      }

      Get.snackbar(
        'Success',
        'Notification marked as read',
        snackPosition: SnackPosition.BOTTOM,

        duration: const Duration(seconds: 1),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to mark notification as read: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isMarkingAsRead(false);
    }
  }

  Future<void> markAllAsRead() async {
    try {
      isMarkingAllAsRead(true);
      await _repository.markAllAsRead();

      // Update local state
      for (var i = 0; i < notifications.length; i++) {
        if (!notifications[i].isRead) {
          notifications[i] = notifications[i].copyWith(isRead: true);
        }
      }
      unreadCount(0);

      Get.snackbar(
        'Success',
        'All notifications marked as read',
        snackPosition: SnackPosition.BOTTOM,

      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to mark all notifications as read: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isMarkingAllAsRead(false);
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _repository.deleteNotification(notificationId);

      // Update local state
      final wasUnread = notifications.firstWhere((n) => n.id == notificationId).isRead == false;
      notifications.removeWhere((n) => n.id == notificationId);

      if (wasUnread) {
        unreadCount(unreadCount.value - 1);
      }

      // Regroup notifications
      _groupNotifications();

      Get.snackbar(
        'Success',
        'Notification deleted',
        snackPosition: SnackPosition.BOTTOM,

        duration: const Duration(seconds: 1),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete notification: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void navigateToLink(String link) {
    // Handle navigation based on link
    // You might want to use Get.toNamed or custom navigation logic
    if (link.isNotEmpty) {
      Get.snackbar(
        'Navigation',
        'Would navigate to: $link',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}