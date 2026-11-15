
/// Smart Vision Reader
/// File: speech_recognition_service.dart
/// Purpose: Converts user's speech into text.
/// Package: speech_to_text

import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Callback for recognized speech.
typedef SpeechResultCallback = void Function(
  String recognizedText,
  bool isFinal,
);

/// Callback for speech status.
typedef SpeechStatusCallback = void Function(
  String status,
);

/// Callback for speech errors.
typedef SpeechErrorCallback = void Function(
  String error,
);

class SpeechRecognitionService {
  final stt.SpeechToText _speech =
      stt.SpeechToText();

  final SpeechResultCallback? onResult;
  final SpeechStatusCallback? onStatus;
  final SpeechErrorCallback? onError;

  bool _isInitialized = false;
  bool _isListening = false;
  bool _isAvailable = false;

  String _recognizedText = '';

  SpeechRecognitionService({
    this.onResult,
    this.onStatus,
    this.onError,
  });

  /// Check initialization status.
  bool get isInitialized => _isInitialized;

  /// Check whether speech recognition is available.
  bool get isAvailable => _isAvailable;

  /// Check listening status.
  bool get isListening => _isListening;

  /// Get the latest recognized text.
  String get recognizedText => _recognizedText;

  /// Initialize speech recognition.
  /// Call this method once before listening.
  Future<bool> initialize() async {
    if (_isInitialized) {
      return _isAvailable;
    }

    try {
      _isAvailable = await _speech.initialize(
        onStatus: _handleStatus,
        onError: _handleError,
        debugLogging: false,
      );

      _isInitialized = true;

      if (!_isAvailable) {
        onError?.call(
          'Speech recognition is not available.',
        );
      }

      return _isAvailable;
    } catch (e) {
      _isAvailable = false;
      onError?.call(
        'Speech initialization failed.',
      );

      return false;
    }
  }

  /// Handle speech recognition status.
  void _handleStatus(String status) {
    _isListening = status == 'listening';

    if (status == 'notListening' ||
        status == 'done') {
      _isListening = false;
    }

    onStatus?.call(status);
  }

  /// Handle speech recognition errors.
  void _handleError(
    stt.SpeechRecognitionError error,
  ) {
    _isListening = false;

    onError?.call(error.errorMsg);
  }

  /// Handle recognized speech results.
  void _handleResult(
    SpeechRecognitionResult result,
  ) {
    _recognizedText = result.recognizedWords;

    onResult?.call(
      _recognizedText,
      result.finalResult,
    );
  }

  /// Start listening for speech.
  ///
  /// Default language: Hindi (India).
  /// Use 'en_IN' for English (India).
  Future<bool> startListening({
    String localeId = 'hi_IN',
    Duration listenFor = const Duration(seconds: 30),
    Duration pauseFor = const Duration(seconds: 3),
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();

      if (!initialized) {
        return false;
      }
    }

    if (!_isAvailable) {
      return false;
    }

    if (_isListening) {
      return true;
    }

    try {
      _recognizedText = '';

      await _speech.listen(
        onResult: _handleResult,
        listenOptions: stt.SpeechListenOptions(
          localeId: localeId,
          listenFor: listenFor,
          pauseFor: pauseFor,
          partialResults: true,
          cancelOnError: true,
          listenMode: stt.ListenMode.confirmation,
        ),
      );

      return true;
    } catch (e) {
      _isListening = false;

      onError?.call(
        'Unable to start speech recognition.',
      );

      return false;
    }
  }

  /// Stop listening and receive the final result.
  Future<void> stopListening() async {
    if (!_isInitialized || !_isListening) {
      return;
    }

    try {
      await _speech.stop();
    } catch (e) {
      onError?.call(
        'Unable to stop speech recognition.',
      );
    } finally {
      _isListening = false;
    }
  }

  /// Cancel listening without keeping the final result.
  Future<void> cancelListening() async {
    if (!_isInitialized) {
      return;
    }

    try {
      await _speech.cancel();

      _isListening = false;
      _recognizedText = '';
    } catch (e) {
      onError?.call(
        'Unable to cancel speech recognition.',
      );
    }
  }

  /// Get available recognition languages.
  Future<List<stt.LocaleName>> getAvailableLocales() async {
    if (!_isInitialized) {
      final initialized = await initialize();

      if (!initialized) {
        return <stt.LocaleName>[];
      }
    }

    if (!_isAvailable) {
      return <stt.LocaleName>[];
    }

    try {
      return await _speech.locales();
    } catch (e) {
      onError?.call(
        'Unable to retrieve available languages.',
      );

      return <stt.LocaleName>[];
    }
  }

  /// Get the device's default recognition language.
  Future<stt.LocaleName?> getSystemLocale() async {
    if (!_isInitialized) {
      final initialized = await initialize();

      if (!initialized) {
        return null;
      }
    }

    if (!_isAvailable) {
      return null;
    }

    try {
      return await _speech.systemLocale();
    } catch (e) {
      onError?.call(
        'Unable to retrieve system language.',
      );

      return null;
    }
  }
}
