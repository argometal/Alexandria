import 'package:flutter/material.dart';
import 'library_build.dart';

void main() {
  runApp(const LBApp());
}

class LBApp extends StatelessWidget {
  const LBApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LBHome(),
    );
  }
}

class LBHome extends StatefulWidget {
  const LBHome({super.key});

  @override
  State<LBHome> createState() => _LBHomeState();
}

class _LBHomeState extends State<LBHome> {

  String status = 'READY';

void runBuild() {
  setState(() {
    status = 'RUNNING';
  });

  runLibraryBuild();

  setState(() {
    status = 'DONE';
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            ElevatedButton(
              onPressed: runBuild,
              child: const Text('BUILD'),
            ),

            const SizedBox(height: 20),

            Text(
              status,
              style: const TextStyle(color: Colors.white),
            ),

          ],
        ),
      ),
    );
  }
}