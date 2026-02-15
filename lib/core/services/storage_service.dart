import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;

class StorageService {
  static const String _keySavePath = 'custom_save_path';
  
  /// Get the user-selected save path or default to app documents/ToolsApp
  Future<String> getSavePath() async {
    final prefs = await SharedPreferences.getInstance();
    String? customPath = prefs.getString(_keySavePath);
    
    if (customPath != null && customPath.isNotEmpty) {
      final dir = Directory(customPath);
      if (await dir.exists()) {
        return customPath;
      }
    }
    
    // Default path
    Directory baseDir;
    if (Platform.isWindows) {
      baseDir = await getApplicationDocumentsDirectory();
    } else {
      baseDir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
    }
    
    final toolsAppDir = Directory(p.join(baseDir.path, 'ToolsApp'));
    if (!await toolsAppDir.exists()) {
      await toolsAppDir.create(recursive: true);
    }
    
    return toolsAppDir.path;
  }
  
  /// Set a custom save path
  Future<void> setSavePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySavePath, path);
  }
  
  /// Get default suggested paths for the picker
  Future<List<String>> getSuggestedPaths() async {
    List<String> paths = [];
    
    paths.add((await getApplicationDocumentsDirectory()).path);
    
    if (Platform.isAndroid) {
      final external = await getExternalStorageDirectory();
      if (external != null) paths.add(external.path);
    } else if (Platform.isWindows) {
      final downloads = p.join(Platform.environment['USERPROFILE']!, 'Downloads');
      if (await Directory(downloads).exists()) {
        paths.add(downloads);
      }
    }
    
    return paths;
  }
}
