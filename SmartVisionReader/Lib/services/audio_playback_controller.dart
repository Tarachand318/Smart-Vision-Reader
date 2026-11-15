
/// Smart Vision Reader
/// File: audio_playback_controller.dart
/// Purpose: Controls audio playback through TtsService.

import 'tts_service.dart';

class AudioPlaybackController {
  AudioPlaybackController._internal();

  static final AudioPlaybackController instance =
      AudioPlaybackController._internal();

  final TtsService _ttsService = TtsService.instance;

  /// Current playback state.
  TtsPlaybackState get state => _ttsService.state;

  /// Check whether audio is playing.
  bool get isPlaying => _ttsService.isPlaying;

  /// Check whether audio is paused.
  bool get isPaused => _ttsService.isPaused;

  /// Initialize audio playback.
  Future<void> initialize() async {
    await _ttsService.initialize();
  }

  /// Read text aloud.
  Future<void> play(String text) async {
    if (text.trim().isEmpty) {
      return;
    }

    await _ttsService.speak(text);
  }

  /// Pause audio playback.
  Future<void> pause() async {
    await _ttsService.pause();
  }

  /// Resume paused audio.
  Future<void> resume() async {
    await _ttsService.resume();
  }

  /// Stop audio playback completely.
  Future<void> stop() async {
    await _ttsService.stop();
  }

  /// Repeat the previously supplied text.
  String _lastText = '';

  Future<void> repeat() async {
    if (_lastText.isEmpty) {
      return;
    }

    await _ttsService.speak(_lastText);
  }

  /// Play text and remember it for repetition.
  Future<void> playAndRemember(String text) async {
    if (text.trim().isEmpty) {
      return;
    }

    _lastText = text;

    await _ttsService.speak(text);
  }

  /// Change playback speed.
  Future<void> setSpeed(double speed) async {
    await _ttsService.setSpeechRate(speed);
  }

  /// Change voice volume.
  Future<void> setVolume(double volume) async {
    await _ttsService.setVolume(volume);
  }

  /// Change voice pitch.
  Future<void> setPitch(double pitch) async {
    await _ttsService.setPitch(pitch);
  }

  /// Set Hindi language.
  Future<void> setHindi() async {
    await _ttsService.setHindi();
  }

  /// Set English language.
  Future<void> setEnglish() async {
    await _ttsService.setEnglish();
  }

  /// Set another supported language.
  Future<void> setLanguage(String languageCode) async {
    await _ttsService.setLanguage(languageCode);
  }

  /// Clear remembered text.
  void clearRememberedText() {
    _lastText = '';
  }
}
