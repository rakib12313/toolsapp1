import 'dart:io';
import 'package:provider/provider.dart';
import '../../../widgets/responsive/responsive_builder.dart';
import '../../../providers/history_provider.dart';
import '../../../models/history_item.dart';

/// Video Converter Tool Screen  
class VideoConverterScreen extends StatefulWidget {
  const VideoConverterScreen({super.key});

  @override
  State<VideoConverterScreen> createState() => _VideoConverterScreenState();
}

class _VideoConverterScreenState extends State<VideoConverterScreen> {
  File? _selectedVideo;
  String _outputFormat = 'mp4';
  final bool _isProcessing = false;
  
  final List<Map<String, String>> _formats = [
    {'value': 'mp4', 'label': 'MP4', 'icon': '🎬'},
    {'value': 'avi', 'label': 'AVI', 'icon': '📹'},
    {'value': 'mov', 'label': 'MOV', 'icon': '🎥'},
    {'value': 'mkv', 'label': 'MKV', 'icon': '🎞️'},
  ];
  
  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Responsive.getHorizontalPadding(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Converter'),
      ),
      body: ListView(
        padding: EdgeInsets.all(horizontalPadding),
        children: [
          if (_selectedVideo == null)
            _buildFilePickerCard()
          else
            _buildVideoPreviewCard(),
          
          if (_selectedVideo != null) ...[
            const SizedBox(height: 16),
            _buildFormatCard(),
            
            const SizedBox(height: 16),
            _buildActionButtons(),
          ],
        ],
      ),
    );
  }
  
  Widget _buildFilePickerCard() {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.video_file,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Convert Video Format',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Select a video file to convert',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _pickVideo,
              icon: const Icon(Icons.folder_open),
              label: const Text('Pick Video'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildVideoPreviewCard() {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.video_library,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedVideo!.path.split('/').last.split('\\').last,
                    style: Theme.of(context).textTheme.bodyLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _formatFileSize(_selectedVideo!.lengthSync()),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: _pickVideo,
              child: const Text('Change'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFormatCard() {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Output Format',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _formats.map((format) {
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(format['icon']!),
                      const SizedBox(width: 8),
                      Text(format['label']!),
                    ],
                  ),
                  selected: _outputFormat == format['value'],
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _outputFormat = format['value']!);
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButtons() {
    return FilledButton.icon(
      onPressed: _isProcessing ? null : _convertVideo,
      icon: _isProcessing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.transform),
      label: Text(_isProcessing ? 'Converting...' : 'Convert Video'),
    );
  }
  
  String _formatFileSize(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
  
  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );
    
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedVideo = File(result.files.single.path!);
      });
    }
  }
  
  Future<void> _convertVideo() async {
    if (_selectedVideo == null) return;
    
    final historyProvider = Provider.of<HistoryProvider>(context, listen: false);
    
    // Simulate recording history for the demo
    await historyProvider.addEntry(HistoryItem(
      toolName: 'Video Converter',
      toolId: 'video_converter',
      fileName: _selectedVideo!.path.split('/').last.split('\\').last,
      fileSize: _selectedVideo!.lengthSync(),
      status: 'success',
    ));
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Feature Note'),
        content: const Text(
          'Video conversion requires FFmpeg which is not included in this basic implementation. '
          'For full video conversion support, you would need to:\n\n'
          '1. Add FFmpeg library\n'
          '2. Use ffmpeg_kit_flutter package\n'
          '3. Configure platform-specific settings\n\n'
          'This is a demonstration UI showing how the feature would work.\n\n'
          'History entry has been recorded for this operation.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
