import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_chat_app/controllers/auth_controller.dart';
import 'package:just_chat_app/controllers/home_controller.dart';
import 'package:just_chat_app/controllers/main_controller.dart';
import 'package:just_chat_app/theme/app_theme.dart';
import 'package:just_chat_app/views/widgets/chat_list_item.dart';

class HomeView extends GetView<HomeController> {
  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: _buildAppBar(context, authController),
      body: Column(
        children: [
          _buildSearchBar(),
          Obx(
            () =>
                controller.isSearching && controller.searchQuery.isNotEmpty
                    ? _buildSearchResults()
                    : _buildQuickFilters(),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.refreshChats,
              color: AppTheme.primaryColor,
              child: Obx(() {
                if (controller.chats.isEmpty) {
                  if (controller.isSearching &&
                      controller.searchQuery.isNotEmpty) {
                    return _buildNoSearchResults();
                  } else if (controller.activeFilter != 'All') {
                    return _buildNoFilterResults();
                  } else {
                    return _buildEmptyState();
                  }
                }
                return _buildChatsList();
              }),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AuthController authController,
  ) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      elevation: 0,
      title: Obx(
        () => Text(
          controller.isSearching ? 'Search Results' : 'Messages',
          // style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
      ),
      automaticallyImplyLeading: false,
      actions: [
        Obx(
          () =>
              controller.isSearching
                  ? IconButton(
                    onPressed: controller.clearSearch,
                    icon: Icon(Icons.clear_rounded),
                  )
                  : _buildNotificationButton(),
        ),
        SizedBox(width: 8),
      ],
    );
  }

  Widget _buildNotificationButton() {
    return Obx(() {
      final undreadNotifications = controller.getUnreadNotificationsCount();

      return Container(
        margin: EdgeInsets.only(right: 8),
        child: Stack(
          children: [
            Container(
              margin: EdgeInsets.only(right: 8),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: controller.openNotifications,
                      icon: Icon(Icons.notifications_outlined),
                      iconSize: 22,
                      splashRadius: 20,
                    ),
                  ),
                  if (undreadNotifications > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Theme.of(Get.context!).colorScheme.surface, width: 1.5),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          undreadNotifications > 99
                              ? '99+'
                              : undreadNotifications.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSearchBar() {
    return Container(
      color: Theme.of(Get.context!).colorScheme.surface,
      padding: EdgeInsets.fromLTRB(16, 8, 15, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          onChanged: controller.onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search conversations...',
            hintStyle: TextStyle(color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.6)),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.6),
              size: 20,
            ),
            suffixIcon: Obx(
              () =>
                  controller.searchQuery.isNotEmpty
                      ? IconButton(
                        onPressed: controller.clearSearch,
                        icon: Icon(
                          Icons.clear_rounded,
                          color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.6),
                          size: 18,
                        ),
                      )
                      : SizedBox.shrink(),
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickFilters() {
    return Container(
      color: Theme.of(Get.context!).colorScheme.surface,
      padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Obx(
              () => _buildFilterChip(
                'All',
                () => controller.setFilter('All'),
                controller.activeFilter == 'All',
              ),
            ),
            SizedBox(width: 8),
            Obx(
              () => _buildFilterChip(
                'Unread (${controller.getUnreadCount()})',
                () => controller.setFilter('Unread'),
                controller.activeFilter == 'Unread',
              ),
            ),
            SizedBox(width: 8),
            Obx(
              () => _buildFilterChip(
                'Recent (${controller.getUnreadCount()})',
                () => controller.setFilter('Recent'),
                controller.activeFilter == 'Recent',
              ),
            ),
            SizedBox(width: 8),
            Obx(
              () => _buildFilterChip(
                'Active (${controller.getUnreadCount()})',
                () => controller.setFilter('Active'),
                controller.activeFilter == 'Active',
              ),
            ),
            SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onTap, bool isSelected) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.7),
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return Container(
      color: Theme.of(Get.context!).colorScheme.surface,
      padding: EdgeInsets.fromLTRB(16, 8, 18, 8),
      child: Row(
        children: [
          Obx(
            () => Text(
              'Found ${controller.filteredChats.length} results${controller.filteredChats.length == 1 ? '' : 's'}',
              style: TextStyle(
                color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ),
          TextButton(
            onPressed: controller.clearSearch,
            child: Text(
              'Clear',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSearchResults() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(Get.context!).colorScheme.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[400]),
              SizedBox(height: 16),
              Text(
                'No conversations found',
                style: TextStyle(
                  color: Theme.of(Get.context!).colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Obx(
                () => Text(
                  'No results for "${controller.searchQuery}"',
                  style: TextStyle(color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.7)),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoFilterResults() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(Get.context!).colorScheme.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getFilterIcon(controller.activeFilter),
                size: 64,
                color: Colors.grey[400],
              ),
              SizedBox(height: 16),
              Text(
                'No ${controller.activeFilter.toLowerCase()} conversations',
                style: TextStyle(
                  color: Theme.of(Get.context!).colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                _getFilterEmptyMessage(controller.activeFilter),
                style: TextStyle(color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.7)),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => controller.setFilter('All'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('View All Conversations'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFilterIcon(String filter) {
    switch (filter) {
      case 'Unread':
        return Icons.mark_email_unread_outlined;
      case 'Recent':
        return Icons.schedule_outlined;
      case 'Active':
        return Icons.trending_up_outlined;
      default:
        return Icons.filter_list_outlined;
    }
  }

  String _getFilterEmptyMessage(String filter) {
    switch (filter) {
      case 'Unread':
        return 'You have no unread conversations at the moment.';
      case 'Recent':
        return 'There are no recent conversations to display.';
      case 'Active':
        return 'No active conversations found right now.';
      default:
        return 'No conversations found for the selected filter.';
    }
  }

  Widget _buildChatsList() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(Get.context!).colorScheme.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          if (!controller.isSearching || controller.searchQuery.isEmpty)
            _buildChatHeader(),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(
                vertical: controller.isSearching ? 16 : 8,
                horizontal: 16,
              ),
              itemCount: controller.chats.length,
              separatorBuilder:
                  (context, index) =>
                      Divider(height: 1, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1), indent: 72),
              itemBuilder: (context, index) {
                final chat = controller.chats[index];
                final otherUser = controller.getOtherUser(chat);

                if (otherUser == null) return SizedBox.shrink();

                return AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  child: ChatListItem(
                    chat: chat,
                    otherUser: otherUser,
                    onTap: () => controller.openChat(chat),
                    lastMessageTime: controller.formatLastMessageTime(
                      chat.lastMessageTime,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Obx(() {
            String title = 'Recent Chats';
            switch (controller.activeFilter) {
              case 'Unread':
                title = 'Unread Chats';
                break;
              case 'Recent':
                title = 'Recent Chats';
                break;
              case 'Active':
                title = 'Active Chats';
                break;
            }
            return Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(Get.context!).colorScheme.onSurface,
              ),
            );
          }),

          Row(
            children: [
              if (controller.activeFilter != 'All')
                TextButton(
                  onPressed: controller.clearAllFilters,
                  child: Text(
                    'Clear Filter',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
        borderRadius: BorderRadius.circular(16),
      ),
      child: FloatingActionButton.extended(
        onPressed: () {
          final mainController = Get.find<MainController>();
          mainController.changeTabIndex(1);
        },
        icon: Icon(Icons.chat_rounded, size: 20),
        label: Text(
          'New Chat',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(Get.context!).size.height * 0.6,
        decoration: BoxDecoration(
          color: Theme.of(Get.context!).colorScheme.background,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildEmptyStateIcon(),
                SizedBox(height: 24),
                _buildEmptyStateText(),
                SizedBox(height: 24),
                _buildEmptyStateActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyStateIcon() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(70),
      ),
      child: Icon(
        Icons.chat_bubble_outline_rounded,
        size: 64,
        color: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildEmptyStateText() {
    return Column(
      children: [
        Text(
          'No Conversations Yet',
          style: TextStyle(
            color: Theme.of(Get.context!).colorScheme.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Start meaningful conversations and connect with friends!',
          style: TextStyle(
            color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.7),
            fontSize: 15,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmptyStateActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              final mainController = Get.find<MainController>();
              mainController.changeTabIndex(2);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            icon: Icon(Icons.person_search_rounded, size: 20),
            label: Text(
              'Find People',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              final mainController = Get.find<MainController>();
              mainController.changeTabIndex(1);
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              padding: EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: AppTheme.primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(Icons.person_search_rounded, size: 20),
            label: Text(
              'Find Friends',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
