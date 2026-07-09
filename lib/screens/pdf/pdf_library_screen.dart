import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../models/pdf_document.dart';
import 'pdf_viewer_screen.dart';

class PdfLibraryScreen extends StatefulWidget {
  const PdfLibraryScreen({Key? key}) : super(key: key);

  @override
  State<PdfLibraryScreen> createState() => _PdfLibraryScreenState();
}

class _PdfLibraryScreenState extends State<PdfLibraryScreen> {
  late Box<PdfDocument> _pdfBox;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _pdfBox = Hive.box<PdfDocument>('pdf_library');
  }

  Future<void> _importPdf() async {
    setState(() => _isLoading = true);

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final sourceFile = File(result.files.single.path!);
        final fileName = result.files.single.name;

        // App-এর নিজস্ব folder-এ copy করুন
        final appDir = await getApplicationDocumentsDirectory();
        final pdfDir = Directory('${appDir.path}/pdfs');
        if (!await pdfDir.exists()) {
          await pdfDir.create(recursive: true);
        }

        final destPath =
            '${pdfDir.path}/${DateTime.now().millisecondsSinceEpoch}_$fileName';
        await sourceFile.copy(destPath);

        // Hive-এ save করুন
        final doc = PdfDocument(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: path.basenameWithoutExtension(fileName),
          filePath: destPath,
          dateAdded: DateTime.now(),
        );

        await _pdfBox.put(doc.id, doc);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF সফলভাবে যোগ হয়েছে!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _deletePdf(PdfDocument doc) async {
    // Confirm dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('PDF মুছে দিবেন?'),
        content: Text('"${doc.title}" মুছে দেওয়া হবে।'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('বাতিল'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('মুছুন', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // File delete
      final file = File(doc.filePath);
      if (await file.exists()) await file.delete();
      // Hive থেকে delete
      await doc.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          'PDF লাইব্রেরি',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: _pdfBox.listenable(),
        builder: (context, Box<PdfDocument> box, _) {
          final pdfs = box.values.toList()
            ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded));

          if (pdfs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.picture_as_pdf_outlined,
                    size: 80,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'কোনো PDF নেই',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'নিচের + বাটন চেপে PDF যোগ করুন',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pdfs.length,
            itemBuilder: (context, index) {
              final doc = pdfs[index];
              return _PdfCard(
                doc: doc,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PdfViewerScreen(document: doc),
                  ),
                ),
                onDelete: () => _deletePdf(doc),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _importPdf,
        backgroundColor: const Color(0xFF0F3460),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'PDF যোগ করুন',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

class _PdfCard extends StatelessWidget {
  final PdfDocument doc;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PdfCard({
    required this.doc,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF16213E),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 28),
        ),
        title: Text(
          doc.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'যোগ করা হয়েছে: ${_formatDate(doc.dateAdded)}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
            if (doc.lastPage > 0)
              Text(
                'শেষ পড়া: পৃষ্ঠা ${doc.lastPage + 1}',
                style: const TextStyle(color: Colors.blueAccent, fontSize: 12),
              ),
            if (doc.bookmarkedPages.isNotEmpty)
              Text(
                '${doc.bookmarkedPages.length}টি বুকমার্ক',
                style: const TextStyle(color: Colors.amber, fontSize: 12),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white54),
          color: const Color(0xFF0F3460),
          onSelected: (val) {
            if (val == 'delete') onDelete();
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red, size: 18),
                  SizedBox(width: 8),
                  Text('মুছুন', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
