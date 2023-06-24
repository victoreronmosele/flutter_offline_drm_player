import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'bare_player_plugin_method_channel.dart';

abstract class BarePlayerPluginPlatform extends PlatformInterface {
  /// Constructs a BarePlayerPluginPlatform.
  BarePlayerPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static BarePlayerPluginPlatform _instance = MethodChannelBarePlayerPlugin();

  /// The default instance of [BarePlayerPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelBarePlayerPlugin].
  static BarePlayerPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [BarePlayerPluginPlatform] when
  /// they register themselves.
  static set instance(BarePlayerPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<void> play({required String url}) {
    throw UnimplementedError('play() has not been implemented.');
  }

  void setUpStateListener(
      {required void Function(String) onPlaybackStateChanged,
      required void Function(String) onIsPlayingChanged,
      required void Function(String) onUrlChanged,
      required void Function(String) onKeyAvailable,
      required void Function(int) onDurationChanged,
      }) {
    throw UnimplementedError('setUpStateListener() has not been implemented.');
  }

  Future<void> playDRMOnline({
    required String url,
    required String licenseUrl,
    Map<String, String>? licenseRequestHeader,
  }) {
    throw UnimplementedError('playDRM() has not been implemented.');
  }

  Future<void> playDRMOffline(
      {required String url, required String licenseUrl, required String key}) {
    throw UnimplementedError('playDRM() has not been implemented.');
  }

  Future<void> stop() {
    throw UnimplementedError('stop() has not been implemented.');
  }

  Future<void> seekToPosition({required int seconds}) {
    throw UnimplementedError('seekToPosition() has not been implemented.');
  }

  Future<void> pause() {
    throw UnimplementedError('pause() has not been implemented.');
  }

  Future<void> resume() {
    throw UnimplementedError('resume() has not been implemented.');
  }
}
