import 'package:flutter/foundation.dart';

import 'src/config.dart';
import 'src/flutter_crisp_chat_platform_interface.dart';
import 'src/helper.dart';

export 'src/config.dart';

/// [FlutterCrispChat] to call the native platform method.
class FlutterCrispChat {
  /// Opens the Crisp chat interface.
  ///
  /// This method initializes and displays the Crisp chat view using the
  /// provided [config].
  ///
  /// {@category General}
  /// @param config The configuration object for Crisp chat.
  /// @return A [Future] that completes when the chat is opened.
  /// @throws Exception if the user email in [config] is invalid.
  /// @throws Exception if the company URL in [config] is invalid.
  static Future<void> openCrispChat({required CrispConfig config}) {
    // Validate email if provided
    final email = config.user?.email;
    if (email != null && !email.isEmail) {
      throw ArgumentError.value(
          email, 'config.user.email', 'Invalid email format provided.');
    }

    // Validate company URL if provided
    final url = config.user?.company?.url;
    if (url != null && !url.isUrl) {
      throw ArgumentError.value(url, 'config.user.company.url',
          'Invalid company URL format provided.');
    }

    // ✅ Pass locale to the platform
    return FlutterCrispChatPlatform.instance.openCrispChat(config: config);
  }

  /// Resets the current Crisp chat session.
  static Future<void> resetCrispChatSession() {
    return FlutterCrispChatPlatform.instance.resetCrispChatSession();
  }

  /// Sets a string value in the current session data.
  static void setSessionString({required String key, required String value}) {
    if (key.isEmpty || value.isEmpty) {
      throw ArgumentError('Key and value for session data must not be empty.');
    }
    FlutterCrispChatPlatform.instance.setSessionString(key: key, value: value);
  }

  /// Sets an integer value in the current session data.
  static void setSessionInt({required String key, required int value}) {
    if (key.isEmpty) {
      throw ArgumentError('Key for session data must not be empty.');
    }
    FlutterCrispChatPlatform.instance.setSessionInt(key: key, value: value);
  }

  /// Retrieves the current Crisp session identifier.
  static Future<String?> getSessionIdentifier() async {
    try {
      final sessionId =
          await FlutterCrispChatPlatform.instance.getSessionIdentifier();
      return sessionId;
    } catch (e) {
      if (kDebugMode) {
        print("Error retrieving session identifier: $e");
      }
      return null;
    }
  }

  /// Sets user segments in the current session.
  static void setSessionSegments({
    required List<String> segments,
    bool overwrite = false,
  }) {
    FlutterCrispChatPlatform.instance.setSessionSegments(
      segments: segments,
      overwrite: overwrite,
    );
  }

  /// Sends a custom event to the Crisp session.
  static Future<void> pushSessionEvent({
    required String name,
    SessionEventColor color = SessionEventColor.blue,
  }) {
    return FlutterCrispChatPlatform.instance.pushSessionEvent(
      name: name,
      color: color,
    );
  }
}
