import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter_new_video/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_video/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../models/history_item.dart';
import '../../../providers/history_provider.dart';
import '../../../providers/storage_provider.dart';
import '../../../widgets/responsive/responsive_builder.dart';

class AudioCompressorScreen extends StatefulWidget {
  const AudioCompressorScreen({super.key});

  @override
  State<AudioCompressorScreen> createState() => _AudioCompressorScreenState();
}

class _AudioCompressorScreenState extends State<AudioCompressorScreen> {
  File? _selectedAudio;
  double _compressionLevel = 50;
  int _targetBitrate = 128;
  bool _isProcessing = false;
  double _progress = 0;
  String? _outputPath;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Responsive.getHorizontalPadding(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Compressor'),
      ),
      body: ListView(
        padding: EdgeInsets.all(horizontalPadding),
        children: [
          if (_selectedAudio == null)
            _buildFilePickerCard()
          else ...[
            _buildAudioPreviewCard(),
            const SizedBox(height: 16),
            _buildCompressionSettings(),
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
              Icons.graphic_eq,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text('Compress Audio File', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Reduce file size with minimal quality loss',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    )),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _pickAudio,
              icon: const Icon(Icons.folder_open),
              label: const Text('Pick Audio'),
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
        subtitle: Text('Original size: ${_formatFileSize(_selectedAudio!.lengthSync())}'),
        trailing: TextButton(
          onPressed: _pickAudio,
          child: const Text('Change'),
        ),
      ),
    );
  }

  Widget _buildCompressionSettings() {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Target Bitrate',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    )),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [64, 96, 128, 192, 256].map((br) {
                return ChoiceChip(
                  label: Text('$br kbps'),
                  selected: _targetBitrate == br,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _targetBitrate = br;
                        _outputPath = null;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text('Estimated results:', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text('Expected reduction based on ${_targetBitrate}kbps bitrate.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
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
            onPressed: _isProcessing ? null : _compressAudio,
            icon: const Icon(Icons.compress),
            label: Text(_isProcessing ? 'Compressing...' : 'Compress Audio'),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard() {
    final compressedFile = File(_outputPath!);
    final compressedSize = compressedFile.lengthSync();
    final originalSize = _selectedAudio!.lengthSync();
    final reduction = (1 - (compressedSize / originalSize)) * 100;

    return Card.filled(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('Compression Complete!',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            Text('New Size: ${_formatFileSize(compressedSize)} (${reduction.toStringAsFixed(1)}% reduction)'),
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
      });
    }
  }

  Future<void> _compressAudio() async {
    if (_selectedAudio == null) return;

    setState(() {
      _isProcessing = true;
      _outputPath = null;
    });

    try {
      final tempDir = await getTemporaryDirectory();
      final extension = _selectedAudio!.path.split('.').last;
      final fileName = _selectedAudio!.path.split(Platform.pathSeparator).last.split('.').first;
      final outputFilePath = '${tempDir.path}/${fileName}_compressed_${DateTime.now().millisecondsSinceEpoch}.$extension';

      // FFmpeg command for compression
      // -i input -b:a bitrate output
      final command = '-i "${_selectedAudio!.path}" -b:a ${_targetBitrate}k "$outputFilePath"';

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        setState(() {
          _outputPath = outputFilePath;
          _isProcessing = false;
        });
      } else {
        throw Exception('Compression failed');
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
        toolName: 'Audio Compressor',
        toolId: 'audio_compressor',
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
    await Share.shareXFiles([XFile(_outputPath!)], text: 'Compressed Audio');
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
