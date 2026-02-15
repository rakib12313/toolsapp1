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
    
    // Default to Downloads folder
    Directory downloadsDir;
    
    if (Platform.isWindows) {
      // Windows: %USERPROFILE%\Downloads
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null) {
        downloadsDir = Directory(p.join(userProfile, 'Downloads'));
      } else {
        downloadsDir = await getApplicationDocumentsDirectory();
      }
    } else if (Platform.isAndroid) {
      // Android: /storage/emulated/0/Download
      // This is the standard path for the public Downloads folder
      const downloadPath = '/storage/emulated/0/Download';
      downloadsDir = Directory(downloadPath);
      
      if (!await downloadsDir.exists()) {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          // Navigate to Download folder from external storage (fallback logic)
          final parts = externalDir.path.split('/');
          if (parts.length > 3) {
            final fallbackPath = '/${parts[1]}/${parts[2]}/Download';
            downloadsDir = Directory(fallbackPath);
          }
        }
      }
      
      // Final fallback to app-specific docs if all else fails
      if (!await downloadsDir.exists()) {
        downloadsDir = await getApplicationDocumentsDirectory();
      }
    } else {
      // iOS/macOS: ~/Downloads
      final docDir = await getApplicationDocumentsDirectory();
      downloadsDir = Directory(p.join(docDir.parent.path, 'Downloads'));
      
      // Fallback if Downloads doesn't exist
      if (!await downloadsDir.exists()) {
        downloadsDir = docDir;
      }
    }
    
    // Ensure the directory exists
    if (!await downloadsDir.exists()) {
      try {
        await downloadsDir.create(recursive: true);
      } catch (e) {
        // If we can't create Downloads, fallback to documents
        downloadsDir = await getApplicationDocumentsDirectory();
      }
    }
    
    return downloadsDir.path;
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
