import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'dart:ui';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class BatchProcessorUtils {
  /// Logic for converting an image, extracted for testability
  static Uint8List convertImage(Uint8List bytes, String format, int quality) {
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Failed to decode image');
    
    switch (format.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return Uint8List.fromList(img.encodeJpg(image, quality: quality));
      case 'png':
        return Uint8List.fromList(img.encodePng(image));
      case 'bmp':
        return Uint8List.fromList(img.encodeBmp(image));
      case 'webp':
        // Fallback to JPG if WebP encoding is not directly available in this version of 'image' package
        return Uint8List.fromList(img.encodeJpg(image, quality: quality));
      default:
        return Uint8List.fromList(img.encodeJpg(image, quality: quality));
    }
  }

  /// Logic for merging PDFs, extracted for testability
  static List<int> mergePdfs(List<Uint8List> pdfDataList) {
    final PdfDocument outputDocument = PdfDocument();
    
    for (final bytes in pdfDataList) {
      final PdfDocument inputDocument = PdfDocument(inputBytes: bytes);
      for (int i = 0; i < inputDocument.pages.count; i++) {
        final PdfPage page = inputDocument.pages[i];
        final PdfTemplate template = page.createTemplate();
        outputDocument.pages.add().graphics.drawPdfTemplate(template, const Offset(0, 0));
      }
      inputDocument.dispose();
    }
    
    final bytes = outputDocument.saveSync();
    outputDocument.dispose();
    return bytes;
  }
}
