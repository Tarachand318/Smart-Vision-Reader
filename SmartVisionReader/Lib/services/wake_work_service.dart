
import 'dart:async';

typedef WakeWordCallback = FutureOr<void> Function();

class WakeWordService {
  WakeWordService({
    required this.onWakeWordDetected,
    required this.onStopDetected,
  });

  final WakeWordCallback onWakeWordDetected;
  final WakeWordCallback onStopDetected;

  static const String wakeWord = 'SMART VISION';
  static const String stopWord = 'STOP';

  bool _isRunning = false;
  bool _isAwake = false;

  // Check service status
  bool get isRunning => _isRunning;

  // Check assistant awake status
  bool get isAwake => _isAwake;

  // Start wake word detection
  void start() {
    _isRunning = true;
    _isAwake = false;
  }

  // Stop wake word detection completely
  void stop() {
    _isRunning = false;
    _isAwake = false;
  }

  // Process recognized speech
  Future<void> processRecognizedText(
    String recognizedText,
  ) async {
    if (!_isRunning) return;

    final text = _normalize(recognizedText);

    if (text.isEmpty) return;

    // Activate assistant using SMART VISION
    if (!_isAwake && _containsCommand(text, wakeWord)) {
      _isAwake = true;

      await onWakeWordDetected();
      return;
    }

    // Deactivate assistant using STOP
    if (_isAwake && _containsCommand(text, stopWord)) {
      _isAwake = false;

      await onStopDetected();
    }
  }

  // Check whether a command exists in recognized text
  bool _containsCommand(String text, String command) {
    return (' $text ').contains(' ${_normalize(command)} ');
  }

  // Normalize recognized text
  String _normalize(String text) {
    return text
        .toUpperCase()
        .replaceAll(
          RegExp(r'[^A-Z0-9\s]'),
          ' ',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // Reset assistant awake state
  void reset() {
    _isAwake = false;
  }

  // Dispose service
  void dispose() {
    stop();
  }
}
