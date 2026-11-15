
/// Smart Vision Reader
/// File: voice_command_router.dart
/// Purpose: Routes recognized voice commands to app actions.

typedef VoiceCommandHandler = Future<void> Function();

/// Available voice command actions.
enum VoiceCommandAction {
  startReading,
  stopReading,
  pauseReading,
  resumeReading,
  repeatReading,
  openHome,
  openSettings,
  showHelp,
}

/// Result status of voice command processing.
enum VoiceCommandStatus {
  success,
  unrecognized,
  handlerNotConfigured,
  handlerFailed,
}

/// Result returned after processing a voice command.
class VoiceCommandResult {
  final VoiceCommandStatus status;
  final String originalText;
  final VoiceCommandAction? action;
  final String message;

  const VoiceCommandResult({
    required this.status,
    required this.originalText,
    required this.message,
    this.action,
  });

  bool get isSuccess =>
      status == VoiceCommandStatus.success;
}

/// Voice Command Router
class VoiceCommandRouter {
  final Map<VoiceCommandAction, VoiceCommandHandler>
      _handlers;

  VoiceCommandRouter({
    required Map<VoiceCommandAction, VoiceCommandHandler>
        handlers,
  }) : _handlers =
           Map.unmodifiable(handlers);

  /// Maps recognized phrases to their actions.
  static const Map<String, VoiceCommandAction>
      _commandMap = {
    // Start reading
    'read': VoiceCommandAction.startReading,
    'start reading': VoiceCommandAction.startReading,
    'read text': VoiceCommandAction.startReading,
    'पढ़ना शुरू करो': VoiceCommandAction.startReading,
    'पढ़ना चालू करो': VoiceCommandAction.startReading,
    'पढ़ना शुरू करें': VoiceCommandAction.startReading,

    // Stop reading
    'stop': VoiceCommandAction.stopReading,
    'stop reading': VoiceCommandAction.stopReading,
    'रुको': VoiceCommandAction.stopReading,
    'पढ़ना बंद करो': VoiceCommandAction.stopReading,
    'बंद करो': VoiceCommandAction.stopReading,

    // Pause reading
    'pause': VoiceCommandAction.pauseReading,
    'pause reading': VoiceCommandAction.pauseReading,
    'रोक दो': VoiceCommandAction.pauseReading,
    'थोड़ी देर रुको': VoiceCommandAction.pauseReading,

    // Resume reading
    'resume': VoiceCommandAction.resumeReading,
    'resume reading': VoiceCommandAction.resumeReading,
    'continue reading': VoiceCommandAction.resumeReading,
    'फिर से शुरू करो': VoiceCommandAction.resumeReading,
    'आगे पढ़ो': VoiceCommandAction.resumeReading,

    // Repeat reading
    'repeat': VoiceCommandAction.repeatReading,
    'repeat reading': VoiceCommandAction.repeatReading,
    'फिर से पढ़ो': VoiceCommandAction.repeatReading,
    'दोबारा पढ़ो': VoiceCommandAction.repeatReading,

    // Open home
    'home': VoiceCommandAction.openHome,
    'go home': VoiceCommandAction.openHome,
    'open home': VoiceCommandAction.openHome,
    'होम खोलो': VoiceCommandAction.openHome,
    'मुख्य पृष्ठ खोलो': VoiceCommandAction.openHome,

    // Open settings
    'settings': VoiceCommandAction.openSettings,
    'open settings': VoiceCommandAction.openSettings,
    'सेटिंग खोलो': VoiceCommandAction.openSettings,
    'सेटिंग्स खोलो': VoiceCommandAction.openSettings,

    // Help
    'help': VoiceCommandAction.showHelp,
    'show help': VoiceCommandAction.showHelp,
    'मदद करो': VoiceCommandAction.showHelp,
    'सहायता करो': VoiceCommandAction.showHelp,
  };

  /// Normalize recognized speech text.
  String _normalizeText(String text) {
    return text
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[.,!?;:।]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Identify the action associated with a command.
  VoiceCommandAction? identifyCommand(String text) {
    final normalizedText = _normalizeText(text);

    if (normalizedText.isEmpty) {
      return null;
    }

    return _commandMap[normalizedText];
  }

  /// Check whether a command is supported.
  bool canHandle(String text) {
    return identifyCommand(text) != null;
  }

  /// Process and execute a recognized voice command.
  Future<VoiceCommandResult> route(
    String recognizedText,
  ) async {
    final originalText = recognizedText;

    if (recognizedText.trim().isEmpty) {
      return VoiceCommandResult(
        status: VoiceCommandStatus.unrecognized,
        originalText: originalText,
        message: 'No voice command was recognized.',
      );
    }

    final action = identifyCommand(recognizedText);

    if (action == null) {
      return VoiceCommandResult(
        status: VoiceCommandStatus.unrecognized,
        originalText: originalText,
        message: 'Voice command not recognized.',
      );
    }

    final handler = _handlers[action];

    if (handler == null) {
      return VoiceCommandResult(
        status: VoiceCommandStatus.handlerNotConfigured,
        originalText: originalText,
        action: action,
        message: 'The requested action is not configured.',
      );
    }

    try {
      await handler();

      return VoiceCommandResult(
        status: VoiceCommandStatus.success,
        originalText: originalText,
        action: action,
        message: 'Voice command executed successfully.',
      );
    } catch (_) {
      return VoiceCommandResult(
        status: VoiceCommandStatus.handlerFailed,
        originalText: originalText,
        action: action,
        message: 'Unable to execute the voice command.',
      );
    }
  }
}
