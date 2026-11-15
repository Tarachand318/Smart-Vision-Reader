
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdfx/pdfx.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ScanPdfScreen extends StatefulWidget {
  const ScanPdfScreen({super.key});

  @override
  State<ScanPdfScreen> createState() =>
      _ScanPdfScreenState();
}

class _ScanPdfScreenState extends State<ScanPdfScreen> {
  final FlutterTts flutterTts = FlutterTts();

  final TextRecognizer textRecognizer = TextRecognizer(
    script: TextRecognitionScript.devanagiri,
  );

  String extractedText = '';
  String fileName = '';

  bool isProcessing = false;
  bool isSpeaking = false;

  String status = 'अपनी PDF पुस्तक चुनें';

  @override
  void initState() {
    super.initState();

    flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          isSpeaking = false;
        });
      }
    });

    flutterTts.setErrorHandler((message) {
      if (mounted) {
        setState(() {
          isSpeaking = false;
          status = 'आवाज में समस्या: $message';
        });
      }
    });
  }

  Future<void> pickAndReadPdf() async {
    await stopSpeaking();

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final path = result.files.single.path;

    if (path == null) {
      showMessage('PDF फाइल का रास्ता नहीं मिला।');
      return;
    }

    setState(() {
      fileName = result.files.single.name;
      extractedText = '';
      isProcessing = true;
      status = 'PDF पढ़ी जा रही है...';
    });

    PdfDocument? document;

    try {
      document = await PdfDocument.openFile(path);

      final tempDirectory =
          await getTemporaryDirectory();

      String fullText = '';

      final totalPages = document.pagesCount;

      for (int i = 1; i <= totalPages; i++) {
        if (!mounted) return;

        setState(() {
          status = 'पृष्ठ $i / $totalPages स्कैन हो रहा है';
        });

        final page = await document.getPage(i);

        try {
          final pageImage = await page.render(
            width: page.width * 2,
            height: page.height * 2,
            format: PdfPageImageFormat.PNG,
          );

          if (pageImage == null) {
            continue;
          }

          final imageFile = File(
            '${tempDirectory.path}/ocr_page_$i.png',
          );

          await imageFile.writeAsBytes(pageImage.bytes);

          try {
            final inputImage =
                InputImage.fromFilePath(imageFile.path);

            final recognizedText =
                await textRecognizer.processImage(inputImage);

            fullText +=
                '\n\nपृष्ठ संख्या $i\n\n${recognizedText.text}';

          } finally {
            if (await imageFile.exists()) {
              await imageFile.delete();
            }
          }
        } finally {
          await page.close();
        }
      }

      if (!mounted) return;

      setState(() {
        extractedText = fullText.trim();
        isProcessing = false;

        status = extractedText.isEmpty
            ? 'इस PDF में पढ़ने योग्य टेक्स्ट नहीं मिला।'
            : 'PDF सफलतापूर्वक पढ़ ली गई।';
      });

      if (extractedText.isNotEmpty) {
        showMessage('PDF की सामग्री पहचान ली गई है।');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isProcessing = false;
          status = 'PDF पढ़ने में समस्या आई।';
        });

        showMessage('त्रुटि: $e');
      }
    } finally {
      if (document != null) {
        await document.close();
      }

      if (mounted && isProcessing) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  Future<void> speakText() async {
    if (extractedText.isEmpty) {
      showMessage('पहले PDF चुनकर स्कैन करें।');
      return;
    }

    try {
      await flutterTts.stop();
      await flutterTts.setLanguage('hi-IN');
      await flutterTts.setSpeechRate(0.45);
      await flutterTts.setVolume(1.0);
      await flutterTts.awaitSpeakCompletion(true);

      setState(() {
        isSpeaking = true;
        status = 'PDF सुनाई जा रही है...';
      });

      // लंबे टेक्स्ट को छोटे भागों में पढ़ना
      final chunks = <String>[];

      for (int i = 0; i < extractedText.length; i += 2000) {
        final end = (i + 2000 < extractedText.length)
            ? i + 2000
            : extractedText.length;

        chunks.add(extractedText.substring(i, end));
      }

      for (final chunk in chunks) {
        if (!mounted || !isSpeaking) break;

        await flutterTts.speak(chunk);
      }

      if (mounted) {
        setState(() {
          isSpeaking = false;
          status = 'पढ़ना पूरा हुआ।';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isSpeaking = false;
          status = 'आवाज चलाने में समस्या आई।';
        });
      }
    }
  }

  Future<void> stopSpeaking() async {
    await flutterTts.stop();

    if (mounted) {
      setState(() {
        isSpeaking = false;
      });
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    flutterTts.stop();
    textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('स्कैन PDF पढ़ें और सुनें'),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.picture_as_pdf,
              size: 75,
              color: Colors.red,
            ),

            const SizedBox(height: 15),

            const Text(
              'अपनी स्कैन PDF पुस्तक चुनें',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: isProcessing
                  ? null
                  : pickAndReadPdf,
              icon: const Icon(Icons.folder_open),
              label: const Text('PDF चुनें और स्कैन करें'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(55),
              ),
            ),

            const SizedBox(height: 20),

            if (fileName.isNotEmpty)
              Semantics(
                liveRegion: true,
                child: Text(
                  'चुनी गई फाइल: $fileName',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            const SizedBox(height: 12),

            Semantics(
              liveRegion: true,
              child: Text(
                status,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ),

            if (isProcessing) ...[
              const SizedBox(height: 15),
              const LinearProgressIndicator(),
            ],

            const SizedBox(height: 20),

            if (extractedText.isNotEmpty) ...[
              ElevatedButton.icon(
                onPressed: isSpeaking ? null : speakText,
                icon: const Icon(Icons.volume_up),
                label: const Text('पुस्तक सुनें'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(55),
                ),
              ),

              const SizedBox(height: 10),

              ElevatedButton.icon(
                onPressed: isSpeaking
                    ? stopSpeaking
                    : null,
                icon: const Icon(Icons.stop),
                label: const Text('आवाज रोकें'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(55),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'पहचानी गई पुस्तक की सामग्री',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              SelectableText(
                extractedText,
                style: const TextStyle(
                  fontSize: 18,
                  height: 1.7,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
