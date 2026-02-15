import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

/// Manages theme mode (light/dark/system) with persistence
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  late SharedPreferences _prefs;
  
  ThemeMode get themeMode => _themeMode;
  
  /// Initialize theme from saved preferences
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    final themeValue = _prefs.get(AppConstants.themeKey);
    
    if (themeValue is String) {
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.toString() == themeValue,
        orElse: () => ThemeMode.system,
      );
      notifyListeners();
    } else if (themeValue is int) {
      // Handle legacy index storage if it exists
      if (themeValue >= 0 && themeValue < ThemeMode.values.length) {
        _themeMode = ThemeMode.values[themeValue];
        notifyListeners();
      }
    }
  }
  
  /// Set theme mode and persist to storage
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setString(AppConstants.themeKey, mode.toString());
    notifyListeners();
  }
  
  /// Check if current theme is dark
  bool isDark(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }
}
