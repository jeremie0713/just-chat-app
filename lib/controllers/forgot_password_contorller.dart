import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:just_chat_app/services/auth_service.dart';

class ForgotPasswordController extends GetxController {
  final AuthService _authService = AuthService();
  final TextEditingController emailController = TextEditingController();
  final RxBool _isLoading = false.obs;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final RxString _error = ''.obs;
  final RxBool _emailSent = false.obs;

  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  bool get emailSent => _emailSent.value;

  @override
  void onClose() {
    emailController.dispose();
    super.onClose();
  }

  Future<void> sendPasswordResetEmail() async {
    if (!formKey.currentState!.validate()) return;
    try {
      _isLoading.value = true;
      _error.value = '';
      await _authService.sendPasswordResetEmail(emailController.text.trim());
      _emailSent.value = true;

      Get.snackbar(
        'Success',
        'Password reset email sent ${emailController.text}. Please check your inbox.',
        snackPosition: SnackPosition.BOTTOM,
        colorText: Colors.green,
        duration: Duration(seconds: 4),
        backgroundColor: Colors.green.withOpacity(0.1),
      );
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar(
        'Error',
        'Failed to send password reset email: ${_error.value}',
        colorText: Colors.red,
        duration: Duration(seconds: 4),
        backgroundColor: Colors.red.withOpacity(0.1),
      );
    } finally {
      _isLoading.value = false;
    }
  }

  void goBackToLogin() {
    Get.back();
  }

  void resendEmail() {
    _emailSent.value = false;
    sendPasswordResetEmail();
  } 

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!GetUtils.isEmail(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  void clearError() {
    _error.value = '';
  }
}
