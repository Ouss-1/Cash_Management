import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themePrefKey = 'is_dark_mode';
  static const String _currencyPrefKey = 'currency_symbol';
  
  bool _isDarkMode = false;
  String _currencySymbol = '\$';

  bool get isDarkMode => _isDarkMode;
  String get currencySymbol => _currencySymbol;

  ThemeProvider() {
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themePrefKey) ?? false;
    _currencySymbol = prefs.getString(_currencyPrefKey) ?? '\$';
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themePrefKey, _isDarkMode);
    notifyListeners();
  }

  Future<void> setCurrency(String symbol) async {
    _currencySymbol = symbol;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyPrefKey, symbol);
    notifyListeners();
  }
}
