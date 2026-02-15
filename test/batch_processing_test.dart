import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:toolsapp/core/utils/batch_processor_utils.dart';

void main() {
  group('BatchProcessorUtils Tests', () {
    test('Image Conversion Logic', () {
      // Create a small test image (10x10)
      final image = img.Image(width: 10, height: 10);
      img.fill(image, color: img.ColorRgb8(255, 0, 0)); // Red
      final originalBytes = Uint8List.fromList(img.encodePng(image));

      // Test conversion to JPG
      final jpgBytes = BatchProcessorUtils.convertImage(originalBytes, 'jpg', 90);
      expect(jpgBytes, isNotNull);
      expect(jpgBytes.length, greaterThan(0));

      // Test conversion to BMP
      final bmpBytes = BatchProcessorUtils.convertImage(originalBytes, 'bmp', 90);
      expect(bmpBytes, isNotNull);
      expect(bmpBytes.length, greaterThan(0));
    });

    test('PDF Merging Logic', () {
      // Create two dummy PDFs
      final doc1 = PdfDocument();
      doc1.pages.add().graphics.drawString('Page 1', PdfStandardFont(PdfFontFamily.helvetica, 12));
      final bytes1 = Uint8List.fromList(doc1.saveSync());
      doc1.dispose();

      final doc2 = PdfDocument();
      doc2.pages.add().graphics.drawString('Page 2', PdfStandardFont(PdfFontFamily.helvetica, 12));
      final bytes2 = Uint8List.fromList(doc2.saveSync());
      doc2.dispose();

      // Merge them
      final mergedBytes = BatchProcessorUtils.mergePdfs([bytes1, bytes2]);
      expect(mergedBytes, isNotNull);
      expect(mergedBytes.length, greaterThan(bytes1.length));

      // Verify merged document page count
      final mergedDoc = PdfDocument(inputBytes: mergedBytes);
      expect(mergedDoc.pages.count, equals(2));
      mergedDoc.dispose();
    });

    test('Unsupported format fallback', () {
      final image = img.Image(width: 5, height: 5);
      final originalBytes = Uint8List.fromList(img.encodePng(image));

      // Should fallback to JPG for unknown format
      final resultBytes = BatchProcessorUtils.convertImage(originalBytes, 'unknown_format', 90);
      expect(resultBytes, isNotNull);
      
      // Verify it's valid JPG (starts with 0xFFD8)
      expect(resultBytes[0], equals(0xFF));
      expect(resultBytes[1], equals(0xD8));
    });
  });
}
