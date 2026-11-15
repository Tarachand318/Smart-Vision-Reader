
import 'package:flutter/foundation.dart';

enum VoiceActivityStatus {
  idle,
  listening,
  processing,
  speaking,
  error,
}

class VoiceStateManager extends ChangeNotifier {
  bool _isEnabled = false;
  bool _isWakeWordEnabled = false;

  VoiceActivityStatus _status =
      VoiceActivityStatus.idle;

  String? _errorMessage;

  // Current voice assistant status
  bool get isEnabled => _isEnabled;

  // Wake word detection status
  bool get isWakeWordEnabled => _isWakeWordEnabled;

  // Current voice activity
  VoiceActivityStatus get status => _status;

  // Error information
  String? get errorMessage => _errorMessage;

  // Activity status shortcuts
  bool get isListening =>
      _status == VoiceActivityStatus.listening;

  bool get isProcessing =>
      _status == VoiceActivityStatus.processing;

  bool get isSpeaking =>
      _status == VoiceActivityStatus.speaking;

  bool get hasError =>
      _status == VoiceActivityStatus.error;

  // Enable or disable voice assistant
  void setEnabled(bool enabled) {
    if (_isEnabled == enabled) return;

    _isEnabled = enabled;

    if (!enabled) {
      _isWakeWordEnabled = false;
      _status = VoiceActivityStatus.idle;
      _errorMessage = null;
    }

    notifyListeners();
  }

  // Enable or disable wake word detection
  void setWakeWordEnabled(bool enabled) {
    if (enabled && !_isEnabled) return;

    if (_isWakeWordEnabled == enabled) return;

    _isWakeWordEnabled = enabled;
    notifyListeners();
  }

  // Start listening
  void startListening() {
    if (!_isEnabled) return;

    _updateStatus(VoiceActivityStatus.listening);
  }

  // Start processing voice command
  void startProcessing() {
    if (!_isEnabled) return;

    _updateStatus(VoiceActivityStatus.processing);
  }

  // Start speaking response
  void startSpeaking() {
    if (!_isEnabled) return;

    _updateStatus(VoiceActivityStatus.speaking);
  }

  // Stop current voice activity
  void stopActivity() {
    _updateStatus(VoiceActivityStatus.idle);
  }

  // Handle voice assistant errors
  void setError(String message) {
    final error = message.trim();

    if (error.isEmpty) return;

    _errorMessage = error;
    _updateStatus(VoiceActivityStatus.error);
  }

  // Clear current error
  void clearError() {
    if (_errorMessage == null &&
        _status != VoiceActivityStatus.error) {
      return;
    }

    _errorMessage = null;
    _updateStatus(VoiceActivityStatus.idle);
  }

  // Reset all voice activity states
  void reset() {
    _isEnabled = false;
    _isWakeWordEnabled = false;
    _status = VoiceActivityStatus.idle;
    _errorMessage = null;

    notifyListeners();
  }

  // Update activity status
  void _updateStatus(VoiceActivityStatus newStatus) {
    if (_status == newStatus) return;

    _status = newStatus;

    if (newStatus != VoiceActivityStatus.error) {
      _errorMessage = null;
    }

    notifyListeners();
  }

  // Get readable activity status
  String get statusLabel {
    switch (_status) {
      case VoiceActivityStatus.idle:
        return 'निष्क्रिय';

      case VoiceActivityStatus.listening:
        return 'आवाज सुन रहा है';

      case VoiceActivityStatus.processing:
        return 'आवाज का विश्लेषण कर रहा है';

      case VoiceActivityStatus.speaking:
        return 'बोल रहा है';

      case VoiceActivityStatus.error:
        return 'त्रुटि हुई है';
    }
  }
}
