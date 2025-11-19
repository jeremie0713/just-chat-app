import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:just_chat_app/controllers/auth_controller.dart';
import 'package:just_chat_app/models/message_model.dart';
import 'package:just_chat_app/models/user_model.dart';
import 'package:just_chat_app/services/firestore_service.dart';
import 'package:uuid/uuid.dart';

class ChatController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController messageController = TextEditingController();
  final FocusNode messageFocusNode = FocusNode();
  final Uuid _uuid = Uuid();

  ScrollController? _scrollController;
  ScrollController get scrollController {
    _scrollController ??= ScrollController();
    return _scrollController!;
  }

  final RxList<MessageModel> _messages = <MessageModel>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _error = ''.obs;
  final RxBool _isSending = false.obs;
  final Rx<UserModel?> _otherUser = Rx<UserModel?>(null);
  final RxString _chatId = ''.obs;
  final RxBool _isTyping = false.obs;
  final RxBool _isChatActive = false.obs;

  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  bool get isSending => _isSending.value;
  UserModel? get otherUser => _otherUser.value;
  String get chatId => _chatId.value;
  bool get isTyping => _isTyping.value;

  @override
  void onInit() {
    super.onInit();
    _initializeChat();
    
    // Listen to text changes to update typing state
    messageController.addListener(() {
      final hasText = messageController.text.trim().isNotEmpty;
      if (_isTyping.value != hasText) {
        _isTyping.value = hasText;
      }
    });
    
    // Auto-scroll when keyboard appears
    messageFocusNode.addListener(() {
      if (messageFocusNode.hasFocus) {
        Future.delayed(Duration(milliseconds: 300), () {
          _scrollToBottom();
        });
      }
    });
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    _isChatActive.value = false;
    _markMessagesAsRead();
    super.onClose();
  }

  void _initializeChat() {
    final arguments = Get.arguments;
    if (arguments != null) {
      _chatId.value = arguments['chatId'] ?? '';
      _otherUser.value = arguments['otherUser'];
      _loadMessages();
      _markMessagesAsRead();
    }
  }

  void _loadMessages() {
    final currentUserId = _authController.user?.uid;
    final otherUserId = _otherUser.value?.id;

    if (currentUserId != null && otherUserId != null) {
      _messages.bindStream(
        _firestoreService.getChatMessagesStream(currentUserId, otherUserId),
      );

      ever(_messages, (List<MessageModel> messageList) {
        if (_isChatActive.value) {
          _markUnReadMessagesAsRead(messageList);
        }

        _scrollToBottom();
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController != null && _scrollController!.hasClients) {
        _scrollController!.animateTo(
          0.0, // Scroll to top since list is reversed
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _markUnReadMessagesAsRead(List<MessageModel> messageList) async {
    final currentUserId = _authController.user?.uid;
    if (currentUserId == null) return;

    try {
      final unreadMessages =
          messageList
              .where(
                (message) =>
                    message.receiverId == currentUserId &&
                    !message.isRead &&
                    message.senderId != currentUserId,
              )
              .toList();

      for (var message in unreadMessages) {
        await _firestoreService.markMessageAsRead(message.id);
      }

      if (unreadMessages.isNotEmpty && _chatId.value.isNotEmpty) {
        await _firestoreService.restoreUnreadCount(
          _chatId.value,
          currentUserId,
        );
      }

      if (_chatId.value.isNotEmpty) {
        await _firestoreService.updateUserLastSeen(
          _chatId.value,
          currentUserId,
        );
      }
    } catch (e) {
      print('Error marking messages as read: ${e.toString()}');
    }
  }

  Future<void> deleteChat() async {
    try {
      final currentUserId = _authController.user?.uid;
      if (currentUserId == null || _chatId.value.isEmpty) return;

      final result = await Get.dialog<bool>(
        AlertDialog(
          title: Text('Delete Chat'),
          content: Text(
            'Are you sure you want to delete this chat? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (result == true) {
        _isLoading.value = true;
        await _firestoreService.deleteChatForUser(_chatId.value, currentUserId);

        Get.delete<ChatController>(tag: _chatId.value);
        Get.back(); // Close the chat screen
        Get.snackbar('Success', 'Chat deleted successfully');
      }
    } catch (e) {
      print('Error deleting chat: ${e.toString()}');
      Get.snackbar('Error', 'Failed to delet chat');
    } finally {
      _isLoading.value = false;
    }
  }



  Future<void> sendMessage() async {
    final currentUserId = _authController.user?.uid;
    final otherUserId = _otherUser.value?.id;
    final content = messageController.text.trim();
    messageController.clear();
    _isTyping.value = false;

    if (currentUserId == null || otherUserId == null || content.isEmpty) {
      Get.snackbar('Error', 'You cannot send message to this user');
      return;
    }

    if (await _firestoreService.isUnfriended(currentUserId, otherUserId)) {
      Get.snackbar('Error', 'You can no longer send messages to this user');
      return;
    }

    try {
      _isLoading.value = true;
      final message = MessageModel(
        id: _uuid.v4(),
        senderId: currentUserId,
        receiverId: otherUserId,
        content: content,
        type: MessageType.text,
        timestamp: DateTime.now(),
        isRead: false,
      );

      await _firestoreService.sendMessage(message);
      _isTyping.value = false;

      // Small delay to ensure Firestore has processed the update
      await Future.delayed(Duration(milliseconds: 100));

      _scrollToBottom();
    } catch (e) {
      print('Error sending message: ${e.toString()}');
      Get.snackbar('Error', 'Failed to send message');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _markMessagesAsRead() async {
    final currentUserId = _authController.user?.uid;
    if (currentUserId != null && _chatId.value.isNotEmpty) {
      _isChatActive.value = true;
      try {
        await _firestoreService.restoreUnreadCount(
          _chatId.value,
          currentUserId,
        );
      } catch (e) {
        print('Error restoring unread count: ${e.toString()}');
      }
    }
  }

  void onChatResumed() {
    _isChatActive.value = true;
    _markUnReadMessagesAsRead(_messages);
  }

  void onChatPaused() {
    _isChatActive.value = false;
  }

  Future<void> deleteMessage(MessageModel message) async {
    try {
      await _firestoreService.deleteMessage(message.id);
      Get.snackbar('Success', 'Message deleted successfully');
    } catch (e) {
      print('Error deleting message: ${e.toString()}');
      Get.snackbar('Error', 'Failed to delete message');
    }
  }

  Future<void> editMessage(MessageModel message, String newContent) async {
    try {
      await _firestoreService.editMessage(message.id, newContent);
      Get.snackbar('Success', 'Message edited successfully');
    } catch (e) {
      print('Error editing message: ${e.toString()}');
      Get.snackbar('Error', 'Failed to edit message');
    }
  }

  bool isMyMessage(MessageModel message) {
    return message.senderId == _authController.user?.uid;
  }

  String formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      // return '${difference.inHours}h ago';
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return '${days[timestamp.weekday - 1]} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  void clearError() {
    _error.value = '';
  }
}
