
import 'package:permission_handler/permission_handler.dart';

/// Smart Vision Reader
/// Microphone Permission Management Service

class VoicePermissionService {
  VoicePermissionService._();

  static final VoicePermissionService instance =
      VoicePermissionService._();

  /// Check whether microphone permission is granted.
  Future<bool> hasPermission() async {
    try {
      final status = await Permission.microphone.status;
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  /// Request microphone permission from the user.
  Future<bool> requestPermission() async {
    try {
      final status = await Permission.microphone.request();

      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  /// Check whether permission is permanently denied.
  Future<bool> isPermanentlyDenied() async {
    try {
      final status = await Permission.microphone.status;

      return status.isPermanentlyDenied ||
          status.isRestricted;
    } catch (e) {
      return false;
    }
  }

  /// Check whether permission is denied.
  Future<bool> isDenied() async {
    try {
      final status = await Permission.microphone.status;

      return status.isDenied;
    } catch (e) {
      return false;
    }
  }

  /// Open application settings.
  Future<bool> openSettings() async {
    try {
      return await openAppSettings();
    } catch (e) {
      return false;
    }
  }

  /// Request permission with settings fallback.
  Future<bool> ensurePermission() async {
    if (await hasPermission()) {
      return true;
    }

    if (await isPermanentlyDenied()) {
      return false;
    }

    return await requestPermission();
  }
}
