
import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';

enum TtsPlaybackState {
  stopped,
  playing,
  paused,
}

class TtsService {
  TtsService._internal();

  static final TtsService instance = TtsService._internal();

  final FlutterTts _tts = FlutterTts();

  bool _initialized = false;
  bool _isPaused = false;
  int _requestId = 0;

  TtsPlaybackState _state = TtsPlaybackState.stopped;

  String _currentLanguage = 'hi-IN';
  String _currentChunk = '';

  int _lastEndOffset = 0;

  double _speechRate = 0.45;
  double _speechPitch = 1.0;
  double _speechVolume = 1.0;

  TtsPlaybackState get state => _state;

  bool get isPlaying =>
      _state == TtsPlaybackState.playing;

  bool get isPaused =>
      _state == TtsPlaybackState.paused;

  bool get isInitialized => _initialized;

  String get currentLanguage => _currentLanguage;

  // Initialize TTS engine.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await _tts.awaitSpeakCompletion(true);

      await _tts.setSpeechRate(_speechRate);
      await _tts.setPitch(_speechPitch);
      await _tts.setVolume(_speechVolume);

      _tts.setStartHandler(() {
        if (!_isPaused) {
          _state = TtsPlaybackState.playing;
        }
      });

      _tts.setCompletionHandler(() {
        if (!_isPaused) {
          _state = TtsPlaybackState.stopped;
        }
      });

      _tts.setCancelHandler(() {
        _state = TtsPlaybackState.stopped;
      });

      _tts.setErrorHandler((message) {
        _state = TtsPlaybackState.stopped;
        _isPaused = false;
      });

      _tts.setProgressHandler((
        String text,
        int startOffset,
        int endOffset,
        String word,
      ) {
        _lastEndOffset = endOffset;
      });

      _initialized = true;
    } catch (e) {
      _initialized = false;
      rethrow;
    }
  }

  // Set Hindi language.
  Future<void> setHindi() async {
    await initialize();

    await _tts.setLanguage('hi-IN');

    _currentLanguage = 'hi-IN';
  }

  // Set English language.
  Future<void> setEnglish() async {
    await initialize();

    await _tts.setLanguage('en-US');

    _currentLanguage = 'en-US';
  }

  // Set custom language.
  Future<void> setLanguage(String languageCode) async {
    await initialize();

    if (languageCode.trim().isEmpty) {
      throw ArgumentError('Language code cannot be empty.');
    }

    final available =
        await _tts.isLanguageAvailable(languageCode);

    if (available != true) {
      throw Exception(
        'Selected language is not available on this device.',
      );
    }

    await _tts.setLanguage(languageCode);

    _currentLanguage = languageCode;
  }

  // Read text aloud.
  Future<void> speak(String text) async {
    await initialize();

    if (text.trim().isEmpty) return;

    final int request = ++_requestId;

    await _tts.stop();

    if (request != _requestId) return;

    _isPaused = false;
    _state = TtsPlaybackState.playing;

    // Split large text into smaller chunks.
    final chunks = _splitText(text, 2500);

    try {
      for (final chunk in chunks) {
        if (request != _requestId) return;

        _currentChunk = chunk;
        _lastEndOffset = 0;

        await _tts.speak(chunk);

        if (request != _requestId) return;

        if (_isPaused) return;
      }

      if (request == _requestId && !_isPaused) {
        _state = TtsPlaybackState.stopped;
      }
    } catch (e) {
      if (request == _requestId) {
        _state = TtsPlaybackState.stopped;
      }
      rethrow;
    }
  }

  // Pause reading.
  Future<void> pause() async {
    if (!_initialized || !isPlaying) return;

    await _tts.pause();

    _isPaused = true;
    _state = TtsPlaybackState.paused;
  }

  // Resume reading from the last reported position.
  Future<void> resume() async {
    if (!_initialized || !_isPaused) return;

    final remaining = _currentChunk.substring(
      _lastEndOffset.clamp(0, _currentChunk.length),
    );

    _isPaused = false;

    if (remaining.trim().isEmpty) {
      _state = TtsPlaybackState.stopped;
      return;
    }

    _state = TtsPlaybackState.playing;

    await _tts.speak(remaining);

    if (!_isPaused) {
      _state = TtsPlaybackState.stopped;
    }
  }

  // Stop reading completely.
  Future<void> stop() async {
    _requestId++;

    _isPaused = false;

    await _tts.stop();

    _currentChunk = '';
    _lastEndOffset = 0;

    _state = TtsPlaybackState.stopped;
  }

  // Change speech speed.
  Future<void> setSpeechRate(double rate) async {
    if (rate < 0.0 || rate > 1.0) {
      throw ArgumentError('Speech rate must be between 0 and 1.');
    }

    await initialize();

    _speechRate = rate;

    await _tts.setSpeechRate(rate);
  }

  // Change voice pitch.
  Future<void> setPitch(double pitch) async {
    if (pitch < 0.5 || pitch > 2.0) {
      throw ArgumentError('Pitch must be between 0.5 and 2.0.');
    }

    await initialize();

    _speechPitch = pitch;

    await _tts.setPitch(pitch);
  }

  // Change voice volume.
  Future<void> setVolume(double volume) async {
    if (volume < 0.0 || volume > 1.0) {
      throw ArgumentError('Volume must be between 0 and 1.');
    }

    await initialize();

    _speechVolume = volume;

    await _tts.setVolume(volume);
  }

  // Get languages supported by the device.
  Future<List<String>> getAvailableLanguages() async {
    await initialize();

    final result = await _tts.getLanguages;

    if (result is! List) return [];

    return result
        .whereType<String>()
        .toList();
  }

  // Get installed voices.
  Future<List<Map<String, dynamic>>> getAvailableVoices() async {
    await initialize();

    final result = await _tts.getVoices;

    if (result is! List) return [];

    return result
        .whereType<Map>()
        .map(
          (voice) => Map<String, dynamic>.from(voice),
        )
        .toList();
  }

  // Split long text into manageable chunks.
  List<String> _splitText(String text, int maxLength) {
    final result = <String>[];

    final normalized = text.trim();

    if (normalized.isEmpty) return result;

    int start = 0;

    while (start < normalized.length) {
      int end = start + maxLength;

      if (end >= normalized.length) {
        result.add(normalized.substring(start).trim());
        break;
      }

      int splitAt = normalized.lastIndexOf(
        RegExp(r'[\s।.!?]'),
        end,
      );

      if (splitAt <= start) {
        splitAt = end;
      }

      result.add(
        normalized.substring(start, splitAt).trim(),
      );

      start = splitAt;

      while (start < normalized.length &&
          normalized[start].trim().isEmpty) {
        start++;
      }
    }

    return result.where((chunk) => chunk.isNotEmpty).toList();
  }

  // Release resources.
  Future<void> dispose() async {
    await stop();

    _initialized = false;
  }
}
