
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class BrailleBooksScreen extends StatefulWidget {
  const BrailleBooksScreen({super.key});

  @override
  State<BrailleBooksScreen> createState() =>
      _BrailleBooksScreenState();
}

class _BrailleBooksScreenState
    extends State<BrailleBooksScreen> {
  final FlutterTts flutterTts = FlutterTts();

  final TextEditingController searchController =
      TextEditingController();

  bool isSpeaking = false;

  final List<Map<String, String>> books = [
    {
      'title': 'हिंदी साहित्य',
      'subject': 'हिंदी',
      'content':
          'हिंदी भारत की प्रमुख भाषाओं में से एक है। '
          'हिंदी साहित्य में कविता, कहानी, उपन्यास और नाटक शामिल हैं।',
    },
    {
      'title': 'गणित की पुस्तक',
      'subject': 'गणित',
      'content':
          'गणित संख्याओं और गणनाओं का विज्ञान है। '
          'जोड़, घटाव, गुणा और भाग गणित की मूल क्रियाएँ हैं।',
    },
    {
      'title': 'विज्ञान की पुस्तक',
      'subject': 'विज्ञान',
      'content':
          'विज्ञान हमारे आसपास की दुनिया को समझने का माध्यम है। '
          'यह प्रकृति और विभिन्न घटनाओं का अध्ययन करता है।',
    },
    {
      'title': 'सामान्य ज्ञान',
      'subject': 'सामान्य ज्ञान',
      'content':
          'भारत की राजधानी नई दिल्ली है। '
          'भारत का राष्ट्रीय पशु बाघ है।',
    },
    {
      'title': 'अंग्रेजी भाषा',
      'subject': 'अंग्रेजी',
      'content':
          'English is an important language. '
          'Reading and listening help us learn English.',
    },
  ];

  String searchText = '';

  List<Map<String, String>> get filteredBooks {
    return books.where((book) {
      return book['title']!
              .toLowerCase()
              .contains(searchText.toLowerCase()) ||
          book['subject']!
              .toLowerCase()
              .contains(searchText.toLowerCase());
    }).toList();
  }

  Future<void> speakBook(String content) async {
    await flutterTts.stop();

    await flutterTts.setLanguage('hi-IN');
    await flutterTts.setSpeechRate(0.45);
    await flutterTts.setVolume(1.0);

    setState(() {
      isSpeaking = true;
    });

    await flutterTts.speak(content);
  }

  Future<void> stopSpeaking() async {
    await flutterTts.stop();

    setState(() {
      isSpeaking = false;
    });
  }

  void openBook(Map<String, String> book) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(book['title']!),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('विषय: ${book['subject']}'),
                const SizedBox(height: 15),
                const Text(
                  'पुस्तक की सामग्री:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(book['content']!),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                speakBook(book['content']!);
              },
              icon: const Icon(Icons.volume_up),
              label: const Text('सुनें'),
            ),
            TextButton.icon(
              onPressed: stopSpeaking,
              icon: const Icon(Icons.stop),
              label: const Text('रोकें'),
            ),
            TextButton(
              onPressed: () {
                stopSpeaking();
                Navigator.pop(dialogContext);
              },
              child: const Text('बंद करें'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    flutterTts.stop();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ब्रेल पुस्तकें'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() {
                  searchText = value;
                });
              },
              decoration: const InputDecoration(
                hintText: 'पुस्तक खोजें',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'ब्रेल पुस्तकों का विभाग',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: filteredBooks.isEmpty
                ? const Center(
                    child: Text('कोई पुस्तक नहीं मिली।'),
                  )
                : ListView.builder(
                    itemCount: filteredBooks.length,
                    itemBuilder: (context, index) {
                      final book = filteredBooks[index];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 7,
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.menu_book,
                            size: 38,
                          ),
                          title: Text(book['title']!),
                          subtitle: Text(
                            'विषय: ${book['subject']}',
                          ),
                          trailing: const Icon(
                            Icons.volume_up,
                          ),
                          onTap: () => openBook(book),
                        ),
                      );
                    },
                  ),
          ),
          if (isSpeaking)
            Padding(
              padding: const EdgeInsets.all(12),
              child: ElevatedButton.icon(
                onPressed: stopSpeaking,
                icon: const Icon(Icons.stop),
                label: const Text('आवाज रोकें'),
              ),
            ),
        ],
      ),
    );
  }
}
