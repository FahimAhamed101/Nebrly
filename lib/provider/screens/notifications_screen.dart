import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../controllers/notification_controller.dart';
import '../models/notification.dart';

class NotificationsScreen extends StatelessWidget {
  NotificationsScreen({super.key});

  final NotificationController controller = Get.put(NotificationController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Obx(() => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/images/notification.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
            ),
            const SizedBox(width: 8),
            Text(
              'Notifications ${controller.unreadCount.value > 0 ? "(${controller.unreadCount.value})" : ""}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 16,
              ),
            ),
          ],
        )),
        centerTitle: true,
        actions: [
          if (controller.unreadCount.value > 0)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.black),
              onSelected: (value) {
                if (value == 'mark_all_read') {
                  controller.markAllAsRead();
                } else if (value == 'refresh') {
                  controller.fetchNotifications();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'mark_all_read',
                  child: Row(
                    children: [
                      Icon(Icons.mark_email_read, size: 20),
                      SizedBox(width: 8),
                      Text('Mark all as read'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'refresh',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, size: 20),
                      SizedBox(width: 8),
                      Text('Refresh'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return _buildLoadingState();
        }

        if (controller.notifications.isEmpty) {
          return _buildEmptyState();
        }

        return _buildNotificationsList();
      }),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 100,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/images/notification.svg',
            width: 64,
            height: 64,
            colorFilter: ColorFilter.mode(
              Colors.grey[400]!,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You\'ll see notifications here when you have them',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => controller.fetchNotifications(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0E7A60),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Refresh',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return RefreshIndicator(
      onRefresh: () => controller.fetchNotifications(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: controller.groupedNotifications.keys.length,
        itemBuilder: (context, groupIndex) {
          final dateKey = controller.groupedNotifications.keys.elementAt(groupIndex);
          final notifications = controller.groupedNotifications[dateKey]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  dateKey,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              ...notifications.asMap().entries.map((entry) {
                final index = entry.key;
                final notification = entry.value;
                final globalIndex = _calculateGlobalIndex(groupIndex, index);
                final isExpanded = controller.expandedIndex.value == globalIndex;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () {
                      controller.toggleExpand(globalIndex);
                      if (!notification.isRead) {
                        controller.markAsRead(notification.id);
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isExpanded ? Colors.grey[50] : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: isExpanded
                            ? Border.all(color: Colors.grey[300]!, width: 1)
                            : null,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _buildNotificationIcon(notification),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    notification.title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                _buildNotificationActions(notification),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.only(left: 28),
                              child: Text(
                                controller.getNotificationTime(notification),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            if (isExpanded) ...[
                              const SizedBox(height: 12),
                              Padding(
                                padding: const EdgeInsets.only(left: 28),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      notification.body,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[700],
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (notification.link.isNotEmpty)
                                      GestureDetector(
                                        onTap: () => controller.navigateToLink(notification.link),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0E7A60).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: const Color(0xFF0E7A60).withOpacity(0.3)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.open_in_new,
                                                size: 14,
                                                color: Color(0xFF0E7A60),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _getLinkLabel(notification.link),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF0E7A60),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotificationIcon(NotificationItem notification) {
    IconData icon;
    Color color;

    if (notification.title.toLowerCase().contains('message')) {
      icon = Icons.message;
      color = Colors.blue;
    } else if (notification.title.toLowerCase().contains('request')) {
      icon = Icons.request_page;
      color = Colors.orange;
    } else if (notification.title.toLowerCase().contains('review')) {
      icon = Icons.star;
      color = Colors.yellow[700]!;
    } else if (notification.title.toLowerCase().contains('money')) {
      icon = Icons.monetization_on;
      color = Colors.green;
    } else if (notification.title.toLowerCase().contains('bundle')) {
      icon = Icons.inventory;
      color = Colors.purple;
    } else {
      icon = Icons.notifications;
      color = notification.isRead ? Colors.grey[400]! : Colors.red;
    }

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.grey[400] : color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildNotificationActions(NotificationItem notification) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
      onSelected: (value) {
        if (value == 'mark_read' && !notification.isRead) {
          controller.markAsRead(notification.id);
        } else if (value == 'delete') {
          _showDeleteConfirmation(notification);
        }
      },
      itemBuilder: (context) => [
        if (!notification.isRead)
          const PopupMenuItem(
            value: 'mark_read',
            child: Row(
              children: [
                Icon(Icons.mark_email_read, size: 18),
                SizedBox(width: 8),
                Text('Mark as read'),
              ],
            ),
          ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete'),
            ],
          ),
        ),
      ],
    );
  }

  String _getLinkLabel(String link) {
    if (link.contains('/message/')) {
      return 'View Message';
    } else if (link.contains('/analytics')) {
      return 'View Analytics';
    } else {
      return 'View Details';
    }
  }

  int _calculateGlobalIndex(int groupIndex, int itemIndex) {
    int globalIndex = 0;
    for (int i = 0; i < groupIndex; i++) {
      final key = controller.groupedNotifications.keys.elementAt(i);
      globalIndex += controller.groupedNotifications[key]!.length;
    }
    return globalIndex + itemIndex;
  }

  void _showDeleteConfirmation(NotificationItem notification) {
    Get.defaultDialog(
      title: "Delete Notification",
      titleStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      content: Column(
        children: [
          Text(
            "Are you sure you want to delete this notification?",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            notification.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
      confirm: ElevatedButton(
        onPressed: () {
          Get.back();
          controller.deleteNotification(notification.id);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          "Delete",
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