
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Smart Vision Reader
/// Central language management service.
///
/// Supported languages:
/// Hindi (hi) and English (en).

class LanguageService extends ChangeNotifier {
  LanguageService._();

  static final LanguageService instance = LanguageService._();

  static const String _languageKey = 'app_selected_language';

  static const Locale hindiLocale = Locale('hi');
  static const Locale englishLocale = Locale('en');

  Locale _locale = hindiLocale;

  bool _isInitialized = false;
  bool _isSaving = false;

  Locale get locale => _locale;

  String get languageCode => _locale.languageCode;

  bool get isHindi => languageCode == 'hi';

  bool get isEnglish => languageCode == 'en';

  bool get isInitialized => _isInitialized;

  bool get isSaving => _isSaving;

  List<Locale> get supportedLocales => const [
        hindiLocale,
        englishLocale,
      ];

  /// Available language names.
  Map<String, String> get availableLanguages => {
        'hi': 'हिंदी',
        'en': 'English',
      };

  /// Initialize and restore previously selected language.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      final savedLanguage = prefs.getString(_languageKey);

      if (savedLanguage == 'en') {
        _locale = englishLocale;
      } else {
        _locale = hindiLocale;
      }
    } catch (e) {
      debugPrint('Language initialization error: $e');
      _locale = hindiLocale;
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Change application language.
  Future<bool> changeLanguage(String languageCode) async {
    if (languageCode != 'hi' && languageCode != 'en') {
      return false;
    }

    final newLocale = Locale(languageCode);

    if (_locale == newLocale) {
      return true;
    }

    if (_isSaving) return false;

    _isSaving = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();

      final saved = await prefs.setString(
        _languageKey,
        languageCode,
      );

      if (!saved) return false;

      _locale = newLocale;

      return true;
    } catch (e) {
      debugPrint('Language change error: $e');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Shortcut for Hindi.
  Future<bool> setHindi() {
    return changeLanguage('hi');
  }

  /// Shortcut for English.
  Future<bool> setEnglish() {
    return changeLanguage('en');
  }

  /// Central translation dictionary.
  static const Map<String, Map<String, String>> _translations = {
    'app_name': {
      'hi': 'स्मार्ट विजन रीडर',
      'en': 'Smart Vision Reader',
    },
    'home': {
      'hi': 'होम',
      'en': 'Home',
    },
    'my_library': {
      'hi': 'मेरी लाइब्रेरी',
      'en': 'My Library',
    },
    'digital_library': {
      'hi': 'डिजिटल लाइब्रेरी',
      'en': 'Digital Library',
    },
    'book_reader': {
      'hi': 'बुक रीडर',
      'en': 'Book Reader',
    },
    'settings': {
      'hi': 'सेटिंग्स',
      'en': 'Settings',
    },
    'profile': {
      'hi': 'प्रोफाइल',
      'en': 'Profile',
    },
    'login': {
      'hi': 'लॉगिन',
      'en': 'Login',
    },
    'register': {
      'hi': 'पंजीकरण',
      'en': 'Register',
    },
    'logout': {
      'hi': 'लॉगआउट',
      'en': 'Logout',
    },
    'language': {
      'hi': 'भाषा',
      'en': 'Language',
    },
    'select_language': {
      'hi': 'अपनी भाषा चुनें',
      'en': 'Select your language',
    },
    'hindi': {
      'hi': 'हिंदी',
      'en': 'Hindi',
    },
    'english': {
      'hi': 'अंग्रेजी',
      'en': 'English',
    },
    'save': {
      'hi': 'सहेजें',
      'en': 'Save',
    },
    'cancel': {
      'hi': 'रद्द करें',
      'en': 'Cancel',
    },
    'search': {
      'hi': 'खोजें',
      'en': 'Search',
    },
    'read': {
      'hi': 'पढ़ें',
      'en': 'Read',
    },
    'listen': {
      'hi': 'सुनें',
      'en': 'Listen',
    },
    'pause': {
      'hi': 'रोकें',
      'en': 'Pause',
    },
    'resume': {
      'hi': 'फिर से शुरू करें',
      'en': 'Resume',
    },
    'stop': {
      'hi': 'बंद करें',
      'en': 'Stop',
    },
    'next': {
      'hi': 'अगला',
      'en': 'Next',
    },
    'previous': {
      'hi': 'पिछला',
      'en': 'Previous',
    },
    'camera': {
      'hi': 'कैमरा',
      'en': 'Camera',
    },
    'scan_text': {
      'hi': 'टेक्स्ट स्कैन करें',
      'en': 'Scan Text',
    },
    'accessibility': {
      'hi': 'सुगम्यता',
      'en': 'Accessibility',
    },
    'font_size': {
      'hi': 'अक्षरों का आकार',
      'en': 'Font Size',
    },
    'notifications': {
      'hi': 'सूचनाएँ',
      'en': 'Notifications',
    },
    'privacy': {
      'hi': 'गोपनीयता',
      'en': 'Privacy',
    },
    'security': {
      'hi': 'सुरक्षा',
      'en': 'Security',
    },
    'help': {
      'hi': 'सहायता',
      'en': 'Help',
    },
    'about': {
      'hi': 'हमारे बारे में',
      'en': 'About Us',
    },
    'no_data': {
      'hi': 'कोई जानकारी उपलब्ध नहीं है',
      'en': 'No data available',
    },
    'loading': {
      'hi': 'कृपया प्रतीक्षा करें...',
      'en': 'Please wait...',
    },
    'error': {
      'hi': 'कुछ त्रुटि हुई है',
      'en': 'Something went wrong',
    },
    'success': {
      'hi': 'कार्य सफलतापूर्वक पूरा हुआ',
      'en': 'Operation completed successfully',
    },
  };

  /// Translate a key into the currently selected language.
  ///
  /// If translation is unavailable, the key itself is returned.
  String translate(String key) {
    final translation = _translations[key];

    if (translation == null) {
      debugPrint('Missing translation key: $key');
      return key;
    }

    return translation[languageCode] ??
        translation['hi'] ??
        key;
  }

  /// Short translation method.
  String tr(String key) => translate(key);

  /// Check whether a translation key exists.
  bool hasTranslation(String key) {
    return _translations.containsKey(key);
  }

  /// Return all registered translation keys.
  List<String> get translationKeys {
    return _translations.keys.toList(growable: false);
  }

  /// Check whether both supported languages have translations.
  bool hasCompleteTranslation(String key) {
    final translation = _translations[key];

    if (translation == null) return false;

    return translation.containsKey('hi') &&
        translation.containsKey('en');
  }

  /// Reset selected language to Hindi.
  Future<bool> resetLanguage() {
    return setHindi();
  }
}
