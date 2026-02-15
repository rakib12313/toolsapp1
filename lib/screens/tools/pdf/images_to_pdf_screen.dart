import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../../widgets/responsive/responsive_builder.dart';

/// Images to PDF Tool Screen
class ImagesToPdfScreen extends StatefulWidget {
  const ImagesToPdfScreen({super.key});

  @override
  State<ImagesToPdfScreen> createState() => _ImagesToPdfScreenState();
}

class _ImagesToPdfScreenState extends State<ImagesToPdfScreen> {
  final List<File> _selectedImages = [];
  bool _isProcessing = false;
  File? _generatedPdf;
  
  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Responsive.getHorizontalPadding(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Images to PDF'),
        actions: [
          if (_generatedPdf != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _sharePdf,
            ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(horizontalPadding),
        children: [
          _buildPickerCard(),
          
          if (_selectedImages.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildImageGrid(),
            
            const SizedBox(height: 16),
            _buildActionButtons(),
          ],
          
          if (_generatedPdf != null) ...[
            const SizedBox(height: 24),
            _buildResultCard(),
          ],
        ],
      ),
    );
  }
  
  Widget _buildPickerCard() {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.photo_library,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Create PDF from Images',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Select images to combine into a PDF',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.add_photo_alternate),
              label: Text(_selectedImages.isEmpty ? 'Pick Images' : 'Add More'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildImageGrid() {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selected Images (${_selectedImages.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _selectedImages[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton.filledTonal(
                        onPressed: () {
                          setState(() {
                            _selectedImages.removeAt(index);
                          });
                        },
                        icon: const Icon(Icons.close, size: 16),
                        iconSize: 16,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(
                          minWidth: 24,
                          minHeight: 24,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButtons() {
    return FilledButton.icon(
      onPressed: _selectedImages.isEmpty || _isProcessing ? null : _createPdf,
      icon: _isProcessing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.picture_as_pdf),
      label: Text(_isProcessing ? 'Creating PDF...' : 'Create PDF'),
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
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'PDF Created Successfully!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _savePdf,
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _sharePdf,
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
  
  Future<void> _pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    
    if (result != null) {
      setState(() {
        _selectedImages.addAll(
          result.paths.where((path) => path != null).map((path) => File(path!)),
        );
      });
    }
  }
  
  Future<void> _createPdf() async {
    if (_selectedImages.isEmpty) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      final pdf = pw.Document();
      
      for (final imageFile in _selectedImages) {
        final imageBytes = await imageFile.readAsBytes();
        final image = img.decodeImage(imageBytes);
        
        if (image != null) {
          final pngBytes = img.encodePng(image);
          final pdfImage = pw.MemoryImage(Uint8List.fromList(pngBytes));
          
          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              build: (context) => pw.Center(
                child: pw.Image(pdfImage, fit: pw.BoxFit.contain),
              ),
            ),
          );
        }
      }
      
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/images_to_pdf_$timestamp.pdf';
      
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());
      
      setState(() {
        _generatedPdf = file;
        _isProcessing = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF created successfully!')),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
  
  Future<void> _savePdf() async {
    if (_generatedPdf == null) return;
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/images_to_pdf_$timestamp.pdf';
      
      await _generatedPdf!.copy(filePath);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved to: $filePath')),
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
  
  Future<void> _sharePdf() async {
    if (_generatedPdf == null) return;
    
    try {
      await Share.shareXFiles([XFile(_generatedPdf!.path)], text: 'Created PDF');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing: $e')),
        );
      }
    }
  }
}
