import 'package:bare_player_plugin_example/shared_preferences_util.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:bare_player_plugin/bare_player_plugin.dart';
import 'package:flutter_offline/flutter_offline.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _barePlayerPlugin = BarePlayerPlugin();

  final nonEncryptedUrl =
      'https://samples-files.com/samples/Audio/mp3/sample-file-1.mp3';

  final encryptedUrl =
      'https://1cdb1f9f9b7a67ca92aaa815.blob.core.windows.net/video-output/7iTqGEuWa6bj8AmSujqho4/cmaf/manifest.mpd';
  // 'https://1cdb1f9f9b7a67ca92aaa815.blob.core.windows.net/video-output/8p4Fq8kD4smqzbExdQTPwt/cmaf/manifest.mpd';
  // 'https://bitmovin-a.akamaihd.net/content/art-of-motion_drm/mpds/11331.mpd';
  final licenseUrl =
      'https://proxy.uat.widevine.com/proxy?provider=widevine_test';

  final encryptedUrlWithHeaders =
      "https://media.axprod.net/TestVectors/v7-MultiDRM-SingleKey/Manifest_AudioOnly.mpd";
  final licenseUrlWithHeaders =
      "https://drm-widevine-licensing.axtest.net/AcquireLicense";
  final licenseRequestHeader = {
    "X-AxDRM-Message":
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ2ZXJzaW9uIjoxLCJjb21fa2V5X2lkIjoiYjMzNjRlYjUtNTFmNi00YWUzLThjOTgtMzNjZWQ1ZTMxYzc4IiwibWVzc2FnZSI6eyJ0eXBlIjoiZW50aXRsZW1lbnRfbWVzc2FnZSIsInZlcnNpb24iOjIsImxpY2Vuc2UiOnsiYWxsb3dfcGVyc2lzdGVuY2UiOnRydWV9LCJjb250ZW50X2tleXNfc291cmNlIjp7ImlubGluZSI6W3siaWQiOiI5ZWI0MDUwZC1lNDRiLTQ4MDItOTMyZS0yN2Q3NTA4M2UyNjYiLCJlbmNyeXB0ZWRfa2V5IjoibEszT2pITFlXMjRjcjJrdFI3NGZudz09IiwidXNhZ2VfcG9saWN5IjoiUG9saWN5IEEifV19LCJjb250ZW50X2tleV91c2FnZV9wb2xpY2llcyI6W3sibmFtZSI6IlBvbGljeSBBIiwicGxheXJlYWR5Ijp7Im1pbl9kZXZpY2Vfc2VjdXJpdHlfbGV2ZWwiOjE1MCwicGxheV9lbmFibGVycyI6WyI3ODY2MjdEOC1DMkE2LTQ0QkUtOEY4OC0wOEFFMjU1QjAxQTciXX19XX19.W2FbPDSDaq-LeeLfOnbpTMa-zCmXh8RLChEVDYvdcVw"
  };

  String _url = 'Not Available';
  String playbackState = 'Not Available';
  String _source = 'Not Available';
  bool playing = false;

  String? licenseKey;

  SharedPreferencesUtil? sharedPreferences;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      initialize();
    });
  }

  Future<void> initialize() async {
    sharedPreferences = await SharedPreferencesUtil.initialize();

    final licenseKeyInStorage = sharedPreferences?.getLicenseKey();

    print('licenseKeyInStorage: $licenseKeyInStorage');

    if (licenseKeyInStorage != null) {
      setState(() {
        licenseKey = licenseKeyInStorage;
      });
    }

    _barePlayerPlugin.setUpStateListener(onPlaybackStateChanged: (state) {
      setState(() {
        playbackState = state;
      });
    }, onIsPlayingChanged: (isPlaying) {
      const playingString = "PLAYING";

      setState(() {
        playing = isPlaying == playingString;
      });
    }, onLicenseKeyAvailable: (key) {
      setState(() {
        licenseKey = key;
      });

      sharedPreferences?.setLicenseKey(key);
    }, onUrlChanged: (url) {
      setState(() {
        _url = url;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        useMaterial3: true,
        cardTheme: Theme.of(context)
            .cardTheme
            .copyWith(color: const Color(0xff101010)),
        scaffoldBackgroundColor: const Color(0xff101010),
        appBarTheme: Theme.of(context).appBarTheme.copyWith(
              backgroundColor: const Color(0xff101010),
              foregroundColor: Colors.white,
            ),
      ),
      home: Banner(
        message: 'Experimental',
        location: BannerLocation.topEnd,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Plugin POC app'),
            actions: [
              if (playing)
                IconButton(
                  onPressed: () {
                    _barePlayerPlugin.stop();
                  },
                  icon: const Icon(Icons.stop),
                ),
            ],
          ),
          body: OfflineBuilder(
            connectivityBuilder: (
              BuildContext context,
              ConnectivityResult connectivity,
              Widget child,
            ) {
              final bool connected = connectivity != ConnectivityResult.none;
              return Column(
                children: [
                  AnimatedOpacity(
                    duration: Duration(milliseconds: connected ? 600 : 300),
                    opacity: !connected ? 1.0 : 0.0,
                    child: Container(
                      color: connected
                          ? const Color(0xFF00EE44)
                          : const Color(0xFFEE4400),
                      child: Center(
                        child: Text(connected ? 'ONLINE' : 'OFFLINE'),
                      ),
                    ),
                  ),
                  Expanded(child: child),
                ],
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  MediaPlayerStatusCard(
                    status: playbackState,
                    url: _url,
                    source: _source,
                    playing: playing,
                  ),
                  const SizedBox(height: 54),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _source = 'Online (Non DRM)';
                      });
                      _barePlayerPlugin.play(
                        url: nonEncryptedUrl,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Play Online Audio'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _source = 'Online (DRM)';
                      });
                      _barePlayerPlugin.playDRMOnline(
                        url: encryptedUrl,
                        licenseUrl: licenseUrl,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Play Online Audio With DRM Protection'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _source = 'Online (DRM) With LicenseHeader';
                      });
                      _barePlayerPlugin.playDRMOnline(
                          url: encryptedUrlWithHeaders,
                          licenseUrl: licenseUrlWithHeaders,
                          licenseRequestHeader: licenseRequestHeader);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                        'Play Online Audio With DRM Protection And HeaderRequest'),
                  ),
                  const SizedBox(height: 20),
                  Column(
                    children: [
                      Row(
                        children: [
                          const Text(
                            '⚡',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Center(
                              child: ElevatedButton(
                                onPressed: licenseKey == null
                                    ? null
                                    : () {
                                        setState(() {
                                          _source = 'Local (DRM)';
                                        });

                                        try {
                                          _barePlayerPlugin.playDRMOffline(
                                            url: encryptedUrl,
                                            licenseUrl: licenseUrl,
                                            licenseKey: licenseKey!,
                                          );
                                        } catch (e) {
                                          print(e);
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text(
                                    'Play Local Audio With DRM Protection'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 28),
                        ],
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      if (licenseKey == null)
                        const FractionallySizedBox(
                          widthFactor: 0.8,
                          child: Text(
                            'Local audio with DRM protection can only be played after playing it online first',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w300,
                                letterSpacing: 1),
                          ),
                        ),
                      SizedBox(height: 20),
                      IconButton(
                        onPressed: () {
                          _barePlayerPlugin.seekToPosition(seconds: 3);
                        },
                        icon: Icon(Icons.skip_next),
                        iconSize: 48,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MediaPlayerStatusCard extends StatelessWidget {
  final String status;
  final String url;
  final String source;
  final bool playing;

  const MediaPlayerStatusCard({
    super.key,
    required this.status,
    required this.url,
    required this.source,
    required this.playing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Bare Player Status',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DefaultTextStyle.merge(
                    style: const TextStyle(
                      fontSize: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Source: $source',
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Player State*: $status',
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Url*: $url',
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Player Activity*: ${playing ? "Playing" : "Not Playing"}',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Center(
                      child: LayoutBuilder(
                    builder: (context, constraints) => SizedBox(
                      width: constraints.maxWidth,
                      height: constraints.maxWidth,
                      child: SpinningCoverCircle(
                        key: ObjectKey([url, source]),
                        isSpinning: playing,
                      ),
                    ),
                  )),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              '*Realtime from ${defaultTargetPlatform.name} via platform channels:',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SpinningCoverCircle extends StatefulWidget {
  const SpinningCoverCircle({
    super.key,
    required this.isSpinning,
  });

  final bool isSpinning;

  @override
  State<SpinningCoverCircle> createState() => _SpinningCoverCircleState();
}

class _SpinningCoverCircleState extends State<SpinningCoverCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat();

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    );

    if (widget.isSpinning) {
      _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void didUpdateWidget(covariant SpinningCoverCircle oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isSpinning) {
      _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _animation,
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/cover.jpeg'),
                fit: BoxFit.cover,
              ),
              shape: BoxShape.circle,
            ),
          ),
          Center(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).cardTheme.color!,
              ),
              height: 20,
              width: 20,
            ),
          ),
        ],
      ),
    );
  }
}
