// lib/widgets/socket_debug_widget.dart
// Add this temporarily to debug socket connections

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../controller/socket_controller.dart';


class SocketDebugWidget extends StatelessWidget {
  const SocketDebugWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final socketController = Get.find<SocketController>();

    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Obx(() => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: socketController.isConnected
                      ? Colors.green
                      : Colors.red,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                socketController.isConnected
                    ? 'Socket Connected'
                    : 'Socket Disconnected',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Active Conversations: ${socketController.messages.length}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
          if (!socketController.isConnected) ...[
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => socketController.reconnect(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
              ),
              child: const Text(
                'Reconnect',
                style: TextStyle(fontSize: 10),
              ),
            ),
          ],
        ],
      )),
    );
  }
}

// Add this to the top of your UserRequestInboxScreen widget tree for debugging:
// Stack(
//   children: [
//     // Your existing content
//     Positioned(
//       top: 100,
//       right: 16,
//       child: SocketDebugWidget(),
//     ),
//   ],
// )