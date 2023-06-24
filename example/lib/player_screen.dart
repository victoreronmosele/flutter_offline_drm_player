import 'package:bare_player_plugin/bare_player_plugin.dart';
import 'package:flutter/material.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final playingString = "PLAYING";

  final _barePlayerPlugin = BarePlayerPlugin();

  // encrypted url with id3 chapter tags
  // "https://www.podtrac.com/pts/redirect.mp3/traffic.libsyn.com/upgrade/Upgrade_124.mp3"
  final url =
      "https://samples-files.com/samples/Audio/mp3/sample-file-1.mp3";

  bool playing = false;
  bool playingHasStarted = false;

  double durationInSeconds = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      initialize();
    });
  }

  Future<void> initialize() async {
    _barePlayerPlugin.setUpStateListener(
      onPlaybackStateChanged: (state) {},
      onIsPlayingChanged: (isPlaying) {
        setState(() {
          playing = isPlaying == playingString;

          if (playing && !playingHasStarted) {
            playingHasStarted = true;
          }
        });
      },
      onLicenseKeyAvailable: (key) {},
      onUrlChanged: (url) {},
      onDurationChanged: (duration) {
        setState(() {
          durationInSeconds = duration / 1000;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20.0),
              height: 320,
              width: double.infinity,
              decoration:
                  BoxDecoration(borderRadius: BorderRadius.circular(24)),
              child: Image.asset(
                "assets/cover.jpeg",
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 48),
            PlayerSection(
              isPlaying: playing,
              onPlay: () async {
                if (playingHasStarted) {
                  _barePlayerPlugin.resume();
                } else {
                  _barePlayerPlugin.play(url: url);
                }
              },
              onPause: () {
                _barePlayerPlugin.pause();
              },
              durationInSeconds: durationInSeconds,
            )
          ],
        ),
      ),
    );
  }
}

class PlayerSection extends StatefulWidget {
  const PlayerSection({
    super.key,
    required this.isPlaying,
    required this.onPlay,
    required this.onPause,
    required this.durationInSeconds,
  });

  final bool isPlaying;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final double durationInSeconds;

  @override
  State<PlayerSection> createState() => _PlayerSectionState();
}

class _PlayerSectionState extends State<PlayerSection> {
  final markers = markersResponse
      .map((chapterJson) => Chapter.fromJson(chapterJson))
      .toList();

  final positionNotifier = ValueNotifier<Duration>(Duration.zero);
  final durationNotifier = ValueNotifier<Duration>(Duration.zero);

  final playingChapter = ValueNotifier<Chapter>(Chapter.empty());

  @override
  Widget build(BuildContext context) {
    final timeLeftString = getTimeLeft(
        durationInSeconds: widget.durationInSeconds,
        value: positionNotifier.value);

    return ValueListenableBuilder(
        valueListenable: positionNotifier,
        builder: (context, sliderValue, child) {
          return Container(
            height: 240,
            width: double.infinity,
            color: Colors.black45,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    IconButton(
                        color: Colors.white,
                        icon: const Icon(Icons.list, size: 28),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ChaptersScreen(chapters: markers),
                            ),
                          ).then((selectedChapter) {
                            if (selectedChapter == null) return;

                            setState(() {
                              playingChapter.value = selectedChapter;
                            });
                          });
                        }),
                    const SizedBox(width: 48),
                    Text(
                      playingChapter.value.label,
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Slider(
                  min: 0,
                  max: playingChapter.value.endPosition.inSeconds.toDouble(),
                  value: sliderValue.inSeconds.toDouble(),
                  onChanged: (value) {},
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formatToReadableDuration(positionNotifier.value),
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        timeLeftString.isEmpty ? "" : "$timeLeftString left",
                      ),
                      Text(
                        formatToReadableDuration(
                            playingChapter.value.endPosition),
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.skip_previous,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.replay_30_sharp,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        widget.isPlaying ? widget.onPause() : widget.onPlay();
                      },
                      icon: AnimatedIcon(
                        icon: AnimatedIcons.play_pause,
                        progress:
                            AlwaysStoppedAnimation(widget.isPlaying ? 1 : 0),
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.forward_30_sharp,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.skip_next,
                        color: Colors.white,
                      ),
                    )
                  ],
                )
              ],
            ),
          );
        });
  }
}

class ChaptersScreen extends StatelessWidget {
  const ChaptersScreen({required this.chapters, super.key});
  final List<Chapter> chapters;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SafeArea(
          child: ListView.builder(
              itemCount: chapters.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => Navigator.pop(context, chapters[index]),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          chapters[index].label,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          formatToReadableDuration(
                              chapters[index].startPosition),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        )
                      ],
                    ),
                  ),
                );
              }),
        ),
      ),
    );
  }
}

/// Response and Model
/// 00:20:37
final markersResponse = [
  {
    "label": "Chapter 1",
    "start_position": "00:00:00",
    "end_position": "00:00:28"
  },
  {
    "label": "Chapter 2",
    "start_position": "00:00:29",
    "end_position": "00:03:19"
  },
  {
    "label": "Chapter 3",
    "start_position": "00:03:20",
    "end_position": "00:08:19"
  },
  {
    "label": "Chapter 4",
    "start_position": "00:08:20",
    "end_position": "00:11:40"
  },
  {
    "label": "Chapter 5",
    "start_position": "00:11:41",
    "end_position": "00:20:37"
  },
];

class Chapter {
  const Chapter({
    required this.startPosition,
    required this.endPosition,
    required this.label,
  });
  final String label;
  final Duration startPosition, endPosition;

  factory Chapter.empty() {
    return const Chapter(
        startPosition: Duration.zero, label: "", endPosition: Duration.zero);
  }

  factory Chapter.fromJson(Map<String, dynamic> json) => Chapter(
        startPosition: formatToDuration(json["start_position"]),
        endPosition: formatToDuration(json["end_position"]),
        label: json["label"],
      );
}

///Utils
Duration formatToDuration(String stringDuration) {
  final timeParts = stringDuration.split(":");
  return Duration(
    hours: int.tryParse(timeParts[0]) ?? 0,
    minutes: int.tryParse(timeParts[1]) ?? 0,
    seconds: int.tryParse(timeParts[2]) ?? 0,
  );
}

String formatToReadableDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);
  return "${hours.toString().padLeft(2, "0")}:${minutes.toString().padLeft(2, "0")}:${seconds.toString().padLeft(2, "0")}";
}

String formatToReadableDurationForTimeLeft(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);
  return "${hours}h ${minutes}m ${seconds}s";
}


String getTimeLeft({
  required double durationInSeconds,
  required Duration value,
}) {
  if (durationInSeconds == 0) return '';

  final duration = Duration(seconds: durationInSeconds.toInt());

  final timeLeft = duration - value;

  return formatToReadableDurationForTimeLeft(timeLeft);
}
