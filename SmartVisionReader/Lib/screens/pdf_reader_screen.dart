
import 'dart:io';
import 'dart:typed_data';

import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'tts_service.dart';

/// OCR callback:
/// The future OCR service can implement this callback
/// to extract text from scanned PDF pages.
typedef PdfOcrFallback = Future<String> Function(
  Uint8List pdfBytes,
  int zeroBasedPageIndex,
);

class PdfReaderService {
  PdfReaderService._internal();

  static final PdfReaderService instance =
      PdfReaderService._internal();

  PdfDocument? _document;

  Uint8List? _pdfBytes;

  String? _fileName;

  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  String? get fileName => _fileName;

  int get pageCount => _document?.pages.count ?? 0;

  /// Load PDF from device file.
  Future<void> loadFromFile(String filePath) async {
    final file = File(filePath);

    if (!await file.exists()) {
      throw Exception('PDF file does not exist.');
    }

    final bytes = await file.readAsBytes();

    await loadFromBytes(
      bytes,
      fileName: file.uri.pathSegments.last,
    );
  }

  /// Load PDF from memory.
  /// Useful for file picker and future integrations.
  Future<void> loadFromBytes(
    Uint8List bytes, {
    String? fileName,
  }) async {
    if (bytes.isEmpty) {
      throw Exception('PDF file is empty.');
    }

    await closePdf();

    PdfDocument? newDocument;

    try {
      final copiedBytes = Uint8List.fromList(bytes);

      newDocument = PdfDocument(
        inputBytes: copiedBytes,
      );

      final count = newDocument.pages.count;

      if (count <= 0) {
        throw Exception('PDF has no readable pages.');
      }

      _document = newDocument;
      _pdfBytes = copiedBytes;
      _fileName = fileName;
      _isLoaded = true;
    } catch (e) {
      newDocument?.dispose();
      rethrow;
    }
  }

  /// Extract text from a specific page.
  /// Page numbers start from 1.
  Future<String> extractPageText(
    int pageNumber, {
    PdfOcrFallback? ocrFallback,
  }) async {
    _checkLoaded();

    if (pageNumber < 1 || pageNumber > pageCount) {
      throw RangeError(
        'Page number must be between 1 and $pageCount.',
      );
    }

    final document = _document!;

    try {
      String text = PdfTextExtractor(document).extractText(
        startPageIndex: pageNumber - 1,
        endPageIndex: pageNumber - 1,
      );

      text = _cleanText(text);

      // Scanned PDF fallback.
      if (text.isEmpty && ocrFallback != null) {
        text = await ocrFallback(
          _pdfBytes!,
          pageNumber - 1,
        );

        text = _cleanText(text);
      }

      return text;
    } catch (e) {
      throw Exception(
        'Unable to extract text from page $pageNumber: $e',
      );
    }
  }

  /// Extract text from the entire PDF.
  Future<String> extractAllText({
    PdfOcrFallback? ocrFallback,
  }) async {
    _checkLoaded();

    final List<String> pageTexts = [];

    for (int page = 1; page <= pageCount; page++) {
      final text = await extractPageText(
        page,
        ocrFallback: ocrFallback,
      );

      if (text.isNotEmpty) {
        pageTexts.add(text);
      }
    }

    return pageTexts.join('\n\n');
  }

  /// Extract all pages separately.
  Future<List<String>> extractAllPagesText({
    PdfOcrFallback? ocrFallback,
  }) async {
    _checkLoaded();

    final List<String> pages = [];

    for (int page = 1; page <= pageCount; page++) {
      pages.add(
        await extractPageText(
          page,
          ocrFallback: ocrFallback,
        ),
      );
    }

    return pages;
  }

  /// Read extracted text using TTS.
  Future<void> speakText(
    String text, {
    String languageCode = 'hi-IN',
  }) async {
    if (text.trim().isEmpty) {
      throw Exception('There is no text to read.');
    }

    await TtsService.instance.setLanguage(languageCode);

    await TtsService.instance.speak(text);
  }

  /// Read a particular PDF page.
  Future<void> readPage(
    int pageNumber, {
    String languageCode = 'hi-IN',
    PdfOcrFallback? ocrFallback,
  }) async {
    final text = await extractPageText(
      pageNumber,
      ocrFallback: ocrFallback,
    );

    if (text.isEmpty) {
      throw Exception(
        'No readable text found on this page. OCR may be required.',
      );
    }

    await speakText(
      text,
      languageCode: languageCode,
    );
  }

  /// Read the complete PDF.
  Future<void> readAll({
    String languageCode = 'hi-IN',
    PdfOcrFallback? ocrFallback,
  }) async {
    final text = await extractAllText(
      ocrFallback: ocrFallback,
    );

    if (text.isEmpty) {
      throw Exception(
        'No readable text found in this PDF.',
      );
    }

    await speakText(
      text,
      languageCode: languageCode,
    );
  }

  /// Pause reading.
  Future<void> pauseReading() async {
    await TtsService.instance.pause();
  }

  /// Resume reading.
  Future<void> resumeReading() async {
    await TtsService.instance.resume();
  }

  /// Stop reading.
  Future<void> stopReading() async {
    await TtsService.instance.stop();
  }

  /// Stop speech and close the PDF document.
  Future<void> closePdf() async {
    await TtsService.instance.stop();

    final oldDocument = _document;

    _document = null;
    _pdfBytes = null;
    _fileName = null;
    _isLoaded = false;

    oldDocument?.dispose();
  }

  /// Check whether PDF is loaded.
  void _checkLoaded() {
    if (!_isLoaded || _document == null) {
      throw StateError(
        'Please load a PDF before extracting text.',
      );
    }
  }

  /// Clean unnecessary whitespace.
  String _cleanText(String text) {
    return text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  /// Release resources.
  Future<void> dispose() async {
    await closePdf();
  }
}
