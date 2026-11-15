
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
  bool isPaused = false;

  String selectedLanguage = 'hi-IN';
  double speechRate = 0.45;

  @override
  void initState() {
    super.initState();

    flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          isSpeaking = false;
          isPaused = false;
        });
      }
    });

    flutterTts.setPauseHandler(() {
      if (mounted) {
        setState(() {
          isSpeaking = false;
          isPaused = true;
        });
      }
    });

    flutterTts.setContinueHandler(() {
      if (mounted) {
        setState(() {
          isSpeaking = true;
          isPaused = false;
        });
      }
    });

    flutterTts.setStartHandler(() {
      if (mounted) {
        setState(() {
          isSpeaking = true;
          isPaused = false;
        });
      }
    });

    flutterTts.setErrorHandler((message) {
      if (mounted) {
        setState(() {
          isSpeaking = false;
          isPaused = false;
        });
      }
    });
  }

  Future<void> readText() async {
    final text = controller.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('कृपया पहले टेक्स्ट लिखें।'),
        ),
      );
      return;
    }

    try {
      await flutterTts.setLanguage(selectedLanguage);
      await flutterTts.setSpeechRate(speechRate);

      setState(() {
        isSpeaking = true;
        isPaused = false;
      });

      await flutterTts.speak(text);

    } catch (e) {
      if (mounted) {
        setState(() {
          isSpeaking = false;
          isPaused = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('आवाज शुरू नहीं हो सकी।'),
          ),
        );
      }
    }
  }

  Future<void> pauseText() async {
    await flutterTts.pause();

    if (mounted) {
      setState(() {
        isSpeaking = false;
        isPaused = true;
      });
    }
  }

  Future<void> resumeText() async {
    try {
      await flutterTts.setLanguage(selectedLanguage);
      await flutterTts.setSpeechRate(speechRate);

      // Pause के बाद TTS को जारी रखें।
      await flutterTts.speak(controller.text.trim());

      if (mounted) {
        setState(() {
          isSpeaking = true;
          isPaused = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('दोबारा आवाज शुरू नहीं हो सकी।'),
          ),
        );
      }
    }
  }

  Future<void> stopText() async {
    await flutterTts.stop();

    if (mounted) {
      setState(() {
        isSpeaking = false;
        isPaused = false;
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
        title: const Text('Listen Books - सुनें'),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            const Icon(
              Icons.headphones,
              size: 75,
              color: Colors.blue,
              semanticLabel: 'किताब सुनने की सुविधा',
            ),

            const SizedBox(height: 12),

            const Text(
              'अपनी किताब सुनें',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'भाषा चुनें',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              value: selectedLanguage,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'hi-IN',
                  child: Text('हिंदी'),
                ),
                DropdownMenuItem(
                  value: 'en-US',
                  child: Text('English'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedLanguage = value;
                  });
                }
              },
            ),

            const SizedBox(height: 22),

            const Text(
              'आवाज की गति',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            Slider(
              value: speechRate,
              min: 0.2,
              max: 0.8,
              divisions: 6,
              label: speechRate.toStringAsFixed(2),
              onChanged: (value) {
                setState(() {
                  speechRate = value;
                });
              },
            ),

            const SizedBox(height: 12),

            const Text(
              'अपना टेक्स्ट यहाँ लिखें या पेस्ट करें।',
              style: TextStyle(fontSize: 17),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: controller,
              readOnly: isSpeaking || isPaused,
              maxLines: 8,
              minLines: 5,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                hintText: 'यहाँ किताब का टेक्स्ट लिखें...',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 22),

            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                onPressed: (!isSpeaking && !isPaused)
                    ? readText
                    : null,
                icon: const Icon(Icons.volume_up, size: 27),
                label: const Text(
                  'आवाज में पढ़ें',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                onPressed: isSpeaking ? pauseText : null,
                icon: const Icon(Icons.pause, size: 27),
                label: const Text(
                  'आवाज रोककर रखें',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                onPressed: isPaused ? resumeText : null,
                icon: const Icon(Icons.play_arrow, size: 27),
                label: const Text(
                  'दोबारा सुनें',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                onPressed:
                    (isSpeaking || isPaused) ? stopText : null,
                icon: const Icon(Icons.stop, size: 27),
                label: const Text(
                  'पूरी तरह बंद करें',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              isSpeaking
                  ? 'आवाज चल रही है।'
                  : isPaused
                      ? 'आवाज रोकी गई है।'
                      : 'सुनने के लिए टेक्स्ट तैयार है।',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
