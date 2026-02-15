import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import '../constants/app_constants.dart';

/// Service for checking app updates from GitHub releases
class UpdateService {
  /// Check for available updates
  Future<UpdateInfo?> checkForUpdates() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      // Fetch latest release from GitHub API
      final response = await http.get(
        Uri.parse(AppConstants.githubApiUrl),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final latestVersion = (data['tag_name'] as String).replaceAll('v', '');
        final releaseUrl = data['html_url'] as String;
        final releaseNotes = data['body'] as String? ?? '';
        
        // Compare versions
        if (_isNewerVersion(currentVersion, latestVersion)) {
          return UpdateInfo(
            currentVersion: currentVersion,
            latestVersion: latestVersion,
            releaseUrl: releaseUrl,
            releaseNotes: releaseNotes,
            downloadUrl: _getDownloadUrl(data),
          );
        }
      }
      
      return null;
    } catch (e) {
      // Log error in debug mode
      return null;
    }
  }
  
  /// Compare two version strings
  bool _isNewerVersion(String current, String latest) {
    final currentParts = current.split('.').map(int.parse).toList();
    final latestParts = latest.split('.').map(int.parse).toList();
    
    for (int i = 0; i < 3; i++) {
      final currentPart = i < currentParts.length ? currentParts[i] : 0;
      final latestPart = i < latestParts.length ? latestParts[i] : 0;
      
      if (latestPart > currentPart) return true;
      if (latestPart < currentPart) return false;
    }
    
    return false;
  }
  
  /// Extract download URL from release data
  String? _getDownloadUrl(Map<String, dynamic> releaseData) {
    try {
      final assets = releaseData['assets'] as List;
      if (assets.isEmpty) return null;
      
      // Find Windows executable
      final windowsAsset = assets.firstWhere(
        (asset) => (asset['name'] as String).contains('.exe'),
        orElse: () => assets.first,
      );
      
      return windowsAsset['browser_download_url'] as String;
    } catch (e) {
      return null;
    }
  }
}

/// Update information model
class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String releaseUrl;
  final String releaseNotes;
  final String? downloadUrl;
  
  UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseUrl,
    required this.releaseNotes,
    this.downloadUrl,
  });
}
