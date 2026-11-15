
import 'package:flutter/material.dart';
import 'book_reader_screen.dart';

class DigitalLibraryScreen extends StatefulWidget {
  const DigitalLibraryScreen({super.key});

  @override
  State<DigitalLibraryScreen> createState() =>
      _DigitalLibraryScreenState();
}

class _DigitalLibraryScreenState
    extends State<DigitalLibraryScreen> {

  final TextEditingController searchController =
      TextEditingController();

  final List<Map<String, String>> books = [
    {
      'title': 'हिंदी भाषा',
      'category': 'भाषा एवं साहित्य',
      'content': '''
हिंदी भाषा

हिंदी भारत की प्रमुख भाषाओं में से एक है।
यह देवनागरी लिपि में लिखी जाती है।

भाषा मनुष्य के विचारों और भावनाओं को
व्यक्त करने का महत्वपूर्ण माध्यम है।
      ''',
    },
    {
      'title': 'बाल कहानियाँ',
      'category': 'कहानी',
      'content': '''
बाल कहानियाँ

एक समय की बात है।
एक गाँव में एक मेहनती बच्चा रहता था।
वह प्रतिदिन मन लगाकर पढ़ाई करता था।

उसका मानना था कि मेहनत और लगन से
हर कठिन काम पूरा किया जा सकता है।
      ''',
    },
    {
      'title': 'गणित की पुस्तक',
      'category': 'गणित',
      'content': '''
गणित की पुस्तक

गणित संख्याओं और गणनाओं का विज्ञान है।

दो और तीन को जोड़ने पर पाँच प्राप्त होते हैं।

गणित हमारे दैनिक जीवन में बहुत उपयोगी है।
      ''',
    },
    {
      'title': 'विज्ञान परिचय',
      'category': 'विज्ञान',
      'content': '''
विज्ञान परिचय

विज्ञान हमें प्रकृति और संसार को समझने
में सहायता करता है।

पानी, हवा, प्रकाश और ध्वनि हमारे
जीवन के महत्वपूर्ण भाग हैं।
      ''',
    },
    {
      'title': 'सामान्य ज्ञान',
      'category': 'ज्ञान',
      'content': '''
सामान्य ज्ञान

भारत की राजधानी नई दिल्ली है।

भारत का राष्ट्रीय पशु बाघ है।

भारत का राष्ट्रीय पक्षी मोर है।
      ''',
    },
  ];

  String searchText = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void openBook(Map<String, String> book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookReaderScreen(
          title: book['title']!,
          content: book['content']!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    final filteredBooks = books.where((book) {
      return book['title']!
              .toLowerCase()
              .contains(searchText.toLowerCase()) ||
          book['category']!
              .toLowerCase()
              .contains(searchText.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Library'),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [

            const Text(
              'डिजिटल पुस्तकालय',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: 'पुस्तक खोजें',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  searchText = value;
                });
              },
            ),

            const SizedBox(height: 15),

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
                          child: ListTile(
                            contentPadding:
                                const EdgeInsets.all(12),

                            leading: const Icon(
                              Icons.menu_book,
                              size: 40,
                              color: Colors.blue,
                            ),

                            title: Text(
                              book['title']!,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            subtitle: Text(
                              '${book['category']}\n'
                              'पढ़ने और सुनने के लिए खोलें',
                            ),

                            isThreeLine: true,

                            trailing: const Icon(
                              Icons.volume_up,
                              size: 28,
                            ),

                            onTap: () {
                              openBook(book);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
