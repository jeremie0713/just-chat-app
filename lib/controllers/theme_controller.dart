import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  static ThemeController get instance => Get.find();

  // Storage key
  final _key = 'isDarkMode';

  // Observable theme mode
  var isDarkMode = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Load saved theme preference
    _loadThemePreference();
  }

  // Load theme preference from storage
  void _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    isDarkMode.value = prefs.getBool(_key) ?? false;
  }

  // Toggle theme
  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
    _saveThemePreference();
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }

  // Set specific theme
  void setTheme(bool isDark) {
    isDarkMode.value = isDark;
    _saveThemePreference();
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }

  // Get current theme mode
  ThemeMode get themeMode => isDarkMode.value ? ThemeMode.dark : ThemeMode.light;

  // Save theme preference to storage
  void _saveThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, isDarkMode.value);
  }

  // Check if dark mode is active
  bool get isLight => !isDarkMode.value;
}