import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'config.dart';
import 'flutter_crisp_chat_platform_interface.dart';

/// An implementation of [FlutterCrispChatPlatform] that uses method channels.
class MethodChannelFlutterCrispChat extends FlutterCrispChatPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_crisp_chat');

  /// Opens Crisp Chat with UI
  @override
  Future<void> openCrispChat({required CrispConfig config}) async {
    await methodChannel.invokeMethod<CrispConfig>(
      'openCrispChat',
      config.toJson(),
    );
  }

  /// Configures Crisp session silently (no UI)
  Future<void> configureCrispSession({required CrispConfig config}) async {
    await methodChannel.invokeMethod<CrispConfig>(
      'configureCrispSession',
      config.toJson(),
    );
  }

  /// Resets the Crisp chat session
  @override
  Future<void> resetCrispChatSession() async {
    await methodChannel.invokeMethod('resetCrispChatSession');
  }

  /// Sets a session string key/value
  @override
  void setSessionString({required String key, required String value}) {
    methodChannel.invokeMethod('setSessionString', <String, String>{
      'key': key,
      'value': value,
    });
  }

  /// Sets a session int key/value
  @override
  void setSessionInt({required String key, required int value}) {
    methodChannel.invokeMethod('setSessionInt', <String, dynamic>{
      'key': key,
      'value': value,
    });
  }

  /// Gets the session identifier
  @override
  Future<String?> getSessionIdentifier() async {
    try {
      final sessionId = await methodChannel.invokeMethod<String>(
        'getSessionIdentifier',
      );
      return sessionId;
    } on PlatformException catch (e) {
      debugPrint("Failed to get session identifier: '${e.message}'.");
      return null;
    }
  }

  /// Sets session segments
  @override
  void setSessionSegments({
    required List<String> segments,
    bool overwrite = false,
  }) {
    methodChannel.invokeMethod('setSessionSegments', <String, dynamic>{
      'segments': segments,
      'overwrite': overwrite,
    });
  }

  /// Pushes a session event
  @override
  Future<void> pushSessionEvent({
    required String name,
    SessionEventColor color = SessionEventColor.blue,
  }) async {
    await methodChannel.invokeMethod('pushSessionEvent', <String, dynamic>{
      'name': name,
      'color': color.name.toString(),
    });
  }
}
