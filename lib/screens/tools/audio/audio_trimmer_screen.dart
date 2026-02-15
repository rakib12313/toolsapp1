import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ffmpeg_kit_flutter_new_video/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_video/return_code.dart';
import 'package:ffmpeg_kit_flutter_new_video/ffprobe_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../models/history_item.dart';
import '../../../providers/history_provider.dart';
import '../../../providers/storage_provider.dart';
import '../../../widgets/responsive/responsive_builder.dart';

class AudioTrimmerScreen extends StatefulWidget {
  const AudioTrimmerScreen({super.key});

  @override
  State<AudioTrimmerScreen> createState() => _AudioTrimmerScreenState();
}

class _AudioTrimmerScreenState extends State<AudioTrimmerScreen> {
  File? _selectedAudio;
  double _duration = 100; // Total duration in seconds
  RangeValues _trimRange = const RangeValues(0, 100);
  bool _isProcessing = false;
  String? _outputPath;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Responsive.getHorizontalPadding(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Trimmer'),
      ),
      body: ListView(
        padding: EdgeInsets.all(horizontalPadding),
        children: [
          if (_selectedAudio == null)
            _buildFilePickerCard()
          else ...[
            _buildAudioPreviewCard(),
            const SizedBox(height: 16),
            _buildTrimmerControls(),
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
              Icons.content_cut,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text('Trim Audio', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Cut specific parts of your audio file',
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
        subtitle: Text('Total Length: ${_formatDuration(_duration)}'),
        trailing: TextButton(
          onPressed: _pickAudio,
          child: const Text('Change'),
        ),
      ),
    );
  }

  Widget _buildTrimmerControls() {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Trim Settings',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    )),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Start: ${_formatDuration(_trimRange.start)}'),
                Text('End: ${_formatDuration(_trimRange.end)}'),
              ],
            ),
            RangeSlider(
              values: _trimRange,
              min: 0,
              max: _duration,
              onChanged: (values) {
                setState(() {
                  _trimRange = values;
                });
              },
            ),
            Text(
              'Selected Duration: ${_formatDuration(_trimRange.end - _trimRange.start)}',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
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
            onPressed: _isProcessing ? null : _trimAudio,
            icon: const Icon(Icons.content_cut),
            label: Text(_isProcessing ? 'Trimming...' : 'Trim & Save'),
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
                Text('Trim Complete!',
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
      final file = File(result.files.single.path!);
      
      // Use FFprobe to get duration
      final session = await FFprobeKit.getMediaInformation(file.path);
      final durationStr = session.getMediaInformation()?.getDuration();
      final duration = double.tryParse(durationStr ?? '100') ?? 100;

      setState(() {
        _selectedAudio = file;
        _duration = duration;
        _trimRange = RangeValues(0, duration);
        _outputPath = null;
      });
    }
  }

  Future<void> _trimAudio() async {
    if (_selectedAudio == null) return;

    setState(() {
      _isProcessing = true;
      _outputPath = null;
    });

    try {
      final tempDir = await getTemporaryDirectory();
      final extension = _selectedAudio!.path.split('.').last;
      final fileName = _selectedAudio!.path.split(Platform.pathSeparator).last.split('.').first;
      final outputFilePath = '${tempDir.path}/${fileName}_trimmed_${DateTime.now().millisecondsSinceEpoch}.$extension';

      // FFmpeg command for trimming
      // -ss start_time -to end_time -i input -c copy output
      // Note: -c copy is fast but might not be precise with some formats.
      // Re-encoding is safer for precision: -i input -ss start -to end output
      final start = _trimRange.start.toStringAsFixed(3);
      final end = _trimRange.end.toStringAsFixed(3);
      
      final command = '-i "${_selectedAudio!.path}" -ss $start -to $end -c copy "$outputFilePath"';

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        setState(() {
          _outputPath = outputFilePath;
          _isProcessing = false;
        });
      } else {
        throw Exception('Trimming failed');
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
        toolName: 'Audio Trimmer',
        toolId: 'audio_trimmer',
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
    await Share.shareXFiles([XFile(_outputPath!)], text: 'Trimmed Audio');
  }

  String _formatDuration(double seconds) {
    final duration = Duration(milliseconds: (seconds * 1000).toInt());
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}
