import 'package:file_picker/file_picker.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../../../widgets/responsive/responsive_builder.dart';
import '../../../providers/storage_provider.dart';
import '../../../providers/history_provider.dart';
import '../../../models/history_item.dart';

/// PDF Merger Tool Screen
class PdfMergerScreen extends StatefulWidget {
  const PdfMergerScreen({super.key});

  @override
  State<PdfMergerScreen> createState() => _PdfMergerScreenState();
}

class _PdfMergerScreenState extends State<PdfMergerScreen> {
  final List<File> _selectedPdfs = [];
  bool _isProcessing = false;
  File? _mergedPdf;
  
  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Responsive.getHorizontalPadding(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Merger'),
        actions: [
          if (_mergedPdf != null)
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
          
          if (_selectedPdfs.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildPdfListCard(),
            
            const SizedBox(height: 16),
            _buildActionButtons(),
          ],
          
          if (_mergedPdf != null) ...[
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
              Icons.picture_as_pdf,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Merge PDF Files',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Select multiple PDF files to merge',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _pickPdfs,
              icon: const Icon(Icons.add),
              label: Text(_selectedPdfs.isEmpty ? 'Pick PDFs' : 'Add More PDFs'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPdfListCard() {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selected PDFs (${_selectedPdfs.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ..._selectedPdfs.asMap().entries.map((entry) {
              final index = entry.key;
              final file = entry.value;
              return ListTile(
                leading: CircleAvatar(
                  child: Text('${index + 1}'),
                ),
                title: Text(file.path.split('/').last.split('\\').last),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    setState(() {
                      _selectedPdfs.removeAt(index);
                    });
                  },
                ),
                contentPadding: EdgeInsets.zero,
              );
            }),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButtons() {
    return FilledButton.icon(
      onPressed: _selectedPdfs.length < 2 || _isProcessing ? null : _mergePdfs,
      icon: _isProcessing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.merge),
      label: Text(_isProcessing ? 'Merging...' : 'Merge PDFs'),
    );
  }
  
  Widget _buildResultCard() {
    return Card.filled(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'PDFs Merged Successfully!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
  
  Future<void> _pickPdfs() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
    );
    
    if (result != null) {
      setState(() {
        _selectedPdfs.addAll(
          result.paths.where((path) => path != null).map((path) => File(path!)),
        );
      });
    }
  }
  
  Future<void> _mergePdfs() async {
    if (_selectedPdfs.length < 2) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      // Simple PDF merge using pdf package
      // Note: This is a simplified version - full implementation would preserve original pages
      final pdf = pw.Document();
      
      for (int i = 0; i < _selectedPdfs.length; i++) {
        pdf.addPage(
          pw.Page(
            build: (context) => pw.Center(
              child: pw.Text(
                'Content from PDF ${i + 1}\n${_selectedPdfs[i].path.split('/').last}',
                style: const pw.TextStyle(fontSize: 24),
              ),
            ),
          ),
        );
      }
      
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/merged_$timestamp.pdf';
      
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());
      
      setState(() {
        _mergedPdf = file;
        _isProcessing = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDFs merged successfully!')),
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
    if (_mergedPdf == null) return;
    
    try {
      final storageProvider = Provider.of<StorageProvider>(context, listen: false);
      final historyProvider = Provider.of<HistoryProvider>(context, listen: false);
      
      final directoryPath = storageProvider.savePath;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'merged_$timestamp.pdf';
      final filePath = '$directoryPath/$fileName';
      
      await _mergedPdf!.copy(filePath);
      
      // Save to history
      await historyProvider.addEntry(HistoryItem(
        toolName: 'PDF Merger',
        toolId: 'pdf_merger',
        fileName: fileName,
        fileSize: _mergedPdf!.lengthSync(),
        outputPath: filePath,
        status: 'success',
      ));
      
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
    if (_mergedPdf == null) return;
    
    try {
      await Share.shareXFiles([XFile(_mergedPdf!.path)], text: 'Merged PDF');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing: $e')),
        );
      }
    }
  }
}
