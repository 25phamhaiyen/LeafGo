import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chat/chat_models.dart';
import 'chat_service.dart';

class ChatNotificationManager {
  // Singleton pattern
  static final ChatNotificationManager _instance =
      ChatNotificationManager._internal();
  factory ChatNotificationManager() => _instance;
  ChatNotificationManager._internal();

  final ChatService _chatService = ChatService();
  StreamSubscription<List<ChatMessage>>? _messagesSubscription;

  String? _currentRideId;
  String? _currentUserId;

  // Track unread counts for rides
  final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

  // To avoid notifying old messages when first subscribing
  DateTime? _initialSubscriptionTime;
  final Set<String> _notifiedMessageIds = {};

  // Boolean state to know if the user is currently inside the chat screen
  bool isChatActive = false;

  void _updateUnreadCount(int value) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unreadCountNotifier.value = value;
    });
  }

  void _incrementUnreadCount() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unreadCountNotifier.value += 1;
    });
  }

  void startListening(
    String rideId,
    String currentUserId,
    BuildContext context,
  ) {
    if (_currentRideId == rideId && _currentUserId == currentUserId) {
      return; // Already listening to this ride with this user
    }

    stopListening();

    _currentRideId = rideId;
    _currentUserId = currentUserId;
    _initialSubscriptionTime = DateTime.now();
    _notifiedMessageIds.clear();
    _updateUnreadCount(0);

    _messagesSubscription = _chatService.getMessages(rideId).listen((messages) {
      if (messages.isEmpty) return;

      bool hasNewIncoming = false;
      ChatMessage? newestMessage;

      for (var message in messages) {
        // Skip messages sent by current user
        if (message.senderId == currentUserId) {
          _notifiedMessageIds.add(message.id);
          continue;
        }

        // Skip messages that we already processed/notified
        if (_notifiedMessageIds.contains(message.id)) continue;

        // If it's the very first snapshot, register all existing messages as read
        if (_initialSubscriptionTime != null &&
            message.timestamp.isBefore(_initialSubscriptionTime!)) {
          _notifiedMessageIds.add(message.id);
          continue;
        }

        // This is a brand new incoming message!
        _notifiedMessageIds.add(message.id);
        hasNewIncoming = true;
        if (newestMessage == null ||
            message.timestamp.isAfter(newestMessage.timestamp)) {
          newestMessage = message;
        }
      }

      // If there is a new incoming message and chat is not currently open
      if (hasNewIncoming && newestMessage != null) {
        if (!isChatActive) {
          _incrementUnreadCount();

          // Show beautiful floating In-App Notification SnackBar
          _showNotificationBanner(context, newestMessage.text);
        }
      }

      // Once the first snapshot is processed, we don't need _initialSubscriptionTime anymore
      _initialSubscriptionTime = null;
    });
  }

  void stopListening() {
    _messagesSubscription?.cancel();
    _messagesSubscription = null;
    _currentRideId = null;
    _currentUserId = null;
    _updateUnreadCount(0);
    _notifiedMessageIds.clear();
  }

  void enterChat() {
    isChatActive = true;
    _updateUnreadCount(0);
  }

  void exitChat() {
    isChatActive = false;
  }

  void _showNotificationBanner(BuildContext context, String messageText) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_rounded,
              color: Color(0xFF10B981),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tin nhắn mới',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF111827),
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  messageText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFFAFAFA),
      duration: const Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).size.height - 130,
        left: 16,
        right: 16,
      ),
    );

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

// Custom spelling fallback extension if needed, but we'll use normal colors.
extension on TextStyle {
  TextStyle get whiteee => copyWith(color: Colors.white70);
}
