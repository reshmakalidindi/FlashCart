import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class ApiConfig {
  static String? _customBaseUrl;

  /// Base URL for FastAPI Backend.
  /// Automatically detects Web, Android Emulator (10.0.2.2), and Desktop/iOS Simulator (127.0.0.1).
  /// Can also be overridden at runtime via ApiConfig.baseUrl = 'http://192.168.1.X:8000/api/v1'.
  static String get baseUrl {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!;
    }
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api/v1';
    }
    try {
      // In flutter test, avoid android emulator address
      if (!isTestEnvironment && Platform.isAndroid) {
        return 'http://10.0.2.2:8000/api/v1';
      }
    } catch (_) {}
    return 'http://127.0.0.1:8000/api/v1';
  }

  static set baseUrl(String url) {
    _customBaseUrl = url;
  }

  /// Detects if Flutter is running inside unit tests
  static bool get isTestEnvironment {
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  /// In unit tests, fail network quickly so offline test mocks are instant.
  /// In live app, use generous 5s timeout.
  static Duration get timeout => 
      isTestEnvironment ? const Duration(milliseconds: 50) : const Duration(seconds: 5);
}
