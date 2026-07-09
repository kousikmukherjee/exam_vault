import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import '../../models/pdf_document.dart';

class PdfViewerScreen extends StatefulWidget {
  final PdfDocument document;

  const PdfViewerScreen({Key? key, required this.document}) : super(key: key);

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  PDFViewController? _pdfViewController;
  late List<int> _bookmarks;
  int _currentPage = 0;
  int _totalPages = 0;
  bool _showBookmarks = false;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _bookmarks = List<int>.from(widget.document.bookmarkedPages);
    _currentPage = widget.document.lastPage;
  }

  void _toggleBookmark() {
    setState(() {
      if (_bookmarks.contains(_currentPage)) {
        _bookmarks.remove(_currentPage);
      } else {
        _bookmarks.add(_currentPage);
        _bookmarks.sort();
      }
    });
    _saveProgress();

    final isAdded = _bookmarks.contains(_currentPage);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isAdded
              ? 'পৃষ্ঠা ${_currentPage + 1} বুকমার্ক করা হয়েছে'
              : 'পৃষ্ঠা ${_currentPage + 1} বুকমার্ক সরানো হয়েছে',
        ),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.amber.shade700,
      ),
    );
  }

  void _saveProgress() {
    widget.document.lastPage = _currentPage;
    widget.document.bookmarkedPages = _bookmarks;
    widget.document.save();
  }

  void _jumpToPage(int page) {
    _pdfViewController?.setPage(page);
    setState(() => _showBookmarks = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: Text(
          widget.document.title,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          overflow: TextOverflow.ellipsis,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Bookmark toggle button
          IconButton(
            icon: Icon(
              _bookmarks.contains(_currentPage)
                  ? Icons.bookmark
                  : Icons.bookmark_border,
              color: _bookmarks.contains(_currentPage)
                  ? Colors.amber
                  : Colors.white,
            ),
            onPressed: _toggleBookmark,
            tooltip: 'বুকমার্ক',
          ),

          // Bookmark list button with badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.list, color: Colors.white),
                onPressed: () {
                  setState(() => _showBookmarks = !_showBookmarks);
                },
                tooltip: 'বুকমার্ক তালিকা',
              ),
              if (_bookmarks.isNotEmpty)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${_bookmarks.length}',
                      style: const TextStyle(color: Colors.black, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── PDF Viewer ──────────────────────────────────
          PDFView(
            filePath: widget.document.filePath,
            enableSwipe: true,
            swipeHorizontal: false,
            autoSpacing: true,
            pageFling: true,
            defaultPage: _currentPage,
            fitPolicy: FitPolicy.BOTH,
            onRender: (pages) {
              setState(() {
                _totalPages = pages ?? 0;
                _isReady = true;
              });
            },
            onViewCreated: (controller) {
              _pdfViewController = controller;
              // Last page-এ jump করুন
              if (_currentPage > 0) {
                Future.delayed(const Duration(milliseconds: 300), () {
                  _pdfViewController?.setPage(_currentPage);
                });
              }
            },
            onPageChanged: (page, total) {
              if (page != null) {
                setState(() => _currentPage = page);
                _saveProgress();
              }
            },
            onError: (error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('PDF লোড করা যায়নি: $error'),
                  backgroundColor: Colors.red,
                ),
              );
            },
          ),

          // ── Loading indicator ───────────────────────────
          if (!_isReady)
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          // ── Page indicator ──────────────────────────────
          if (_isReady)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'পৃষ্ঠা ${_currentPage + 1} / $_totalPages',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ),

          // ── Bookmark panel ──────────────────────────────
          if (_showBookmarks)
            Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              width: 220,
              child: Container(
                color: const Color(0xFF16213E),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: const Color(0xFF0F3460),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.bookmark,
                            color: Colors.amber,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'বুকমার্ক',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                            onPressed: () =>
                                setState(() => _showBookmarks = false),
                          ),
                        ],
                      ),
                    ),

                    // Empty state
                    if (_bookmarks.isEmpty)
                      Expanded(
                        child: Center(
                          child: Text(
                            'কোনো বুকমার্ক নেই',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                            ),
                          ),
                        ),
                      )
                    else
                      // Bookmark list
                      Expanded(
                        child: ListView.builder(
                          itemCount: _bookmarks.length,
                          itemBuilder: (ctx, i) {
                            final page = _bookmarks[i];
                            return ListTile(
                              leading: const Icon(
                                Icons.bookmark,
                                color: Colors.amber,
                                size: 18,
                              ),
                              title: Text(
                                'পৃষ্ঠা ${page + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: 16,
                                ),
                                onPressed: () {
                                  setState(() => _bookmarks.remove(page));
                                  _saveProgress();
                                },
                              ),
                              onTap: () => _jumpToPage(page),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _saveProgress();
    super.dispose();
  }
}
