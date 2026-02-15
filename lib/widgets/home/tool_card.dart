import 'package:flutter/material.dart';
import '../../models/tool_model.dart';
import '../../screens/tools/placeholder_tool_screen.dart';
import '../../screens/tools/image/image_resizer_screen.dart';
import '../../screens/tools/image/image_compressor_screen.dart';
import '../../screens/tools/image/image_converter_screen.dart';
import '../../screens/tools/pdf/pdf_merger_screen.dart';
import '../../screens/tools/pdf/images_to_pdf_screen.dart';
import '../../screens/tools/pdf/pdf_to_images_screen.dart';
import '../../screens/tools/video/video_converter_screen.dart';
import '../../screens/tools/video/video_compressor_screen.dart';
import '../../screens/tools/video/video_trimmer_screen.dart';
import '../../screens/tools/audio/audio_extractor_screen.dart';
import '../../screens/tools/audio/audio_trimmer_screen.dart';
import '../../screens/tools/audio/audio_converter_screen.dart';
import '../../screens/tools/audio/audio_compressor_screen.dart';

/// Tool card widget with hover effects and navigation
class ToolCard extends StatefulWidget {
  final Tool tool;
  
  const ToolCard({
    super.key,
    required this.tool,
  });

  @override
  State<ToolCard> createState() => _ToolCardState();
}

class _ToolCardState extends State<ToolCard> {
  bool _isHovered = false;
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: Card.filled(
          elevation: _isHovered ? 2 : 0,
          child: InkWell(
            onTap: widget.tool.enabled ? _navigateToTool : _showComingSoon,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon with gradient background
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: widget.tool.enabled
                            ? [
                                colorScheme.primaryContainer.withOpacity(0.8),
                                colorScheme.secondaryContainer.withOpacity(0.8),
                              ]
                            : [
                                colorScheme.surfaceContainerHighest,
                                colorScheme.surfaceContainerHighest,
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.tool.icon,
                      size: 20,
                      color: widget.tool.enabled
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Tool name
                  Text(
                    widget.tool.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: widget.tool.enabled
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 2),
                  
                  // Tool description
                  Text(
                    widget.tool.description,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  // Coming soon badge
                  if (!widget.tool.enabled) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Coming Soon',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  void _navigateToTool() {
    Widget screen;
    
    switch (widget.tool.id) {
      case 'image_resizer':
      case 'image_compressor':
      case 'image_converter':
      case 'pdf_merger':
      case 'images_to_pdf':
      case 'pdf_to_images':
      case 'video_converter':
      case 'video_compressor':
      case 'video_trimmer':
      case 'audio_extractor':
      case 'audio_trimmer':
      case 'audio_converter':
      case 'audio_compressor':
        screen = _loadScreen(widget.tool.id);
        break;
      default:
        screen = PlaceholderToolScreen(tool: widget.tool);
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }
  
  Widget _loadScreen(String toolId) {
    switch (toolId) {
      case 'image_resizer':
        return const ImageResizerScreen();
      case 'image_compressor':
        return const ImageCompressorScreen();
      case 'image_converter':
        return const ImageConverterScreen();
      case 'pdf_merger':
        return const PdfMergerScreen();
      case 'images_to_pdf':
        return const ImagesToPdfScreen();
      case 'pdf_to_images':
        return const PdfToImagesScreen();
      case 'video_converter':
        return const VideoConverterScreen();
      case 'video_compressor':
        return const VideoCompressorScreen();
      case 'video_trimmer':
        return const VideoTrimmerScreen();
      case 'audio_extractor':
        return const AudioExtractorScreen();
      case 'audio_trimmer':
        return const AudioTrimmerScreen();
      case 'audio_converter':
        return const AudioConverterScreen();
      case 'audio_compressor':
        return const AudioCompressorScreen();
      default:
        return PlaceholderToolScreen(tool: widget.tool);
    }
  }
  
  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.tool.name} - Coming Soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
