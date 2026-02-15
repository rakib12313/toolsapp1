import 'package:flutter/material.dart';
import '../core/services/storage_service.dart';
import 'package:file_picker/file_picker.dart';

class StorageProvider with ChangeNotifier {
  final StorageService _storageService = StorageService();
  String _savePath = '';
  
  String get savePath => _savePath;
  
  Future<void> initialize() async {
    _savePath = await _storageService.getSavePath();
    notifyListeners();
  }
  
  Future<void> pickSavePath() async {
    String? result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      _savePath = result;
      await _storageService.setSavePath(result);
      notifyListeners();
    }
  }
}
