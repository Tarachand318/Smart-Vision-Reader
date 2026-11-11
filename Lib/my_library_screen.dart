
import 'package:flutter/material.dart';

class MyLibraryScreen extends StatefulWidget {
  const MyLibraryScreen({super.key});

  @override
  State<MyLibraryScreen> createState() =>
      _MyLibraryScreenState();
}

class _MyLibraryScreenState extends State<MyLibraryScreen> {
  final TextEditingController searchController =
      TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'मेरी लाइब्रेरी',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: const Text(
                  'आपकी अपनी किताबें',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'यहाँ आपकी सहेजी हुई किताबें दिखाई देंगी।',
                style: TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  labelText: 'किताब खोजें',
                  hintText: 'किताब का नाम लिखें',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              Expanded(
                child: Center(
                  child: Semantics(
                    liveRegion: true,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.library_books_outlined,
                          size: 85,
                          color: Colors.blueGrey,
                        ),

                        const SizedBox(height: 18),

                        const Text(
                          'अभी आपकी लाइब्रेरी खाली है।',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),

                        const Text(
                          'डिजिटल लाइब्रेरी या PDF अपलोड '
                          'विभाग से किताबें जोड़ने की सुविधा '
                          'आगे जोड़ी जाएगी।',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
