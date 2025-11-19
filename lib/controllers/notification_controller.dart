import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_chat_app/controllers/auth_controller.dart';
import 'package:just_chat_app/models/notification_model.dart';
import 'package:just_chat_app/models/user_model.dart';
import 'package:just_chat_app/routes/app_routes.dart';
import 'package:just_chat_app/services/firestore_service.dart';
import 'package:just_chat_app/theme/app_theme.dart';

class NotificationController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthController _authController = Get.find<AuthController>();
  final RxList<NotificationModel> _notifications = <NotificationModel>[].obs;
  final RxMap<String, UserModel> _users = <String, UserModel>{}.obs;
  final RxBool _isLoading = false.obs;
  final RxString _error = ''.obs;

  List<NotificationModel> get notifications => _notifications;
  Map<String, UserModel> get users => _users;
  bool get isLoading => _isLoading.value;
  String get error => _error.value;

  @override
  void onInit() {
    super.onInit();
    _loadNotifications();
    _loadUsers();
  }

  void _loadNotifications() {
    final currentUserId = _authController.user?.uid;
    if (currentUserId != null) {
      _notifications.bindStream(
        _firestoreService.getNotificationsStream(currentUserId),
      );
    }
  }

  void _loadUsers() {
    _users.bindStream(
      _firestoreService.getAllUsersStream().map((userList) {
        Map<String, UserModel> userMap = {};
        for (var user in userList) {
          userMap[user.id] = user;
        }
        return userMap;
      }),
    );
  }

  UserModel? getUser(String userId) {
    return _users[userId];
  }

  Future<UserModel?> getUserAsync(String userId) async {
    if (_users.containsKey(userId)) {
      return _users[userId];
    }
    
    try {
      final user = await _firestoreService.getUser(userId);
      _users[userId] = user;
      return user;
    } catch (e) {
      print('Error fetching user: $e');
      return null;
    }
  }

  Future<void> markAsRead(NotificationModel notification) async {
    try {
      if (!notification.isRead) {
        await _firestoreService.markNotificationAsRead(notification.id);
      }
    } catch (e) {
      _error.value = 'Failed to mark notification as read: ${e.toString()}';
    }
  }

  Future<void> markAllAsRead() async {
    try {
      _isLoading.value = true;
      final currentUserId = _authController.user?.uid;

      if (currentUserId != null) {
        await _firestoreService.markAllNotificationsAsRead(currentUserId);
        Get.snackbar('Success', 'All notifications were marked as read');
      }
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Error', 'Failed to mark all notifications as read');
      print(e.toString());
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> deleteNotification(NotificationModel notification) async {
    try {
      await _firestoreService.deleteNotification(notification.id);
      // Get.snackbar('Success', 'Notification deleted');
    } catch (e) {
      _error.value = 'Failed to delete notification: ${e.toString()}';
      Get.snackbar('Error', 'Failed to delete notification');
      print(e.toString());
    }
  }

  Future<void> handleNotificationTap(NotificationModel notification) async {
    markAsRead(notification);

    switch (notification.type) {
      case NotificationType.friendRequest:
        Get.toNamed(AppRoutes.friendRequests);
        break;
      case NotificationType.friendRequestAccepted:
      case NotificationType.friendRequestDeclined:
        Get.toNamed(AppRoutes.friends);
        break;

      case NotificationType.newMessage:
        final senderId = notification.data?['senderId'];
        final chatId = notification.data?['chatId'];
        if (senderId != null && chatId != null) {
          final user = await getUserAsync(senderId);
          if (user != null) {
            Get.toNamed(AppRoutes.chat, arguments: {'chatId': chatId, 'otherUser': user});
          }
        }
        break;

      case NotificationType.friendRemoved:
        break;
    }
  }

  String getNotificationTimeText(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return '${difference.inDays}d ago';
    } else {
      return '${createdAt.month}/${createdAt.day}/${createdAt.year}';
    }
  }

  IconData getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.friendRequest:
        return Icons.person_add;
      case NotificationType.friendRequestAccepted:
        return Icons.check;
      case NotificationType.friendRequestDeclined:
        return Icons.cancel;
      case NotificationType.newMessage:
        return Icons.message;
      case NotificationType.friendRemoved:
        return Icons.person_off;
    }
  }

  Color getNotificationIconColor(NotificationType type) {
    switch (type) {
      case NotificationType.friendRequest:
        return AppTheme.primaryColor;
      case NotificationType.friendRequestAccepted:
        return AppTheme.successColor;
      case NotificationType.friendRequestDeclined:
        return AppTheme.errorColor;
      case NotificationType.newMessage:
        return AppTheme.backgroundColor;
      case NotificationType.friendRemoved:
        return AppTheme.errorColor;
    }
  }

  int getUnreadCount() {
    return _notifications.where((notification) => !notification.isRead).length;
  }

  void clearError() {
    _error.value = '';
  }
}
