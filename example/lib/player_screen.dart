import 'package:bare_player_plugin/bare_player_plugin.dart';
import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final playingString = "PLAYING";

  final _barePlayerPlugin = BarePlayerPlugin();

  //  url with id3 chapter tags
  // "https://www.podtrac.com/pts/redirect.mp3/traffic.libsyn.com/upgrade/Upgrade_124.mp3"
  final audioUrl =
      "https://1cdb1f9f9b7a67ca92aaa815.blob.core.windows.net/video-output/7iTqGEuWa6bj8AmSujqho4/cmaf/manifest.mpd";

  final coverImageUrl = "https://m.media-amazon.com/images/I/51-nXsSRfZL.jpg";

  bool playing = false;
  bool playingHasStarted = false;

  double durationInSeconds = 0;
  double positionInSeconds = 0;

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
      onPositionChanged: (position) {
        setState(() {
          positionInSeconds = position / 1000;
        });

        print("=>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> $positionInSeconds");
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
            Expanded(
              child: CoverImage(url: coverImageUrl),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: PlayerSection(
                isPlaying: playing,
                onPlay: () async {
                  if (playingHasStarted) {
                    _barePlayerPlugin.resume();
                  } else {
                    _barePlayerPlugin.play(url: audioUrl);
                  }
                },
                onPause: () {
                  _barePlayerPlugin.pause();
                },
                onChapterChanged: (position) {
                  print('chapter changed to $position');
                  _barePlayerPlugin.seekToPosition(seconds: position * 1000);
                },
                durationInSeconds: durationInSeconds,
                positionInSeconds: positionInSeconds,
              ),
            )
          ],
        ),
      ),
    );
  }
}

class CoverImage extends StatelessWidget {
  const CoverImage({
    super.key,
    required this.url,
  });

  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      width: double.infinity,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)),
      child: Image.network(
        url,
        fit: BoxFit.contain,
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
    required this.onChapterChanged,
    required this.durationInSeconds,
    required this.positionInSeconds,
  });

  final bool isPlaying;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final void Function(int) onChapterChanged;
  final double durationInSeconds;
  final double positionInSeconds;

  @override
  State<PlayerSection> createState() => _PlayerSectionState();
}

class _PlayerSectionState extends State<PlayerSection> {
  static final markers = markersResponse
      .map((chapterJson) => Chapter.fromJson(chapterJson))
      .toList();

  final playingChapter = ValueNotifier<Chapter>(markers.first);

  @override
  Widget build(BuildContext context) {
    final minSliderValue =
        playingChapter.value.startPosition.inSeconds.toDouble();

    final endPosition =
        playingChapter.value.endPosition?.inSeconds.toDouble() ??
            widget.durationInSeconds;

    final maxSliderValue = endPosition;

    final timeLeftString = getTimeLeft(
        durationInSeconds: widget.durationInSeconds,
        positionInSeconds: widget.positionInSeconds);

    final timeSpent = widget.positionInSeconds == 0
        ? 0
        : (widget.positionInSeconds -
            playingChapter.value.startPosition.inSeconds.toDouble());

    final double sliderValue = (timeSpent > endPosition || timeSpent <= 0)
        ? playingChapter.value.startPosition.inSeconds.toDouble()
        : (maxSliderValue < widget.positionInSeconds)
            ? minSliderValue
            : widget.positionInSeconds;

    final chapterIndex = markers.indexOf(playingChapter.value);

    return Container(
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
                        builder: (context) => ChaptersScreen(
                          chapters: markers,
                          currentChapterIndex:
                              chapterIndex == -1 ? 0 : chapterIndex,
                        ),
                      ),
                    ).then((selectedChapter) {
                      if (selectedChapter == null) return;

                      setState(() {
                        playingChapter.value = selectedChapter;
                      });

                      widget.onChapterChanged(
                          selectedChapter.startPosition.inSeconds);
                    });
                  }),
              const SizedBox(width: 48),
              Expanded(
                child: Text(
                  playingChapter.value.label,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Slider(
            min: minSliderValue,
            max: maxSliderValue,
            value: sliderValue,
            onChanged: (value) {},
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatToReadableDuration(
                      Duration(seconds: widget.positionInSeconds.toInt())),
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
                Text(
                  timeLeftString.isEmpty ? "" : "$timeLeftString left",
                ),
                Text(
                  formatToReadableDuration(
                      Duration(seconds: endPosition.toInt())),
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.skip_previous,
                  color: Colors.white,
                ),
                iconSize: 44,
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.replay_30_sharp,
                  color: Colors.white,
                ),
                iconSize: 44,
              ),
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () {
                    widget.isPlaying ? widget.onPause() : widget.onPlay();
                  },
                  icon: AnimatedIcon(
                    icon: AnimatedIcons.play_pause,
                    progress: AlwaysStoppedAnimation(widget.isPlaying ? 1 : 0),
                    color: Colors.black,
                  ),
                  iconSize: 64,
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.forward_30_sharp,
                  color: Colors.white,
                ),
                iconSize: 44,
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.skip_next,
                  color: Colors.white,
                ),
                iconSize: 44,
              )
            ],
          )
        ],
      ),
    );
  }
}

class ChaptersScreen extends StatelessWidget {
  const ChaptersScreen(
      {required this.chapters, required this.currentChapterIndex, super.key});

  final List<Chapter> chapters;
  final int currentChapterIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
      ),
      body: SafeArea(
        child: ListView.builder(
            itemCount: chapters.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => Navigator.pop(context, chapters[index]),
                child: Container(
                  decoration: BoxDecoration(
                    color: index == this.currentChapterIndex
                        ? Colors.blue.withOpacity(0.3)
                        : Colors.transparent,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 20.0, horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            chapters[index].label,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            formatToReadableDuration(
                                chapters[index].startPosition),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                            ),
                            textAlign: TextAlign.end,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              );
            }),
      ),
    );
  }
}

final markersResponse = [
  {
    "label": "Opening Credits",
    "start_position": "00:00:00",
    "end_position": "00:01:59"
  },
  {
    "label": "Introduction: My Story",
    "start_position": "00:02:00",
    "end_position": "00:04:00"
  },
  {
    "label": "The Fundamentals: Why Tiny Changes Make a Big Difference",
    "start_position": "00:04:01",
  }
];

class Chapter extends Equatable {
  const Chapter({
    required this.startPosition,
    required this.label,
    this.endPosition,
  });
  final String label;
  final Duration startPosition;
  final Duration? endPosition;

  factory Chapter.fromJson(Map<String, dynamic> json) => Chapter(
        startPosition: formatToDuration(json["start_position"]),
        endPosition: json["end_position"] == null
            ? null
            : formatToDuration(json["end_position"]),
        label: json["label"],
      );

  @override
  List<Object?> get props => [startPosition, endPosition, label];
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
  return "${hours == 0 ? '' : '${hours}h '}${minutes}m ${seconds}s";
}

String getTimeLeft({
  required double durationInSeconds,
  required double positionInSeconds,
}) {
  if (durationInSeconds == 0) return '';

  final timeLeft = Duration(
    seconds: (durationInSeconds - positionInSeconds).toInt(),
  );

  return formatToReadableDurationForTimeLeft(timeLeft);
}
