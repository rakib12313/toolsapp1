import 'package:uuid/uuid.dart';

/// Represents a history entry for a processed file
class HistoryItem {
  final String id;
  final String toolName;
  final String toolId;
  final String fileName;
  final int fileSize;
  final DateTime timestamp;
  final String status; // 'success' or 'failed'
  final String? inputPath;
  final String? outputPath;
  final String? errorMessage;
  
  HistoryItem({
    String? id,
    required this.toolName,
    required this.toolId,
    required this.fileName,
    required this.fileSize,
    DateTime? timestamp,
    this.status = 'success',
    this.inputPath,
    this.outputPath,
    this.errorMessage,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();
  
  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'toolName': toolName,
      'toolId': toolId,
      'fileName': fileName,
      'fileSize': fileSize,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
      'inputPath': inputPath,
      'outputPath': outputPath,
      'errorMessage': errorMessage,
    };
  }
  
  /// Create from JSON
  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id'],
      toolName: json['toolName'],
      toolId: json['toolId'],
      fileName: json['fileName'],
      fileSize: json['fileSize'],
      timestamp: DateTime.parse(json['timestamp']),
      status: json['status'],
      inputPath: json['inputPath'],
      outputPath: json['outputPath'],
      errorMessage: json['errorMessage'],
    );
  }
}
