import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsService extends ChangeNotifier {
  static const String _darkModeKey = 'dark_mode';
  static const String _notificationsKey = 'notifications_enabled';
  static const String _usernameKey = 'username'; // Key for storing username

  bool _isDarkMode = false;
  bool _areNotificationsEnabled = true;
  String _username = 'المسؤول العام'; // Default username

  bool get isDarkMode => _isDarkMode;
  bool get areNotificationsEnabled => _areNotificationsEnabled;
  String get username => _username; // Getter for username

  AppSettingsService() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_darkModeKey) ?? false;
    _areNotificationsEnabled = prefs.getBool(_notificationsKey) ?? true;
    _username =
        prefs.getString(_usernameKey) ?? 'المسؤول العام'; // Load username
    notifyListeners();
  }

  Future<void> toggleDarkMode(bool value) async {
    _isDarkMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
  }

  Future<void> toggleNotifications(bool value) async {
    _areNotificationsEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, value);
  }

  // Method to update username
  Future<void> setUsername(String name) async {
    _username = name;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, name);
  }
}
