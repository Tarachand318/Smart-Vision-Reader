
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// OCR Service
/// तस्वीरों और स्कैन किए हुए पन्नों से टेक्स्ट पहचानती है।
class OcrService {
  OcrService._internal();

  static final OcrService instance = OcrService._internal();

  /// इमेज से टेक्स्ट पहचानने का मुख्य फंक्शन।
  ///
  /// Hindi के लिए devanagiri और English के लिए latin चुनें।
  Future<String> recognizeTextFromFile(
    String imagePath, {
    TextRecognitionScript script =
        TextRecognitionScript.devanagiri,
  }) async {
    final String path = imagePath.trim();

    if (path.isEmpty) {
      throw ArgumentError('Image path खाली नहीं हो सकता।');
    }

    final File imageFile = File(path);

    if (!await imageFile.exists()) {
      throw OcrException('चुनी गई इमेज नहीं मिली।');
    }

    if (await imageFile.length() == 0) {
      throw OcrException('इमेज खाली है।');
    }

    final TextRecognizer recognizer =
        TextRecognizer(script: script);

    try {
      final InputImage inputImage =
          InputImage.fromFilePath(path);

      final RecognizedText result =
          await recognizer.processImage(inputImage);

      final String extractedText = result.text.trim();

      if (extractedText.isEmpty) {
        throw OcrException(
          'इमेज में कोई पढ़ने योग्य टेक्स्ट नहीं मिला।',
        );
      }

      return extractedText;
    } on PlatformException catch (e) {
      throw OcrException(
        'OCR प्रक्रिया में त्रुटि: ${e.message ?? e.code}',
      );
    } finally {
      await recognizer.close();
    }
  }

  /// हिंदी टेक्स्ट पहचानने के लिए।
  Future<String> recognizeHindiText(String imagePath) {
    return recognizeTextFromFile(
      imagePath,
      script: TextRecognitionScript.devanagiri,
    );
  }

  /// अंग्रेजी टेक्स्ट पहचानने के लिए।
  Future<String> recognizeEnglishText(String imagePath) {
    return recognizeTextFromFile(
      imagePath,
      script: TextRecognitionScript.latin,
    );
  }
}

/// OCR से संबंधित त्रुटियों के लिए कस्टम Exception।
class OcrException implements Exception {
  final String message;

  OcrException(this.message);

  @override
  String toString() => message;
}
