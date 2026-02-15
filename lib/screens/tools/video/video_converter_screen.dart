import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter_new_video/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_video/return_code.dart';
import 'package:ffmpeg_kit_flutter_new_video/statistics.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../models/history_item.dart';
import '../../../providers/history_provider.dart';
import '../../../providers/storage_provider.dart';
import '../../../widgets/responsive/responsive_builder.dart';

class VideoConverterScreen extends StatefulWidget {
  const VideoConverterScreen({super.key});

  @override
  State<VideoConverterScreen> createState() => _VideoConverterScreenState();
}

class _VideoConverterScreenState extends State<VideoConverterScreen> {
  File? _selectedVideo;
  String _outputFormat = 'mp4';
  bool _isProcessing = false;
  double _progress = 0;
  String? _outputPath;

  final List<String> _formats = ['mp4', 'avi', 'mkv', 'mov', 'webm'];

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
          else ...[
            _buildVideoPreviewCard(),
            const SizedBox(height: 16),
            _buildFormatSelection(),
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
          if (_outputPath != null) ...[
            const SizedBox(height: 24),
            _buildResultCard(),
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
              Icons.video_library,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text('Convert Video', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Change video format easily',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    )),
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
      child: ListTile(
        leading: const Icon(Icons.movie),
        title: Text(_selectedVideo!.path.split(Platform.pathSeparator).last),
        subtitle: Text(_formatFileSize(_selectedVideo!.lengthSync())),
        trailing: TextButton(
          onPressed: _pickVideo,
          child: const Text('Change'),
        ),
      ),
    );
  }

  Widget _buildFormatSelection() {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Output Format',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    )),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _formats.map((format) {
                return ChoiceChip(
                  label: Text(format.toUpperCase()),
                  selected: _outputFormat == format,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _outputFormat = format;
                        _outputPath = null;
                      });
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
    return Column(
      children: [
        if (_isProcessing) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: 16),
        ],
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _isProcessing ? null : _convertVideo,
            icon: const Icon(Icons.transform),
            label: Text(_isProcessing ? 'Converting...' : 'Convert Video'),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard() {
    return Card.filled(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('Conversion Complete!',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _saveFile,
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _shareFile,
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedVideo = File(result.files.single.path!);
        _outputPath = null;
      });
    }
  }

  Future<void> _convertVideo() async {
    if (_selectedVideo == null) return;

    setState(() {
      _isProcessing = true;
      _outputPath = null;
    });

    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = _selectedVideo!.path.split(Platform.pathSeparator).last.split('.').first;
      final outputFilePath = '${tempDir.path}/${fileName}_converted_${DateTime.now().millisecondsSinceEpoch}.$_outputFormat';

      // FFmpeg command for conversion
      final command = '-i "${_selectedVideo!.path}" "$outputFilePath"';

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        setState(() {
          _outputPath = outputFilePath;
          _isProcessing = false;
        });
      } else {
        throw Exception('Conversion failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _saveFile() async {
    if (_outputPath == null) return;
    try {
      final storageProvider = Provider.of<StorageProvider>(context, listen: false);
      final historyProvider = Provider.of<HistoryProvider>(context, listen: false);
      
      final saveDir = storageProvider.savePath;
      final fileName = _outputPath!.split(Platform.pathSeparator).last;
      final targetPath = '$saveDir/$fileName';
      
      final file = File(_outputPath!);
      await file.copy(targetPath);
      
      await historyProvider.addEntry(HistoryItem(
        toolName: 'Video Converter',
        toolId: 'video_converter',
        fileName: fileName,
        fileSize: file.lengthSync(),
        outputPath: targetPath,
        status: 'success',
      ));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved to: $targetPath')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    }
  }

  Future<void> _shareFile() async {
    if (_outputPath == null) return;
    await Share.shareXFiles([XFile(_outputPath!)], text: 'Converted Video');
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
