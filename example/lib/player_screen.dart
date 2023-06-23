import 'package:flutter/material.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
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
            const PlayerSection()
          ],
        ),
      ),
    );
  }
}

class PlayerSection extends StatefulWidget {
  const PlayerSection({super.key});

  @override
  State<PlayerSection> createState() => _PlayerSectionState();
}

class _PlayerSectionState extends State<PlayerSection> {
  final markers = markersResponse
      .map((chapterJson) => Chapter.fromJson(chapterJson))
      .toList();

  final positionNotifier = ValueNotifier<Duration>(Duration.zero);
  final durationNotifier = ValueNotifier<Duration>(Duration.zero);

  final isPlaying = ValueNotifier<bool>(false);
  final playingChapter = ValueNotifier<Chapter>(Chapter.empty());

  @override
  Widget build(BuildContext context) {
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
                      onPressed: () {},
                      icon: Icon(
                        isPlaying.value
                            ? Icons.pause_circle
                            : Icons.play_circle,
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
                          style: const TextStyle(fontSize: 16,
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
  final minutes = duration.inMinutes - (hours * 60);
  final seconds = duration.inSeconds - (minutes * 60);
  return "${hours.toString().padLeft(2, "0")}:${minutes.toString().padLeft(2, "0")}:${seconds.toString().padLeft(2, "0")}";
}
