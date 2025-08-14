import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static const String _useEditableTextKey = 'use_editable_text';
  
  bool _useEditableText = false;
  SharedPreferences? _prefs;

  bool get useEditableText => _useEditableText;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _useEditableText = _prefs?.getBool(_useEditableTextKey) ?? false;
    notifyListeners();
  }

  Future<void> setUseEditableText(bool value) async {
    _useEditableText = value;
    await _prefs?.setBool(_useEditableTextKey, value);
    notifyListeners();
  }
}