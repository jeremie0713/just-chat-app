import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_chat_app/controllers/auth_controller.dart';
import 'package:just_chat_app/models/user_model.dart';
import 'package:just_chat_app/services/firestore_service.dart';

class ProfileController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController displayNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  final RxBool _isLoading = false.obs;
  final RxBool _isEditing = false.obs;
  final RxString _error = ''.obs;
  final Rx<UserModel?> _currentUser = Rxn<UserModel>(null);

  bool get isLoading => _isLoading.value;
  bool get isEditing => _isEditing.value;
  String? get error => _error.value;
  UserModel? get currentUser => _currentUser.value;
  
  @override
  void onInit() {
    super.onInit();
    _loadUserData();
  }

  @override
  void onClose() {
    // displayNameController.dispose();
    // emailController.dispose();
    super.onClose();
  }

  void _loadUserData() {
    final currentUserId = _authController.user?.uid;

    if (currentUserId != null) {
      _currentUser.bindStream(
        _firestoreService.getUserStream(currentUserId).handleError((error) {
          _error.value = error.toString();
          return null;
        }),
      );

      ever(_currentUser, (UserModel? user) {
        if (user != null) {
          displayNameController.text = user.displayName;
          emailController.text = user.email;
        } else {
          // If user document doesn't exist, create it from Firebase Auth user
          _createUserDocumentIfNeeded(currentUserId);
        }
      });
    }
  }

  Future<void> _createUserDocumentIfNeeded(String userId) async {
    try {
      final firebaseUser = _authController.user;
      if (firebaseUser != null) {
        final userModel = UserModel(
          id: userId,
          displayName: firebaseUser.displayName ?? 'User',
          email: firebaseUser.email ?? '',
          photoUrl: firebaseUser.photoURL ?? '',
          isOnline: true,
          createdAt: DateTime.now(),
          lastSeen: DateTime.now(),
        );
        
        await _firestoreService.createUser(userModel);
      }
    } catch (e) {
      _error.value = 'Failed to create user profile: ${e.toString()}';
    }
  }

  void toggleEditing() {
    _isEditing.value = !_isEditing.value;
    if (!_isEditing.value) {
      final user = _currentUser.value;
      if (user != null) {
        displayNameController.text = user.displayName;
        emailController.text = user.email;
      }
    }
  }

  Future<void> updateProfile() async {
    try {
      _isLoading.value = true;
      _error.value = '';

      final user = _currentUser.value;
      if (user == null) return;

      // Create new user with only changed fields and fresh timestamps
      final updatedUser = UserModel(
        id: user.id,
        displayName: displayNameController.text.trim(),
        email: user.email, // Keep original email
        photoUrl: user.photoUrl,
        isOnline: user.isOnline,
        createdAt: user.createdAt, // Keep original creation date
        lastSeen: DateTime.now(), // Update to current time
      );

      await _firestoreService.updateUser(updatedUser);
      _isEditing.value = false;
      Get.snackbar('Success', 'Profile updated successfully');
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Error', 'Failed updating profile');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    try{
      await _authController.signOut();
      Get.offAllNamed('/login');
    } catch (e) {
      Get.snackbar('Error', 'Failed to logout');
    }
  }

  Future<void> deleteAccount() async {
    try {
      final result = await Get.dialog<bool>(
        AlertDialog(
          title: Text('Delete Account'),
          content: Text('Are you sure you want to delete your account? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (result == true) {
        _isLoading.value = true;
        await _authController.deleteAccount(confirmPassword: '');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete account');
    } finally {
      _isLoading.value = false;
    }
  }

  String getJoinedDate() {
    final user = _currentUser.value;
    if (user == null) return 'N/A';
    final date = user.createdAt;
    
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return 'Joined ${months[date.month - 1]} ${date.year}';
  }

  void clearError() {
    _error.value = '';
  }
}
