
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

class ReaderLanguage {
  final String name;
  final String code;
  final TextDirection direction;

  const ReaderLanguage(
    this.name,
    this.code, {
    this.direction = TextDirection.ltr,
  });
}

class BookReaderScreen extends StatefulWidget {
  final String bookTitle;
  final String bookText;

  const BookReaderScreen({
    super.key,
    this.bookTitle = 'पुस्तक पाठक',
    this.bookText = '',
  });

  @override
  State<BookReaderScreen> createState() =>
      _BookReaderScreenState();
}

class _BookReaderScreenState extends State<BookReaderScreen> {
  final FlutterTts _tts = FlutterTts();

  late final TextEditingController _textController;
  late final ScrollController _scrollController;

  final List<ReaderLanguage> _languages = const [
    ReaderLanguage('हिंदी', 'hi-IN'),
    ReaderLanguage('अंग्रेजी', 'en-IN'),
    ReaderLanguage('असमिया', 'as-IN'),
    ReaderLanguage('बंगाली', 'bn-IN'),
    ReaderLanguage('बोडो', 'brx-IN'),
    ReaderLanguage('डोगरी', 'doi-IN'),
    ReaderLanguage('गुजराती', 'gu-IN'),
    ReaderLanguage('कन्नड़', 'kn-IN'),
    ReaderLanguage('कश्मीरी', 'ks-IN'),
    ReaderLanguage('कोंकणी', 'kok-IN'),
    ReaderLanguage('मैथिली', 'mai-IN'),
    ReaderLanguage('मलयालम', 'ml-IN'),
    ReaderLanguage('मणिपुरी', 'mni-IN'),
    ReaderLanguage('मराठी', 'mr-IN'),
    ReaderLanguage('नेपाली', 'ne-NP'),
    ReaderLanguage('ओड़िया', 'or-IN'),
    ReaderLanguage('पंजाबी', 'pa-IN'),
    ReaderLanguage('संस्कृत', 'sa-IN'),
    ReaderLanguage('संथाली', 'sat-IN'),
    ReaderLanguage('सिंधी', 'sd-IN'),
    ReaderLanguage('तमिल', 'ta-IN'),
    ReaderLanguage('तेलुगु', 'te-IN'),
    ReaderLanguage(
      'उर्दू',
      'ur-IN',
      direction: TextDirection.rtl,
    ),
  ];

  String _selectedLanguage = 'hi-IN';

  List<String> _availableLanguages = [];

  double _speechRate = 0.45;
  double _speechPitch = 1.0;
  double _fontSize = 22;

  bool _isSpeaking = false;
  bool _isPaused = false;
  bool _isLoading = false;
  bool _isStopping = false;
  bool _isInitialized = false;

  String _status = 'पुस्तक पढ़ने के लिए तैयार';

  ReaderLanguage get _currentLanguage =>
      _languages.firstWhere(
        (language) => language.code == _selectedLanguage,
      );

  @override
  void initState() {
    super.initState();

    _textController = TextEditingController(
      text: widget.bookText,
    );

    _scrollController = ScrollController();

    _initializeTts();
  }

  Future<void> _initializeTts() async {
    try {
      await _tts.awaitSpeakCompletion(true);

      _tts.setStartHandler(() {
        if (mounted) {
          setState(() {
            _status = 'पुस्तक सुनाई जा रही है';
          });
        }
      });

      _tts.setCompletionHandler(() {
        if (mounted && !_isStopping) {
          setState(() {
            _isSpeaking = false;
            _isPaused = false;
            _isLoading = false;
            _status = 'पुस्तक सुनना पूरा हुआ';
          });
        }
      });

      _tts.setCancelHandler(() {
        if (mounted) {
          setState(() {
            _isSpeaking = false;
            _isPaused = false;
            _isLoading = false;
          });
        }
      });

      _tts.setErrorHandler((message) {
        if (mounted) {
          setState(() {
            _isSpeaking = false;
            _isLoading = false;
            _status = 'आवाज में समस्या हुई';
          });
        }
      });

      final result = await _tts.getLanguages;

      if (result is List) {
        _availableLanguages = result
            .map((e) => e.toString().toLowerCase())
            .toList();
      }

      await _tts.setSpeechRate(_speechRate);
      await _tts.setPitch(_speechPitch);
      await _tts.setLanguage(_selectedLanguage);

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _status = 'पुस्तक पढ़ने के लिए तैयार';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = 'TTS सेवा शुरू नहीं हो सकी';
        });
      }
    }
  }

  bool _isLanguageAvailable(String code) {
    final languageCode = code.split('-').first.toLowerCase();

    return _availableLanguages.any((locale) {
      return locale.split('-').first == languageCode;
    });
  }

  Future<void> _changeLanguage(String? code) async {
    if (code == null) return;

    await _stopSpeech();

    try {
      await _tts.setLanguage(code);

      if (!mounted) return;

      setState(() {
        _selectedLanguage = code;
        _status = 'भाषा बदल दी गई';
      });
    } catch (e) {
      _showMessage(
        'इस भाषा की आवाज उपलब्ध नहीं है।',
      );
    }
  }

  List<String> _makeChunks(String text) {
    final words = text.trim().split(RegExp(r'\s+'));

    final chunks = <String>[];
    String current = '';

    for (final word in words) {
      if ((current.length + word.length + 1) > 2000) {
        if (current.isNotEmpty) {
          chunks.add(current);
        }
        current = word;
      } else {
        current = current.isEmpty
            ? word
            : '$current $word';
      }
    }

    if (current.isNotEmpty) {
      chunks.add(current);
    }

    return chunks;
  }

  Future<void> _speakText() async {
    final text = _textController.text.trim();

    if (text.isEmpty) {
      _showMessage('पुस्तक में कोई टेक्स्ट उपलब्ध नहीं है।');
      return;
    }

    if (!_isInitialized) {
      _showMessage('आवाज सेवा अभी तैयार नहीं है।');
      return;
    }

    if (!_isLanguageAvailable(_selectedLanguage)) {
      _showMessage(
        'इस भाषा की आवाज आपके मोबाइल में उपलब्ध नहीं है।',
      );
      return;
    }

    await _stopSpeech();

    _isStopping = false;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _isSpeaking = true;
        _isPaused = false;
        _status = 'पुस्तक तैयार की जा रही है';
      });
    }

    try {
      await _tts.setLanguage(_selectedLanguage);
      await _tts.setSpeechRate(_speechRate);
      await _tts.setPitch(_speechPitch);

      final chunks = _makeChunks(text);

      for (final chunk in chunks) {
        if (_isStopping) break;

        await _tts.speak(chunk);
      }

      if (mounted && !_isStopping) {
        setState(() {
          _isSpeaking = false;
          _isLoading = false;
          _status = 'पुस्तक सुनना पूरा हुआ';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _isLoading = false;
          _status = 'पुस्तक सुनाने में समस्या हुई';
        });
      }
    }
  }

  Future<void> _pauseSpeech() async {
    if (!_isSpeaking || _isPaused) return;

    try {
      final result = await _tts.pause();

      if (result == 1 && mounted) {
        setState(() {
          _isPaused = true;
          _status = 'पुस्तक रोकी गई';
        });
      } else {
        _showMessage(
          'आपका TTS इंजन Pause सुविधा का समर्थन नहीं करता।',
        );
      }
    } catch (e) {
      _showMessage('Pause सुविधा उपलब्ध नहीं है।');
    }
  }

  Future<void> _resumeSpeech() async {
    // सुरक्षित और संगत विकल्प:
    // वर्तमान पुस्तक को शुरुआत से दोबारा सुनाना।
    await _speakText();
  }

  Future<void> _stopSpeech() async {
    _isStopping = true;

    try {
      await _tts.stop();
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isSpeaking = false;
        _isPaused = false;
        _isLoading = false;
        _status = 'पुस्तक सुनना बंद किया गया';
      });
    }
  }

  Future<void> _copyText() async {
    final text = _textController.text;

    if (text.trim().isEmpty) {
      _showMessage('कॉपी करने के लिए टेक्स्ट नहीं है।');
      return;
    }

    await Clipboard.setData(
      ClipboardData(text: text),
    );

    _showMessage('टेक्स्ट कॉपी हो गया।');
  }

  void _increaseFont() {
    setState(() {
      if (_fontSize < 36) {
        _fontSize += 2;
      }
    });
  }

  void _decreaseFont() {
    setState(() {
      if (_fontSize > 16) {
        _fontSize -= 2;
      }
    });
  }

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
    _tts.stop();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageAvailable =
        _isLanguageAvailable(_selectedLanguage);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.bookTitle),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'टेक्स्ट कॉपी करें',
            onPressed: _copyText,
            icon: const Icon(Icons.copy),
          ),
        ],
      ),

      body: SafeArea(
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          children: [

            // Language selection

            const Text(
              'अध्ययन की भाषा चुनें',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Semantics(
              label: 'पुस्तक की भाषा चुनें',
              child: DropdownButtonFormField<String>(
                value: _selectedLanguage,
                isExpanded: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.language),
                  border: OutlineInputBorder(),
                ),
                items: _languages.map((language) {
                  return DropdownMenuItem<String>(
                    value: language.code,
                    child: Text(language.name),
                  );
                }).toList(),
                onChanged: _changeLanguage,
              ),
            ),

            const SizedBox(height: 10),

            if (_availableLanguages.isNotEmpty)
              Semantics(
                liveRegion: true,
                child: Text(
                  languageAvailable
                      ? 'इस भाषा का TTS समर्थन मोबाइल में उपलब्ध है।'
                      : 'इस भाषा की आवाज मोबाइल में उपलब्ध नहीं है।',
                  style: TextStyle(
                    color: languageAvailable
                        ? Colors.green
                        : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            const SizedBox(height: 22),

            // Reader text

            const Text(
              'पुस्तक की सामग्री',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Semantics(
                label: 'पुस्तक पढ़ने का क्षेत्र',
                child: TextField(
                  controller: _textController,
                  maxLines: 14,
                  textDirection: _currentLanguage.direction,
                  textAlign: _currentLanguage.direction ==
                          TextDirection.rtl
                      ? TextAlign.right
                      : TextAlign.start,
                  style: TextStyle(
                    fontSize: _fontSize,
                    height: 1.8,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'यहाँ पुस्तक का टेक्स्ट उपलब्ध होगा...',
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Font controls

            const Text(
              'अक्षरों का आकार',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            Row(
              children: [
                IconButton(
                  tooltip: 'अक्षर छोटे करें',
                  onPressed: _decreaseFont,
                  icon: const Icon(Icons.remove_circle_outline),
                ),

                Expanded(
                  child: Slider(
                    value: _fontSize,
                    min: 16,
                    max: 36,
                    divisions: 10,
                    label: _fontSize.toInt().toString(),
                    onChanged: (value) {
                      setState(() {
                        _fontSize = value;
                      });
                    },
                  ),
                ),

                IconButton(
                  tooltip: 'अक्षर बड़े करें',
                  onPressed: _increaseFont,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Audio controls

            const Text(
              'पुस्तक सुनने की सुविधा',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [

                ElevatedButton.icon(
                  onPressed: _isSpeaking || _isLoading
                      ? null
                      : _speakText,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('सुनें'),
                ),

                ElevatedButton.icon(
                  onPressed: _isSpeaking && !_isPaused
                      ? _pauseSpeech
                      : null,
                  icon: const Icon(Icons.pause),
                  label: const Text('रोकें'),
                ),

                ElevatedButton.icon(
                  onPressed: _isPaused
                      ? _resumeSpeech
                      : null,
                  icon: const Icon(Icons.replay),
                  label: const Text('दोबारा सुनें'),
                ),

                ElevatedButton.icon(
                  onPressed: _isSpeaking || _isPaused
                      ? _stopSpeech
                      : null,
                  icon: const Icon(Icons.stop),
                  label: const Text('बंद करें'),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Semantics(
              liveRegion: true,
              child: Text(
                _status,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 22),

            // Speech rate

            Text(
              'आवाज की गति: ${_speechRate.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            Slider(
              value: _speechRate,
              min: 0.1,
              max: 0.8,
              divisions: 14,
              onChanged: (value) {
                setState(() {
                  _speechRate = value;
                });
              },
            ),

            const SizedBox(height: 10),

            // Speech pitch

            Text(
              'आवाज का पिच: ${_speechPitch.toStringAsFixed(1)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            Slider(
              value: _speechPitch,
              min: 0.5,
              max: 2.0,
              divisions: 15,
              onChanged: (value) {
                setState(() {
                  _speechPitch = value;
                });
              },
            ),

            const SizedBox(height: 20),

            // Accessibility card

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'दृष्टिबाधित विद्यार्थियों के लिए',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'इस स्क्रीन में बड़े अक्षर, '
                      'स्पष्ट नियंत्रण, Semantics लेबल '
                      'और आवाज सुनने की सुविधा दी गई है। '
                      'TalkBack के साथ भी इसका परीक्षण '
                      'किया जाना आवश्यक है।',
                      style: TextStyle(
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Future integration note

            const Text(
              'नोट: PDF, EPUB और स्कैन की गई पुस्तकों '
              'का टेक्स्ट निकालने के लिए अलग सर्विस '
              'फाइलें जोड़ी जाएँगी।',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
