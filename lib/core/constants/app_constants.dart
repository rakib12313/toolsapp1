// Core application constants
class AppConstants {
  // App Information
  static const String appName = 'ToolBox Pro';
  static const String appVersion = '1.0.0';
  
  // GitHub Repository (Update with your repo details)
  static const String githubOwner = 'YOUR_USERNAME';
  static const String githubRepo = 'toolsapp';
  static const String githubApiUrl = 
      'https://api.github.com/repos/$githubOwner/$githubRepo/releases/latest';
  
  // Storage Keys
  static const String themeKey = 'theme_mode';
  static const String autoCheckUpdatesKey = 'auto_check_updates';
  static const String lastUpdateCheckKey = 'last_update_check';
  
  // Layout Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;
  
  // Grid Columns
  static const int mobileColumns = 2;
  static const int tabletColumns = 4;
  static const int desktopColumns = 8;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // File Size Limits (in bytes)
  static const int maxImageSize = 50 * 1024 * 1024; // 50MB
  static const int maxPdfSize = 100 * 1024 * 1024; // 100MB
  static const int maxVideoSize = 500 * 1024 * 1024; // 500MB
}
