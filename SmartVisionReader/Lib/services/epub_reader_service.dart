
import 'dart:io';
import 'dart:typed_data';

import 'package:epubx/epubx.dart' as epubx;
import 'package:html/parser.dart' as html_parser;

import 'tts_service.dart';

/// Represents one readable EPUB chapter.
class EpubChapterInfo {
  final String title;
  final String text;
  final int depth;

  const EpubChapterInfo({
    required this.title,
    required this.text,
    required this.depth,
  });
}

class EpubReaderService {
  EpubReaderService._internal();

  static final EpubReaderService instance =
      EpubReaderService._internal();

  epubx.EpubBook? _book;

  Uint8List? _bookBytes;

  String? _fileName;

  List<EpubChapterInfo> _chapters = [];

  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  String? get fileName => _fileName;

  String get bookTitle => _book?.Title ?? '';

  String get author => _book?.Author ?? '';

  int get chapterCount => _chapters.length;

  List<EpubChapterInfo> get chapters =>
      List.unmodifiable(_chapters);

  // --------------------------------------------------
  // 1. Load EPUB from device.
  // --------------------------------------------------

  Future<void> loadFromFile(String filePath) async {
    final file = File(filePath);

    if (!await file.exists()) {
      throw Exception('EPUB file does not exist.');
    }

    final extension = file.path.toLowerCase();

    if (!extension.endsWith('.epub')) {
      throw Exception('Please select a valid EPUB file.');
    }

    final bytes = await file.readAsBytes();

    await loadFromBytes(
      bytes,
      fileName: file.uri.pathSegments.last,
    );
  }

  // --------------------------------------------------
  // 2. Load EPUB from memory.
  // --------------------------------------------------

  Future<void> loadFromBytes(
    Uint8List bytes, {
    String? fileName,
  }) async {
    if (bytes.isEmpty) {
      throw Exception('EPUB file is empty.');
    }

    await closeBook();

    epubx.EpubBook? newBook;

    try {
      final copiedBytes = Uint8List.fromList(bytes);

      newBook = await epubx.EpubReader.readBook(
        copiedBytes,
      );

      final parsedChapters = <EpubChapterInfo>[];

      _collectChapters(
        newBook.Chapters,
        parsedChapters,
        0,
      );

      if (parsedChapters.isEmpty) {
        throw Exception(
          'No readable chapters found in this EPUB.',
        );
      }

      _book = newBook;
      _bookBytes = copiedBytes;
      _fileName = fileName;
      _chapters = parsedChapters;
      _isLoaded = true;
    } catch (e) {
      _book = null;
      _bookBytes = null;
      _chapters = [];
      _isLoaded = false;

      throw Exception('Unable to open EPUB: $e');
    }
  }

  // --------------------------------------------------
  // 3. Collect chapters and nested chapters.
  // --------------------------------------------------

  void _collectChapters(
    List<epubx.EpubChapter> source,
    List<EpubChapterInfo> output,
    int depth,
  ) {
    for (final chapter in source) {
      final title = chapter.Title.trim();

      final text = _htmlToText(
        chapter.HtmlContent,
      );

      if (text.isNotEmpty) {
        output.add(
          EpubChapterInfo(
            title: title.isEmpty
                ? 'Untitled Chapter'
                : title,
            text: text,
            depth: depth,
          ),
        );
      }

      if (chapter.SubChapters.isNotEmpty) {
        _collectChapters(
          chapter.SubChapters,
          output,
          depth + 1,
        );
      }
    }
  }

  // --------------------------------------------------
  // 4. Convert HTML into clean readable text.
  // --------------------------------------------------

  String _htmlToText(String htmlContent) {
    if (htmlContent.trim().isEmpty) {
      return '';
    }

    final document = html_parser.parse(
      htmlContent,
    );

    // Remove content that should not be spoken.
    document
        .querySelectorAll('script, style, noscript')
        .forEach((element) => element.remove());

    final text = document.body?.text ??
        document.documentElement?.text ??
        '';

    return _cleanText(text);
  }

  String _cleanText(String text) {
    return text
        .replaceAll('\u00A0', ' ')
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  // --------------------------------------------------
  // 5. Extract a particular chapter.
  // Chapter numbering starts from 1.
  // --------------------------------------------------

  String extractChapterText(int chapterNumber) {
    _checkLoaded();

    if (chapterNumber < 1 ||
        chapterNumber > _chapters.length) {
      throw RangeError(
        'Chapter number must be between 1 and $_chapters.length.',
      );
    }

    return _chapters[chapterNumber - 1].text;
  }

  // --------------------------------------------------
  // 6. Extract complete book text.
  // --------------------------------------------------

  String extractAllText() {
    _checkLoaded();

    return _chapters
        .map((chapter) {
          return '${chapter.title}\n\n${chapter.text}';
        })
        .join('\n\n');
  }

  // --------------------------------------------------
  // 7. Read text using TTS service.
  // --------------------------------------------------

  Future<void> speakText(
    String text, {
    String languageCode = 'hi-IN',
  }) async {
    if (text.trim().isEmpty) {
      throw Exception('No readable text available.');
    }

    await TtsService.instance.setLanguage(
      languageCode,
    );

    await TtsService.instance.speak(text);
  }

  // --------------------------------------------------
  // 8. Read a particular chapter.
  // --------------------------------------------------

  Future<void> readChapter(
    int chapterNumber, {
    String languageCode = 'hi-IN',
  }) async {
    final chapter = extractChapterText(
      chapterNumber,
    );

    await speakText(
      chapter,
      languageCode: languageCode,
    );
  }

  // --------------------------------------------------
  // 9. Read complete EPUB book.
  // --------------------------------------------------

  Future<void> readAll({
    String languageCode = 'hi-IN',
  }) async {
    final text = extractAllText();

    await speakText(
      text,
      languageCode: languageCode,
    );
  }

  // --------------------------------------------------
  // 10. Pause reading.
  // --------------------------------------------------

  Future<void> pauseReading() async {
    await TtsService.instance.pause();
  }

  // --------------------------------------------------
  // 11. Resume reading.
  // --------------------------------------------------

  Future<void> resumeReading() async {
    await TtsService.instance.resume();
  }

  // --------------------------------------------------
  // 12. Stop reading.
  // --------------------------------------------------

  Future<void> stopReading() async {
    await TtsService.instance.stop();
  }

  // --------------------------------------------------
  // 13. Search inside the EPUB book.
  // --------------------------------------------------

  List<EpubChapterInfo> searchText(String query) {
    _checkLoaded();

    if (query.trim().isEmpty) {
      return [];
    }

    final searchQuery = query.toLowerCase();

    return _chapters.where((chapter) {
      return chapter.text.toLowerCase().contains(
        searchQuery,
      );
    }).toList();
  }

  // --------------------------------------------------
  // 14. Check whether EPUB is loaded.
  // --------------------------------------------------

  void _checkLoaded() {
    if (!_isLoaded || _book == null) {
      throw StateError(
        'Please load an EPUB book first.',
      );
    }
  }

  // --------------------------------------------------
  // 15. Close EPUB book and clear memory.
  // --------------------------------------------------

  Future<void> closeBook() async {
    await TtsService.instance.stop();

    _book = null;
    _bookBytes = null;
    _fileName = null;

    _chapters = [];

    _isLoaded = false;
  }

  // --------------------------------------------------
  // 16. Release resources.
  // --------------------------------------------------

  Future<void> dispose() async {
    await closeBook();
  }
}
