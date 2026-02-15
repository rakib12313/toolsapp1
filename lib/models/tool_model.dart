import 'package:flutter/material.dart';

/// Tool categories for filtering and organization
enum ToolCategory {
  image,
  pdf,
  video,
  audio;
  
  String get displayName {
    switch (this) {
      case ToolCategory.image:
        return 'Image';
      case ToolCategory.pdf:
        return 'PDF';
      case ToolCategory.video:
        return 'Video';
      case ToolCategory.audio:
        return 'Audio';
    }
  }
}

/// Represents a tool in the app
class Tool {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final ToolCategory category;
  final String route;
  final bool enabled; // For placeholder tools
  
  const Tool({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.route,
    this.enabled = true,
  });
}

/// All available tools in the app
class ToolsData {
  static const List<Tool> allTools = [
    // Image Tools
    Tool(
      id: 'image_resizer',
      name: 'Image Resizer',
      description: 'Resize images by percentage or dimensions',
      icon: Icons.photo_size_select_large,
      category: ToolCategory.image,
      route: '/tools/image/resizer',
    ),
    Tool(
      id: 'image_compressor',
      name: 'Image Compressor',
      description: 'Compress images to reduce file size',
      icon: Icons.compress,
      category: ToolCategory.image,
      route: '/tools/image/compressor',
    ),
    Tool(
      id: 'image_converter',
      name: 'Image Converter',
      description: 'Convert images between different formats',
      icon: Icons.transform,
      category: ToolCategory.image,
      route: '/tools/image/converter',
    ),
    
    // PDF Tools
    Tool(
      id: 'pdf_merger',
      name: 'PDF Merger',
      description: 'Merge multiple PDF files into one',
      icon: Icons.merge_type,
      category: ToolCategory.pdf,
      route: '/tools/pdf/merger',
    ),
    Tool(
      id: 'pdf_to_images',
      name: 'PDF to Images',
      description: 'Convert PDF pages to image files',
      icon: Icons.image_outlined,
      category: ToolCategory.pdf,
      route: '/tools/pdf/to-images',
    ),
    Tool(
      id: 'images_to_pdf',
      name: 'Images to PDF',
      description: 'Convert multiple images into a single PDF',
      icon: Icons.picture_as_pdf,
      category: ToolCategory.pdf,
      route: '/tools/pdf/from-images',
    ),
    
    Tool(
      id: 'video_converter',
      name: 'Video Converter',
      description: 'Convert videos between different formats',
      icon: Icons.video_file,
      category: ToolCategory.video,
      route: '/tools/video/converter',
    ),
    Tool(
      id: 'video_compressor',
      name: 'Video Compressor',
      description: 'Reduce video file size',
      icon: Icons.video_settings,
      category: ToolCategory.video,
      route: '/tools/video/compressor',
    ),
    Tool(
      id: 'video_trimmer',
      name: 'Video Trimmer',
      description: 'Trim video start and end points',
      icon: Icons.cut,
      category: ToolCategory.video,
      route: '/tools/video/trimmer',
    ),
    
    // Audio Tools
    Tool(
      id: 'audio_extractor',
      name: 'Audio Extractor',
      description: 'Extract audio from video files',
      icon: Icons.audiotrack,
      category: ToolCategory.audio,
      route: '/tools/audio/extractor',
    ),
    Tool(
      id: 'audio_trimmer',
      name: 'Audio Trimmer',
      description: 'Trim audio start and end points',
      icon: Icons.music_note,
      category: ToolCategory.audio,
      route: '/tools/audio/trimmer',
    ),
    Tool(
      id: 'audio_converter',
      name: 'Audio Converter',
      description: 'Convert audio between different formats',
      icon: Icons.library_music,
      category: ToolCategory.audio,
      route: '/tools/audio/converter',
    ),
    Tool(
      id: 'audio_compressor',
      name: 'Audio Compressor',
      description: 'Reduce audio file size',
      icon: Icons.graphic_eq,
      category: ToolCategory.audio,
      route: '/tools/audio/compressor',
    ),
  ];
}
