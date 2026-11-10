
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TextReaderScreen extends StatefulWidget {
  const TextReaderScreen({super.key});

  @override
  State<TextReaderScreen> createState() =>
      _TextReaderScreenState();
}

class _TextReaderScreenState
    extends State<TextReaderScreen> {

  final TextEditingController controller =
      TextEditingController();

  final FlutterTts flutterTts = FlutterTts();

  bool isSpeaking = false;

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
  }

  Future<void> readText() async {
    final text = controller.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('कृपया टेक्स्ट लिखें।'),
        ),
      );
      return;
    }

    await flutterTts.setLanguage('hi-IN');
    await flutterTts.setSpeechRate(0.45);

    setState(() {
      isSpeaking = true;
    });

    await flutterTts.speak(text);
  }

  Future<void> stopText() async {
    await flutterTts.stop();

    if (mounted) {
      setState(() {
        isSpeaking = false;
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('टेक्स्ट रीडर'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'अपना टेक्स्ट यहाँ लिखें या पेस्ट करें।',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: 'यहाँ टेक्स्ट लिखें...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isSpeaking ? null : readText,
                icon: const Icon(Icons.volume_up),
                label: const Text('आवाज में पढ़ें'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isSpeaking ? stopText : null,
                icon: const Icon(Icons.stop),
                label: const Text('आवाज रोकें'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
