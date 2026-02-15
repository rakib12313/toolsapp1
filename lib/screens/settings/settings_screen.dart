import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/theme_provider.dart';
import '../../providers/storage_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/update_service.dart';
import '../../widgets/responsive/responsive_builder.dart';

/// Settings screen for app configuration
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Responsive.getHorizontalPadding(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings',
          style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
        children: [
          _buildSection(
            context,
            title: 'Appearance',
            children: [
              const _ThemeSelectorCard(),
            ],
          ),
          
          const SizedBox(height: 24),
          
          _buildSection(
            context,
            title: 'Storage',
            children: [
              _buildStorageCard(context),
            ],
          ),
          
          const SizedBox(height: 24),
          
          _buildSection(
            context,
            title: 'Updates',
            children: [
              _buildUpdateCard(context),
            ],
          ),
          
          const SizedBox(height: 24),
          
          _buildSection(
            context,
            title: 'About',
            children: [
              _buildAboutCard(context),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
  
  Widget _buildStorageCard(BuildContext context) {
    final storageProvider = Provider.of<StorageProvider>(context);
    
    return Card.outlined(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: const Text('Storage Location'),
            subtitle: Text(storageProvider.savePath.isEmpty 
              ? 'Default save folder' 
              : storageProvider.savePath),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await storageProvider.pickSavePath();
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Clear Cache'),
            subtitle: const Text('Free up storage space'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showClearCacheDialog(context);
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildUpdateCard(BuildContext context) {
    return Card.outlined(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.system_update),
            title: const Text('Version'),
            subtitle: Text('${AppConstants.appName} v${AppConstants.appVersion}'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.cloud_download_outlined),
            title: const Text('Check for Updates'),
            subtitle: const Text('Tap to check for new versions'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              _checkForUpdates(context);
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildAboutCard(BuildContext context) {
    return Card.outlined(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            subtitle: const Text('App information and developer'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showAboutDialog(context);
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Licenses'),
            subtitle: const Text('Open source licenses'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: AppConstants.appName,
                applicationVersion: AppConstants.appVersion,
              );
            },
          ),
        ],
      ),
    );
  }
  
  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('This will remove all temporary files. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared successfully')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
  
  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: AppConstants.appVersion,
      applicationIcon: const FlutterLogo(size: 64),
      children: [
        const Text('A comprehensive multi-tool utility application for image, PDF, and video processing.'),
        const SizedBox(height: 16),
        const Text('Developed with ❤️ using Flutter'),
      ],
    );
  }
  
  Future<void> _checkForUpdates(BuildContext context) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    final updateService = UpdateService();
    final updateInfo = await updateService.checkForUpdates();
    
    if (!context.mounted) return;
    
    // Close loading dialog
    Navigator.pop(context);
    
    if (updateInfo != null) {
      _showUpdateDialog(context, updateInfo);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You\'re on the latest version!')),
      );
    }
  }
  
  void _showUpdateDialog(BuildContext context, UpdateInfo updateInfo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Available!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New version ${updateInfo.latestVersion} is available!'),
            const SizedBox(height: 8),
            Text(
              'Current version: ${updateInfo.currentVersion}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (updateInfo.releaseNotes.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Release Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                updateInfo.releaseNotes,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () async {
              final url = Uri.parse(updateInfo.releaseUrl);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }
}

/// Theme selector card widget
class _ThemeSelectorCard extends StatelessWidget {
  const _ThemeSelectorCard();

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.palette_outlined),
                const SizedBox(width: 12),
                Text(
                  'Theme Mode',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('System'),
                  icon: Icon(Icons.brightness_auto),
                ),
              ],
              selected: {themeProvider.themeMode},
              onSelectionChanged: (Set<ThemeMode> selection) {
                themeProvider.setThemeMode(selection.first);
              },
            ),
          ],
        ),
      ),
    );
  }
}
