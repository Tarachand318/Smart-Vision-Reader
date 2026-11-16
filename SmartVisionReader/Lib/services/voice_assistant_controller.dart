
/// Smart Vision Reader
/// File: voice_assistant_controller.dart
/// Purpose: Controls voice commands and wake word mode.

import 'dart:async';

import 'speech_recognition_service.dart';
import 'wake_word_service.dart';
import 'voice_command_router.dart';
import 'voice_state_manager.dart';

class VoiceAssistantController {
  VoiceAssistantController({
    required Map<VoiceCommandAction, VoiceCommandHandler>
        commandHandlers,
    this.localeId = 'hi_IN',
  }) {
    _wakeWordService = WakeWordService(
      onWakeWordDetected: _handleWakeWord,
      onStopDetected: _handleStopWord,
    );

    _speechService = SpeechRecognitionService(
      onResult: _handleSpeechResult,
      onStatus: _handleSpeechStatus,
      onError: _handleSpeechError,
    );

    _commandRouter = VoiceCommandRouter(
      handlers: commandHandlers,
    );
  }

  final String localeId;

  final VoiceStateManager voiceStateManager =
      VoiceStateManager();

  late final WakeWordService _wakeWordService;
  late final SpeechRecognitionService _speechService;
  late final VoiceCommandRouter _commandRouter;

  bool _isStarted = false;
  bool _isRestarting = false;
  bool _isDisposed = false;

  bool get isStarted => _isStarted;

  /// Whether voice command mode is active.
  bool get isCommandModeActive =>
      _wakeWordService.isAwake;

  /// Start wake-word detection.
  Future<bool> start() async {
    if (_isDisposed) return false;

    if (_isStarted) return true;

    final available = await _speechService.initialize();

    if (!available) return false;

    voiceStateManager.setEnabled(true);
    voiceStateManager.setWakeWordEnabled(true);

    _wakeWordService.start();
    _isStarted = true;

    final listening =
        await _speechService.startListening(
      localeId: localeId,
    );

    if (!listening) {
      _isStarted = false;
      _wakeWordService.stop();
      voiceStateManager.reset();
      return false;
    }

    return true;
  }

  /// Process only final speech results.
  Future<void> _handleSpeechResult(
    String recognizedText,
    bool isFinal,
  ) async {
    if (!_isStarted || !isFinal) return;

    final text = recognizedText
        .toUpperCase()
        .replaceAll(
          RegExp(r'[^A-Z0-9\s]'),
          ' ',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (text.isEmpty) return;

    // When command mode is inactive,
    // accept only SMART VISION.
    if (!_wakeWordService.isAwake) {
      await _wakeWordService.processRecognizedText(text);
      return;
    }

    // STOP disables voice commands only.
    // Speech recognition remains active for
    // detecting SMART VISION again.
    if (text == 'STOP') {
      await _wakeWordService.processRecognizedText(text);
      return;
    }

    // All other recognized commands go to router.
    voiceStateManager.startProcessing();

    final result = await _commandRouter.route(
      recognizedText,
    );

    if (result.status == VoiceCommandStatus.handlerFailed) {
      voiceStateManager.setError(result.message);
    } else {
      voiceStateManager.stopActivity();
    }
  }

  /// SMART VISION detected.
  Future<void> _handleWakeWord() async {
    if (!_isStarted) return;

    voiceStateManager.clearError();
    voiceStateManager.startListening();
  }

  /// STOP detected.
  ///
  /// IMPORTANT:
  /// Do not stop speech recognition.
  /// Do not stop TTS or book reading.
  Future<void> _handleStopWord() async {
    voiceStateManager.stopActivity();
  }

  /// Handle speech recognition status.
  void _handleSpeechStatus(String status) {
    if (!_isStarted || _isDisposed) return;

    if (status == 'done' ||
        status == 'notListening') {
      _restartListening();
    }
  }

  /// Restart listening so SMART VISION
  /// can be detected after STOP.
  Future<void> _restartListening() async {
    if (_isRestarting || !_isStarted || _isDisposed) {
      return;
    }

    _isRestarting = true;

    try {
      await Future<void>.delayed(
        const Duration(milliseconds: 400),
      );

      if (_isStarted && !_isDisposed) {
        await _speechService.startListening(
          localeId: localeId,
        );
      }
    } finally {
      _isRestarting = false;
    }
  }

  /// Handle speech recognition errors.
  void _handleSpeechError(String error) {
    if (!_isStarted || _isDisposed) return;

    voiceStateManager.setError(error);
  }

  /// Completely shut down voice recognition.
  ///
  /// This method is different from spoken STOP.
  Future<void> stop() async {
    _isStarted = false;
    _wakeWordService.stop();

    await _speechService.cancelListening();

    voiceStateManager.reset();
  }

  /// Release controller resources.
  Future<void> dispose() async {
    if (_isDisposed) return;

    await stop();

    _isDisposed = true;
    voiceStateManager.dispose();
    _wakeWordService.dispose();
  }
}
