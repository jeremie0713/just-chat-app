import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_chat_app/controllers/chat_controller.dart';
import 'package:just_chat_app/theme/app_theme.dart';
import 'package:just_chat_app/views/widgets/message_bubble.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> with WidgetsBindingObserver {
  late final String chatId;
  late final ChatController controller;

  @override
  void initState() {
    super.initState();
    chatId = Get.arguments?['chatId'] ?? '';

    if (!Get.isRegistered<ChatController>(tag: chatId)) {
      Get.put<ChatController>(ChatController(), tag: chatId);
    }

    controller = Get.find<ChatController>(tag: chatId);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Get.back();
          },
          icon: Icon(Icons.arrow_back),
        ),
        title: Obx(() {
          final otherUser = controller.otherUser;
          if (otherUser == null) return Text('Chat');
          return Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.primaryColor,
                child:
                    otherUser.photoUrl.isNotEmpty
                        ? ClipOval(
                          child: Image.network(
                            otherUser.photoUrl,
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Text(
                                otherUser.displayName.isNotEmpty
                                    ? otherUser.displayName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            },
                          ),
                        )
                        : Text(
                          otherUser.displayName.isNotEmpty
                              ? otherUser.displayName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      otherUser.displayName,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color:
                            otherUser.isOnline
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      otherUser.isOnline ? 'Online' : 'Offline',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color:
                            otherUser.isOnline
                                ? AppTheme.successColor
                                : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'delete':
                  controller.deleteChat();
                  break;
              }
            },
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(
                        Icons.delete_outline,
                        color: AppTheme.errorColor,
                      ),
                      title: Text('Delete Chat'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: Obx(() {
                if (controller.messages.isEmpty) {
                  return _buildEmptyState();
                }
                return ListView.builder(
                  controller: controller.scrollController,
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  reverse: true,
                  itemCount: controller.messages.length,
                  itemBuilder: (context, index) {
                    // Reverse the index to show latest messages at bottom
                    final reverseIndex = controller.messages.length - 1 - index;
                    final message = controller.messages[reverseIndex];
                    final isMyMessage = controller.isMyMessage(message);
                    final showTime =
                        reverseIndex == 0 ||
                        controller.messages[reverseIndex - 1].timestamp
                                .difference(message.timestamp)
                                .inMinutes
                                .abs() >
                            5;

                    return MessageBubble(
                      message: message,
                      isMyMessage: isMyMessage,
                      showTime: showTime,
                      timeText: controller.formatMessageTime(message.timestamp),
                      onLongPress:
                          isMyMessage ? () => _showMessageOptions(message) : null,
                    );
                  },
                );
              }),
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        controller.onChatResumed();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        controller.onChatPaused();
        break;

      case AppLifecycleState.hidden:
        break;
    }
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(Get.context!).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        minimum: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 8 : 0),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller.messageController,
                        focusNode: controller.messageFocusNode,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => controller.sendMessage(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 8),
            Obx(() => Container(
              decoration: BoxDecoration(
                color: controller.isTyping
                    ? AppTheme.primaryColor
                    : AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: IconButton(
                onPressed: controller.isSending
                ? null
                : controller.sendMessage,
                icon: Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                ),
              ),
            ))
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 40,
                color: AppTheme.primaryColor,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Start a conversation!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Send your first message to begin a conversation.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageOptions(dynamic message) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit, color: AppTheme.primaryColor),
              title: Text('Edit Message'),
              onTap: () {
                // Handle edit message action
                Get.back();
                _showEditDialog(message);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: AppTheme.primaryColor),
              title: Text('Delete Message'),
              onTap: () {
                // Handle edit message action
                Get.back();
                _showDeleteDialog(message);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(dynamic message) {
    final editController = TextEditingController(text: message.content);

    Get.dialog(
      AlertDialog(
        title: Text('Edit Message'),
        content: TextField(
          controller: editController,
          decoration: InputDecoration(hintText: 'Enter new message'),
          maxLines: null,
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Cancel')),
          TextButton(
            onPressed: () {
              // Handle save action
              if (editController.text.trim().isNotEmpty) {
                controller.editMessage(message, editController.text.trim());
                Get.back();
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(dynamic message) {
    Get.dialog(
      AlertDialog(
        title: Text('Delete Message'),
        content: Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Cancel')),
          TextButton(
            onPressed: () {
              controller.deleteMessage(message);
              Get.back();
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }
}
