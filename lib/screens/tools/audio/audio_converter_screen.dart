import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter_new_video/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_video/return_code.dart';
import 'package:ffmpeg_kit_flutter_new_video/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new_video/statistics.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../models/history_item.dart';
import '../../../providers/history_provider.dart';
import '../../../providers/storage_provider.dart';
import '../../../widgets/responsive/responsive_builder.dart';

class AudioConverterScreen extends StatefulWidget {
  const AudioConverterScreen({super.key});

  @override
  State<AudioConverterScreen> createState() => _AudioConverterScreenState();
}

class _AudioConverterScreenState extends State<AudioConverterScreen> {
  File? _selectedAudio;
  String _outputFormat = 'mp3';
  int _bitrate = 192;
  bool _isProcessing = false;
  double _progress = 0;
  String? _outputPath;
  
  final List<Map<String, String>> _formats = [
    {'value': 'mp3', 'label': 'MP3', 'icon': '🎵'},
    {'value': 'wav', 'label': 'WAV', 'icon': '🎼'},
    {'value': 'aac', 'label': 'AAC', 'icon': '🎹'},
    {'value': 'm4a', 'label': 'M4A', 'icon': '🎶'},
    {'value': 'flac', 'label': 'FLAC', 'icon': '🎸'},
  ];

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Responsive.getHorizontalPadding(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Converter'),
      ),
      body: ListView(
        padding: EdgeInsets.all(horizontalPadding),
        children: [
          if (_selectedAudio == null)
            _buildFilePickerCard()
          else ...[
            _buildAudioPreviewCard(),
            const SizedBox(height: 16),
            _buildFormatCard(),
            const SizedBox(height: 16),
            _buildBitrateCard(),
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
              Icons.library_music,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Convert Audio',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Supports MP3, WAV, AAC, M4A, FLAC',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _pickAudio,
              icon: const Icon(Icons.folder_open),
              label: const Text('Pick Audio File'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioPreviewCard() {
    return Card.outlined(
      child: ListTile(
        leading: const Icon(Icons.audiotrack),
        title: Text(_selectedAudio!.path.split(Platform.pathSeparator).last),
        subtitle: Text(_formatFileSize(_selectedAudio!.lengthSync())),
        trailing: TextButton(
          onPressed: _pickAudio,
          child: const Text('Change'),
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
                      setState(() {
                        _outputFormat = format['value']!;
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

  Widget _buildBitrateCard() {
    if (_outputFormat == 'flac' || _outputFormat == 'wav') return const SizedBox.shrink();
    
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bitrate: $_bitrate kbps',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    )),
            Slider(
              value: _bitrate.toDouble(),
              min: 64,
              max: 320,
              divisions: 8,
              label: '$_bitrate kbps',
              onChanged: (value) => setState(() { 
                _bitrate = value.toInt();
                _outputPath = null;
              }),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('64 kbps', style: Theme.of(context).textTheme.bodySmall),
                Text('320 kbps', style: Theme.of(context).textTheme.bodySmall),
              ],
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
          LinearProgressIndicator(value: _progress > 0 ? _progress : null),
          const SizedBox(height: 8),
          Text(_progress > 0 
            ? 'Converting: ${(_progress * 100).toInt()}%' 
            : 'Starting conversion...'),
          const SizedBox(height: 16),
        ],
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _isProcessing ? null : _convertAudio,
            icon: const Icon(Icons.transform),
            label: Text(_isProcessing ? 'Converting...' : 'Convert Audio'),
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

  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedAudio = File(result.files.single.path!);
        _outputPath = null;
        _progress = 0;
      });
    }
  }

  Future<void> _convertAudio() async {
    if (_selectedAudio == null) return;

    setState(() {
      _isProcessing = true;
      _progress = 0;
      _outputPath = null;
    });

    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = _selectedAudio!.path.split(Platform.pathSeparator).last.split('.').first;
      final outputFilePath = '${tempDir.path}/${fileName}_converted_${DateTime.now().millisecondsSinceEpoch}.$_outputFormat';

      // FFmpeg command construction
      // -i input -b:a bitrate output
      String command = '-i "${_selectedAudio!.path}" ';
      if (_outputFormat != 'flac' && _outputFormat != 'wav') {
        command += '-b:a ${_bitrate}k ';
      }
      command += '"$outputFilePath"';

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        setState(() {
          _outputPath = outputFilePath;
          _isProcessing = false;
        });
        
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Conversion successful!')),
          );
        }
      } else {
        throw Exception('FFmpeg process failed with return code $returnCode');
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
        toolName: 'Audio Converter',
        toolId: 'audio_converter',
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
    await Share.shareXFiles([XFile(_outputPath!)], text: 'Converted Audio');
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
