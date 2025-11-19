import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:just_chat_app/controllers/profile_controller.dart';
import 'package:just_chat_app/controllers/theme_controller.dart';
import 'package:just_chat_app/routes/app_routes.dart';
import 'package:just_chat_app/theme/app_theme.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        actions: [
          Obx(
            () => TextButton(
              onPressed:
                  controller.isEditing
                      ? controller.toggleEditing
                      : controller.toggleEditing,
              child: Text(
                controller.isEditing ? 'Cancel' : 'Edit',
                style: TextStyle(
                  color:
                      controller.isEditing
                          ? AppTheme.errorColor
                          : AppTheme.primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Obx(() {
        final user = controller.currentUser;

        // Show error if there's one
        if (controller.error != null && controller.error!.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
                SizedBox(height: 16),
                Text('Error loading profile'),
                SizedBox(height: 8),
                Text(
                  controller.error!,
                  style: TextStyle(color: AppTheme.errorColor, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    controller.clearError();
                    // Trigger reload
                    controller.onInit();
                  },
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (user == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppTheme.primaryColor),
                SizedBox(height: 16),
                Text('Loading profile...'),
              ],
            ),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: AppTheme.primaryColor,
                    child:
                        user.photoUrl.isNotEmpty
                            ? ClipOval(
                              child: Image.network(
                                user.photoUrl,
                                width: 110,
                                height: 110,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildDefaultAvatar(user);
                                },
                              ),
                            )
                            : _buildDefaultAvatar(user),
                  ),
              
                  if (controller.isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        // padding: EdgeInsets.all(8),
                        child: IconButton(
                          onPressed: () {
                            Get.snackbar(
                              'Info',
                              'Photo Update Coming Soon!',
                            );
                          },
                          icon: Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 16),
              Text(
                user.displayName,
                style: Theme.of(Get.context!).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.7)),
                    
              ),
              SizedBox(height: 4),
              Text(
                user.email,
                style: Theme.of(Get.context!).textTheme.bodyMedium
                    ?.copyWith(color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.7)),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                decoration: BoxDecoration(
                  color:
                      user.isOnline
                          ? AppTheme.successColor.withOpacity(0.1)
                          : Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 8,
                      width: 8,
                      decoration: BoxDecoration(
                        color:
                            user.isOnline
                                ? AppTheme.successColor
                                : Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      user.isOnline ? 'Online' : 'Offline',
                      style: Theme.of(
                        Get.context!,
                      ).textTheme.bodySmall?.copyWith(
                        color:
                            user.isOnline
                                ? AppTheme.successColor
                                : Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
              Text(
                controller.getJoinedDate(),
                style: Theme.of(Get.context!).textTheme.bodySmall?.copyWith(
                  color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Personal Information',
                        style: Theme.of(
                          Get.context!,
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                          color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      SizedBox(height: 20),
                      Obx(() => TextFormField(
                        controller: controller.displayNameController,
                        enabled: controller.isEditing,
                        decoration: InputDecoration(
                          labelText: 'Display Name',
                          prefixIcon: Icon(Icons.person_outlined),
                        ),
                      )),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: controller.emailController,
                        enabled: false,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                          helperText: 'Email cannot be changed',
                        ),
                      ),
                      Obx(() => controller.isEditing ? Column(
                        children: [
                          SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: controller.isLoading
                                  ? null
                                  : controller.updateProfile,
                              child: controller.isLoading
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text('Save Changes'),
                            ),
                          ),
                        ],
                      ) : SizedBox.shrink()),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 32),
              Column(
                children: [
                  Card(
                    child: Column(
                      children: [
                        Obx(() => ListTile(
                          leading: Icon(
                            themeController.isDarkMode.value ? Icons.dark_mode : Icons.light_mode,
                            color: AppTheme.primaryColor,
                          ),
                          title: Text('Dark Mode'),
                          trailing: Switch(
                            value: themeController.isDarkMode.value,
                            onChanged: (value) => themeController.toggleTheme(),
                            activeColor: AppTheme.primaryColor,
                          ),
                        )),
                        Divider(height: 1, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
                        ListTile(
                          leading: Icon(
                            Icons.security,
                            color: AppTheme.primaryColor,
                          ),
                          title: Text('Change Password'),
                          trailing: Icon(Icons.arrow_forward_ios),
                          onTap: () => Get.toNamed(AppRoutes.changePassword),
                        ),
                        Divider(height: 1, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
                        ListTile(
                          leading: Icon(
                            Icons.delete_forever,
                            color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.7),
                          ),
                          title: Text('Delete Account'),
                          trailing: Icon(Icons.arrow_forward_ios),
                          onTap: controller.deleteAccount,
                        ),
                        Divider(height: 1, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
                        ListTile(
                          leading: Icon(
                            Icons.logout,
                            color: AppTheme.errorColor,
                          ),
                          title: Text('Sign Out'),
                          trailing: Icon(Icons.arrow_forward_ios),
                          onTap: controller.signOut,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Text('Just Chat App © 2025', style: Theme.of(Get.context!).textTheme.bodySmall?.copyWith(
                    color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.7),
                  )),
                ],
              )
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDefaultAvatar(dynamic user) {
    return Text(
      user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
      style: TextStyle(
        fontSize: 45,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
