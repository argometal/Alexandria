import 'package:flutter/material.dart';

import 'alexandria_app_log.dart';
import 'screens/home_screen.dart';
import 'services/session_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AlexandriaAppLog.init();
  final store = await SessionStore.create();
  runApp(TrainingApp(sessionStore: store));
}

class TrainingApp extends StatelessWidget {
  const TrainingApp({super.key, required this.sessionStore});

  final SessionStore sessionStore;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Training lab',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B4A2E),
          brightness: Brightness.dark,
        ),
      ),
      home: HomeScreen(sessionStore: sessionStore),
    );
  }
}
