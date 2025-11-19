import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:just_chat_app/controllers/users_list_controller.dart';
import 'package:just_chat_app/models/user_model.dart';
import 'package:just_chat_app/theme/app_theme.dart';

class UserListItem extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onTap;
  final UsersListController controller;

  const UserListItem({
    super.key,
    required this.user,
    this.onTap,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final relationshipStatus = controller.getUserRelationshipStatus(user.id);

      if (relationshipStatus == UserRelationshipStatus.friends) {
        return SizedBox.shrink();
      }

      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.primaryColor,
                child: Text(
                  user.displayName.isNotEmpty
                      ? user.displayName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      user.email,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  _buildActionButton(relationshipStatus),
                  if (relationshipStatus ==
                      UserRelationshipStatus.friendRequestReceived) ...[
                    SizedBox(
                      width: 110, // Fixed width to match accept button
                      child: OutlinedButton(
                        onPressed: () => controller.declineFriendRequest(user),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.errorColor,
                          side: BorderSide(color: AppTheme.errorColor, width: 1.5),
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: Size(0, 32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                        ),
                        child: Text('Decline', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildActionButton(UserRelationshipStatus relationshipStatus) {
    switch (relationshipStatus) {
      case UserRelationshipStatus.none:
        return ElevatedButton.icon(
          onPressed: () => controller.handleRelationshipAction(user),
          icon: Icon(controller.getRelationshipButtonIcon(relationshipStatus)),
          label: Text(controller.getRelationshipButtonText(relationshipStatus)),
          style: ElevatedButton.styleFrom(
            backgroundColor: controller.getRelationshipButtonColor(
              relationshipStatus,
            ),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: Size(0, 32),
          ),
        );

      case UserRelationshipStatus.friendRequestSent:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  controller.getRelationshipButtonIcon(relationshipStatus),
                  color: controller.getRelationshipButtonColor(
                    relationshipStatus,
                  ),
                  size: 16,
                ),
                SizedBox(width: 4),
                Text(
                  controller.getRelationshipButtonText(relationshipStatus),
                  style: TextStyle(
                    color: controller.getRelationshipButtonColor(
                      relationshipStatus,
                    ),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            ElevatedButton.icon(
              onPressed: () => _showCancelRequestDialog(),
              icon: Icon(Icons.cancel_outlined, size: 14),
              label: Text('Cancel Request', style: TextStyle(fontSize: 10)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                side: BorderSide(color: Colors.redAccent),
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                minimumSize: Size(0, 32),
              ),
            ),
          ],
        );

      case UserRelationshipStatus.friendRequestReceived:
        return SizedBox(
          width: 110, // Fixed width to match decline button
          child: OutlinedButton(
            onPressed: () => controller.handleRelationshipAction(user),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: controller.getRelationshipButtonColor(
                relationshipStatus,
              ),
              side: BorderSide(color: controller.getRelationshipButtonColor(
                relationshipStatus,
              ), width: 1.5),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size(0, 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.0),
              ),
            ),
            child: Text(controller.getRelationshipButtonText(relationshipStatus)),
          ),
        );

      case UserRelationshipStatus.blocked:
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.errorColor.withOpacity(0.1),
            border: Border.all(color: AppTheme.errorColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.block, color: AppTheme.errorColor, size: 16),
              SizedBox(width: 4),
              Text(
                'Blocked',
                style: TextStyle(
                  color: AppTheme.errorColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );

      case UserRelationshipStatus.friends:
        return SizedBox.shrink();
    }
  }

  void _showCancelRequestDialog() {
    Get.dialog(
      AlertDialog(
        title: Text('Cancel Friend Request'),
        content: Text(
          'Are you sure you want to cancel the friend request to ${user.displayName}?',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Keep Request')),
          TextButton(
            onPressed: () {
              controller.cancelFriendRequest(user);
              Get.back();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Cancel Request'),
          ),
        ],
      ),
    );
  }
}
