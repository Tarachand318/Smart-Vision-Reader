
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_pdf_text/flutter_pdf_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

class PdfUploadScreen extends StatefulWidget {
  const PdfUploadScreen({super.key});

  @override
  State<PdfUploadScreen> createState() =>
      _PdfUploadScreenState();
}

class _PdfUploadScreenState extends State<PdfUploadScreen> {

  // आवाज और PDF से संबंधित variables
  final FlutterTts _tts = FlutterTts();

  List<File> _pdfFiles = [];

  String _pdfText = '';
  String _selectedName = '';

  bool _loading = false;
  bool _isSpeaking = false;

  // आवाज रोकने का नियंत्रण
  bool _stopRequested = false;

  @override
  void initState() {
    super.initState();

    _initializeTts();
    _loadPdfFiles();
  }

  // आवाज की प्रारंभिक सेटिंग
  Future<void> _initializeTts() async {
    try {
      await _tts.setLanguage('hi-IN');
      await _tts.setSpeechRate(0.45);
      await _tts.awaitSpeakCompletion(true);

      _tts.setStartHandler(() {
        if (mounted) {
          setState(() {
            _isSpeaking = true;
          });
        }
      });

      _tts.setCompletionHandler(() {
        if (mounted) {
          setState(() {
            _isSpeaking = false;
          });
        }
      });

      _tts.setCancelHandler(() {
        if (mounted) {
          setState(() {
            _isSpeaking = false;
          });
        }
      });

      _tts.setErrorHandler((message) {
        if (mounted) {
          setState(() {
            _isSpeaking = false;
          });
          _showMessage('आवाज में समस्या: $message');
        }
      });

    } catch (e) {
      _showMessage('आवाज की सेटिंग में समस्या: $e');
    }
  }

  // PDF रखने के लिए ऐप का निजी फोल्डर
  Future<Directory> _getPdfDirectory() async {
    final appDir =
        await getApplicationDocumentsDirectory();

    final pdfDir = Directory(
      '${appDir.path}/pdf_books',
    );

    if (!await pdfDir.exists()) {
      await pdfDir.create(recursive: true);
    }

    return pdfDir;
  }

  // पहले से अपलोड की गई PDF की सूची
  Future<void> _loadPdfFiles() async {
    try {
      final directory = await _getPdfDirectory();

      final files = directory
          .listSync()
          .whereType<File>()
          .where((file) =>
              file.path.toLowerCase().endsWith('.pdf'))
          .toList();

      files.sort(
        (a, b) => b.lastModifiedSync()
            .compareTo(a.lastModifiedSync()),
      );

      if (mounted) {
        setState(() {
          _pdfFiles = files;
        });
      }

    } catch (e) {
      _showMessage('PDF सूची खोलने में समस्या: $e');
    }
  }

  // मोबाइल से PDF अपलोड करना
  Future<void> _uploadPdf() async {
    try {
      final result =
          await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final pickedFile = result.files.single;

      if (pickedFile.path == null) {
        _showMessage('PDF फाइल का रास्ता उपलब्ध नहीं है।');
        return;
      }

      final sourceFile = File(pickedFile.path!);

      if (!await sourceFile.exists()) {
        _showMessage('चुनी गई PDF उपलब्ध नहीं है।');
        return;
      }

      final directory = await _getPdfDirectory();

      final safeName =
          '${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';

      final savedFile = await sourceFile.copy(
        '${directory.path}/$safeName',
      );

      await _loadPdfFiles();

      if (!mounted) return;

      _showMessage('PDF सफलतापूर्वक अपलोड हुई।');

      await _openPdf(savedFile);

    } catch (e) {
      _showMessage('PDF अपलोड नहीं हो सकी: $e');
    }
  }

  // PDF खोलना और उसका टेक्स्ट निकालना
  Future<void> _openPdf(File file) async {
    await _stopSpeaking();

    if (!mounted) return;

    setState(() {
      _loading = true;
      _pdfText = '';
      _selectedName = file.uri.pathSegments.last;
    });

    try {
      final document = await PDFDoc.fromFile(file);

      final extractedText = await document.text;

      if (!mounted) return;

      setState(() {
        _pdfText = extractedText;
        _loading = false;
      });

      if (extractedText.trim().isEmpty) {
        _showMessage(
          'इस PDF में पढ़ने योग्य टेक्स्ट नहीं मिला।',
        );
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }

      _showMessage('PDF पढ़ने में समस्या हुई: $e');
    }
  }

  // लंबे टेक्स्ट को छोटे हिस्सों में बाँटना
  List<String> _splitText(String text) {
    const maxLength = 2500;

    final words = text.split(RegExp(r'\s+'));

    final chunks = <String>[];

    String current = '';

    for (final word in words) {

      if (current.isNotEmpty &&
          current.length + word.length + 1 > maxLength) {

        chunks.add(current);
        current = '';
      }

      current += current.isEmpty ? word : ' $word';
    }

    if (current.isNotEmpty) {
      chunks.add(current);
    }

    return chunks;
  }

  // PDF को आवाज में सुनाना
  Future<void> _speakPdf() async {

    if (_pdfText.trim().isEmpty) {
      _showMessage('पहले PDF खोलें।');
      return;
    }

    // पिछली आवाज को पहले रोकना
    _stopRequested = true;
    await _tts.stop();

    // नई आवाज शुरू करने की अनुमति
    _stopRequested = false;

    if (mounted) {
      setState(() {
        _isSpeaking = false;
      });
    }

    final chunks = _splitText(_pdfText);

    try {
      for (final chunk in chunks) {

        if (_stopRequested || !mounted) {
          return;
        }

        await _tts.speak(chunk);

      }

    } catch (e) {
      _showMessage('पुस्तक सुनने में समस्या: $e');

    } finally {
      if (mounted && !_stopRequested) {
        setState(() {
          _isSpeaking = false;
        });
      }
    }
  }

  // आवाज रोकने का बटन
  Future<void> _stopSpeaking() async {

    _stopRequested = true;

    await _tts.stop();

    if (mounted) {
      setState(() {
        _isSpeaking = false;
      });
    }
  }

  // संदेश दिखाना
  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  void dispose() {
    _stopRequested = true;
    _tts.stop();
    super.dispose();
  }

  // स्क्रीन का डिजाइन
  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text('PDF पुस्तकालय'),
        centerTitle: true,
      ),

      body: ListView(

        padding: const EdgeInsets.all(16),

        children: [

          // PDF अपलोड बटन
          Semantics(
            button: true,
            label: 'मोबाइल से PDF पुस्तक अपलोड करें',

            child: ElevatedButton.icon(
              onPressed: _uploadPdf,
              icon: const Icon(Icons.upload_file),
              label: const Text('PDF अपलोड करें'),

              style: ElevatedButton.styleFrom(
                minimumSize: const Size(
                  double.infinity,
                  60,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'अपलोड की गई पुस्तकें',

            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          // PDF पुस्तकों की सूची
          if (_pdfFiles.isEmpty)
            const Text(
              'अभी कोई PDF पुस्तक उपलब्ध नहीं है।',
            ),

          ..._pdfFiles.map((file) {

            final name = file.uri.pathSegments.last;

            return Card(

              child: ListTile(

                leading: const Icon(
                  Icons.picture_as_pdf,
                  size: 35,
                ),

                title: Text(name),

                subtitle: const Text(
                  'पुस्तक खोलने के लिए चुनें',
                ),

                onTap: () => _openPdf(file),

              ),
            );
          }),

          const Divider(height: 30),

          // लोडिंग संकेत
          if (_loading)
            const Center(
              child: CircularProgressIndicator(),
            ),

          // चुनी गई PDF की सामग्री
          if (_selectedName.isNotEmpty && !_loading) ...[

            Text(
              _selectedName,

              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            // सुनने और रोकने के बटन
            Wrap(

              spacing: 10,
              runSpacing: 10,

              children: [

                ElevatedButton.icon(

                  onPressed:
                      _isSpeaking ? null : _speakPdf,

                  icon: const Icon(Icons.volume_up),

                  label: const Text('सुनें'),

                ),

                ElevatedButton.icon(

                  onPressed:
                      _isSpeaking ? _stopSpeaking : null,

                  icon: const Icon(Icons.stop),

                  label: const Text('रोकें'),

                ),

              ],
            ),

            const SizedBox(height: 20),

            const Text(
              'पढ़ने योग्य पुस्तक सामग्री',

              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            // PDF का टेक्स्ट पढ़ना
            SelectableText(

              _pdfText.isEmpty
                  ? 'इस पुस्तक में टेक्स्ट उपलब्ध नहीं है।'
                  : _pdfText,

              style: const TextStyle(
                fontSize: 19,
                height: 1.7,
              ),
            ),

          ],

        ],
      ),
    );
  }
}
