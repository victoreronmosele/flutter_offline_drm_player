import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'bare_player_plugin_platform_interface.dart';

/// An implementation of [BarePlayerPluginPlatform] that uses method channels.
class MethodChannelBarePlayerPlugin extends BarePlayerPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('bare_player_plugin');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<void> play({required String url}) async {
    methodChannel.invokeMethod<void>('play', <String, dynamic>{
      'url': url,
    });
  }

  @override
  void setUpStateListener(
      {required void Function(String) onPlaybackStateChanged,
      required void Function(String) onIsPlayingChanged,
      required void Function(String) onUrlChanged,
      required void Function(String) onKeyAvailable}) {
    print('Flutter/setUpStateListener');
    methodChannel.setMethodCallHandler((call) async {
      final method = call.method;
      final args = call.arguments;

      if (method == 'onPlaybackStateChanged') {
        onPlaybackStateChanged(args);
      }

      if (method == 'onIsPlayingChanged') {
        onIsPlayingChanged(args);
      }

      if (method == 'onKeyAvailable') {
        onKeyAvailable(args);
      }

      if (method == 'onUrlChanged') {
        onUrlChanged(args);
      }
    });
  }

  @override
  Future<void> playDRMOnline({
    required String url,
    required String licenseUrl,
     Map<String, String>? licenseRequestHeader,
  }) async {
    methodChannel.invokeMethod<void>('playDRMOnline', <String, dynamic>{
      'url': url,
      'licenseUrl': licenseUrl,
      'licenseRequestHeader':licenseRequestHeader
    });
  }

  @override
  Future<void> playDRMOffline(
      {required String url,
      required String licenseUrl,
      required String key}) async {
    methodChannel.invokeMethod<void>('playDRMOffline', <String, dynamic>{
      'url': url,
      'licenseUrl': licenseUrl,
      'licenseKey': key,
    });
  }

  @override
  Future<void> stop() async {
    methodChannel.invokeMethod<void>('stop');
  }
}
