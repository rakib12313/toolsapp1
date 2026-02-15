import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../widgets/responsive/responsive_builder.dart';

/// Audio Trimmer Tool Screen
class AudioTrimmerScreen extends StatefulWidget {
  const AudioTrimmerScreen({super.key});

  @override
  State<AudioTrimmerScreen> createState() => _AudioTrimmerScreenState();
}

class _AudioTrimmerScreenState extends State<AudioTrimmerScreen> {
  File? _selectedAudio;
  double _startTime = 0;
  double _endTime = 100;
  double _totalDuration = 100; // In seconds
  
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
            _buildWaveformCard(),
            const SizedBox(height: 16),
            _buildTrimControlsCard(),
            const SizedBox(height: 16),
            _buildActionButton(),
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
              Icons.music_note,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Trim Audio',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Trim audio files to desired length',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
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
        title: Text(_selectedAudio!.path.split('/').last.split('\\').last),
        subtitle: Text('Duration: ${_formatDuration(_totalDuration)}'),
        trailing: TextButton(
          onPressed: _pickAudio,
          child: const Text('Change'),
        ),
      ),
    );
  }
  
  Widget _buildWaveformCard() {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Audio Waveform', style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            )),
            const SizedBox(height: 16),
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.graphic_eq,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Waveform Preview',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTrimControlsCard() {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Trim Points', style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            )),
            const SizedBox(height: 16),
            
            // Start time
            Row(
              children: [
                Expanded(
                  child: Text('Start: ${_formatDuration(_startTime)}', 
                    style: Theme.of(context).textTheme.bodyMedium),
                ),
                Text('End: ${_formatDuration(_endTime)}',
                  style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 8),
            
            // Range slider
            RangeSlider(
              values: RangeValues(_startTime, _endTime),
              min: 0,
              max: _totalDuration,
              divisions: _totalDuration.toInt(),
              labels: RangeLabels(
                _formatDuration(_startTime),
                _formatDuration(_endTime),
              ),
              onChanged: (values) {
                setState(() {
                  _startTime = values.start;
                  _endTime = values.end;
                });
              },
            ),
            
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('0:00', style: Theme.of(context).textTheme.bodySmall),
                Text(_formatDuration(_totalDuration), 
                  style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Trimmed duration: ${_formatDuration(_endTime - _startTime)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButton() {
    return FilledButton.icon(
      onPressed: _showFeatureDialog,
      icon: const Icon(Icons.cut),
      label: const Text('Trim Audio'),
    );
  }
  
  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedAudio = File(result.files.single.path!);
        // Simulated duration - in real implementation, would use audio packages
        _totalDuration = 180; // 3 minutes
        _endTime = _totalDuration;
      });
    }
  }
  
  String _formatDuration(double seconds) {
    final minutes = (seconds / 60).floor();
    final secs = (seconds % 60).floor();
    return '${minutes}:${secs.toString().padLeft(2, '0')}';
  }
  
  void _showFeatureDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Feature Note'),
        content: const Text(
          'Audio trimming requires audio processing libraries like just_audio or audioplayers for playback and FFmpeg for actual trimming. '
          'This demo UI demonstrates the interface. Full implementation would include waveform visualization and precise audio editing.',
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
