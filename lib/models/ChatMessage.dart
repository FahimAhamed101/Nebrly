// Add this to your ChatMessage class (at the end of user_request_inbox_screen.dart)

class ChatMessage {
  final String text;
  final bool isFromUser;
  final bool isFromProvider;
  final DateTime timestamp;
  final String? senderId;
  final bool isQuickChat;
  final bool isPending; // For optimistic UI updates

  ChatMessage({
    required this.text,
    this.isFromUser = false,
    this.isFromProvider = false,
    required this.timestamp,
    this.senderId,
    this.isQuickChat = false,
    this.isPending = false,
  });

  // Create from socket message data
  factory ChatMessage.fromSocketData(Map<String, dynamic> data) {
    return ChatMessage(
      text: data['content']?.toString() ?? '',
      isFromUser: data['senderRole'] == 'customer',
      isFromProvider: data['senderRole'] == 'provider',
      timestamp: data['timestamp'] != null
          ? DateTime.parse(data['timestamp'])
          : DateTime.now(),
      senderId: data['senderId']?.toString(),
      isQuickChat: data['isQuickChat'] == true || data['quickChatId'] != null,
      isPending: false,
    );
  }

  // Copy with updated fields
  ChatMessage copyWith({
    String? text,
    bool? isFromUser,
    bool? isFromProvider,
    DateTime? timestamp,
    String? senderId,
    bool? isQuickChat,
    bool? isPending,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      isFromUser: isFromUser ?? this.isFromUser,
      isFromProvider: isFromProvider ?? this.isFromProvider,
      timestamp: timestamp ?? this.timestamp,
      senderId: senderId ?? this.senderId,
      isQuickChat: isQuickChat ?? this.isQuickChat,
      isPending: isPending ?? this.isPending,
    );
  }
}