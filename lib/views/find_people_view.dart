import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_chat_app/controllers/users_list_controller.dart';
import 'package:just_chat_app/theme/app_theme.dart';
import 'package:just_chat_app/views/widgets/user_list_item.dart';

class FindPeopleView extends GetView<UsersListController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Find People'), leading: SizedBox()),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: Obx(() {
              if (controller.filteredUsers.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.separated(
                padding: EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final user = controller.filteredUsers[index];
                  return UserListItem(
                    user: user,
                    onTap: () => controller.handleRelationshipAction(user),
                    controller: controller,
                  );
                },
                separatorBuilder: (context, index) => SizedBox(height: 8),
                itemCount: controller.filteredUsers.length,
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(Get.context!).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: TextField(
        onChanged: controller.updateSearchQuery,
        decoration: InputDecoration(
          hintText: 'Search people...',
          hintStyle: TextStyle(color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.6)),
          prefixIcon: Icon(Icons.search, color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.6)),
          suffixIcon: Obx(() {
            return controller.searchQuery.isNotEmpty
                ? IconButton(
                  icon: Icon(Icons.clear, color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.6)),
                  onPressed: () => controller.clearSearch(),
                )
                : SizedBox.shrink();
          }),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
          ),
          filled: true,
          fillColor: Theme.of(Get.context!).colorScheme.surface,
          // contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.people_outline,
                size: 50,
                color: AppTheme.primaryColor,
              ),
            ),
            SizedBox(height: 24),
            Text(
              controller.searchQuery.isEmpty
                  ? 'No results found'
                  : 'No people found',
              style: Theme.of(Get.context!).textTheme.headlineMedium?.copyWith(
                color: Theme.of(Get.context!).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              controller.searchQuery.isEmpty
                  ? 'Try adjusting your search to find people.'
                  : 'All users will appear here.',
              style: Theme.of(Get.context!).textTheme.bodyMedium?.copyWith(
                color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
