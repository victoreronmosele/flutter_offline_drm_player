import 'bare_player_plugin_platform_interface.dart';

class BarePlayerPlugin {
  Future<void> play({required String url}) async {
    return BarePlayerPluginPlatform.instance.play(url: url);
  }

  void setUpStateListener(
      {required void Function(String) onPlaybackStateChanged,
      required void Function(String) onIsPlayingChanged,
      required void Function(String) onUrlChanged,
      required void Function(String) onLicenseKeyAvailable,
      required void Function(int) onDurationChanged,
      }) {
    BarePlayerPluginPlatform.instance.setUpStateListener(
        onPlaybackStateChanged: onPlaybackStateChanged,
        onUrlChanged: onUrlChanged,
        onIsPlayingChanged: onIsPlayingChanged,
        onKeyAvailable: onLicenseKeyAvailable,
        onDurationChanged: onDurationChanged,
    );
  }

  Future<void> playDRMOnline({
    required String url,
    required String licenseUrl,
    Map<String, String>? licenseRequestHeader,
  }) async {
    return BarePlayerPluginPlatform.instance.playDRMOnline(
      url: url,
      licenseUrl: licenseUrl,
      licenseRequestHeader: licenseRequestHeader,
    );
  }

  Future<void> playDRMOffline(
      {required String url,
      required String licenseUrl,
      required String licenseKey}) async {
    return BarePlayerPluginPlatform.instance
        .playDRMOffline(url: url, licenseUrl: licenseUrl, key: licenseKey);
  }

  Future<void> stop() {
    return BarePlayerPluginPlatform.instance.stop();
  }

  Future<void> seekToPosition({required int seconds}) {
    return BarePlayerPluginPlatform.instance.seekToPosition(seconds: seconds);
  }

  Future<void> pause() {
    return BarePlayerPluginPlatform.instance.pause();
  }

  Future<void> resume() {
    return BarePlayerPluginPlatform.instance.resume();
  }
}
