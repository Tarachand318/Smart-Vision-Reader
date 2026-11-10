
import 'package:flutter/material.dart';
import 'text_reader_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  final List<Map<String, dynamic>> departments = const [
    {
      'title': 'Home',
      'subtitle': 'मुख्य पेज',
      'icon': Icons.home,
      'color': Colors.blue,
    },
    {
      'title': 'Digital Library',
      'subtitle': 'डिजिटल पुस्तकालय',
      'icon': Icons.local_library,
      'color': Colors.orange,
    },
    {
      'title': 'Braille Books',
      'subtitle': 'ब्रेल पुस्तकें',
      'icon': Icons.menu_book,
      'color': Colors.purple,
    },
    {
      'title': 'Upload PDF',
      'subtitle': 'अपनी किताब अपलोड करें',
      'icon': Icons.picture_as_pdf,
      'color': Colors.red,
    },
    {
      'title': 'Scan Book',
      'subtitle': 'कैमरे से स्कैन करें',
      'icon': Icons.document_scanner,
      'color': Colors.teal,
    },
    {
      'title': 'Listen Books',
      'subtitle': 'किताबें सुनें',
      'icon': Icons.headphones,
      'color': Colors.green,
    },
    {
      'title': 'My Library',
      'subtitle': 'मेरी किताबें',
      'icon': Icons.bookmark,
      'color': Colors.indigo,
    },
    {
      'title': 'Settings',
      'subtitle': 'सेटिंग्स',
      'icon': Icons.settings,
      'color': Colors.blueGrey,
    },
  ];

  void openDepartment(
    BuildContext context,
    String title,
  ) {
    if (title == 'Listen Books') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const TextReaderScreen(),
        ),
      );
      return;
    }

    if (title == 'Home') {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$title विभाग का पेज अगले चरण में तैयार होगा।',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Smart Vision Reader',
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [

            const SizedBox(height: 10),

            const Icon(
              Icons.visibility,
              size: 75,
              color: Colors.blue,
            ),

            const SizedBox(height: 12),

            const Text(
              'आपका स्वागत है!',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'पढ़ें, सुनें और सीखें।',
              style: TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 25),

            GridView.builder(
              shrinkWrap: true,
              physics:
                  const NeverScrollableScrollPhysics(),
              itemCount: departments.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.05,
              ),

              itemBuilder: (context, index) {
                final item = departments[index];

                return Card(
                  elevation: 3,
                  child: InkWell(
                    borderRadius:
                        BorderRadius.circular(12),

                    onTap: () {
                      openDepartment(
                        context,
                        item['title'],
                      );
                    },

                    child: Padding(
                      padding:
                          const EdgeInsets.all(10),

                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,

                        children: [

                          Icon(
                            item['icon'],
                            size: 42,
                            color: item['color'],
                          ),

                          const SizedBox(height: 12),

                          Text(
                            item['title'],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            item['subtitle'],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
