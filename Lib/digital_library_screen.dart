
import 'package:flutter/material.dart';

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
      'description': 'हिंदी भाषा के अध्ययन की पुस्तक',
    },
    {
      'title': 'बाल कहानियाँ',
      'category': 'कहानी',
      'description': 'बच्चों के लिए शिक्षाप्रद कहानियाँ',
    },
    {
      'title': 'गणित की पुस्तक',
      'category': 'गणित',
      'description': 'गणित सीखने के लिए पुस्तक',
    },
    {
      'title': 'विज्ञान परिचय',
      'category': 'विज्ञान',
      'description': 'विज्ञान की प्रारंभिक जानकारी',
    },
    {
      'title': 'सामान्य ज्ञान',
      'category': 'ज्ञान',
      'description': 'सामान्य ज्ञान से संबंधित पुस्तक',
    },
  ];

  String searchText = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
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
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: 'पुस्तक खोजें...',
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
                      child: Text(
                        'कोई पुस्तक नहीं मिली।',
                        style: TextStyle(fontSize: 18),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredBooks.length,

                      itemBuilder: (context, index) {
                        final book = filteredBooks[index];

                        return Card(
                          margin: const EdgeInsets.only(
                            bottom: 12,
                          ),

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
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),

                            subtitle: Text(
                              '${book['category']}\n'
                              '${book['description']}',
                            ),

                            isThreeLine: true,

                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                            ),

                            onTap: () {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${book['title']} की पुस्तक सामग्री अगले चरण में जोड़ी जाएगी।',
                                  ),
                                ),
                              );
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
