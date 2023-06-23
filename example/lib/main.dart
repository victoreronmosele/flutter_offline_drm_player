import 'package:bare_player_plugin_example/player_screen.dart';
import 'package:flutter/material.dart';

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
        home: const PlayerScreen());
  }
}
