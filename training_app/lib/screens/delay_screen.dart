import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state/training_orchestrator.dart';
import '../services/session_store.dart';
import 'recall_screen.dart';

class DelayScreen extends StatefulWidget {
  const DelayScreen({super.key, required this.session, required this.store});

  final ActiveTrainingSession session;
  final SessionStore store;

  @override
  State<DelayScreen> createState() => _DelayScreenState();
}

class _DelayScreenState extends State<DelayScreen> {
  int _left = 60;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (tm) {
      if (!mounted) {
        tm.cancel();
        return;
      }
      if (_left <= 1) {
        tm.cancel();
        _go();
        return;
      }
      setState(() => _left--);
    });
  }

  Future<void> _go() async {
    _t?.cancel();
    if (!mounted) {
      return;
    }
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (ctx) => RecallScreen(
          session: widget.session,
          store: widget.store,
          phase: 'recall_delayed',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: const Text('Pausa'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _go,
            child: const Text('Skip'),
          ),
        ],
      ),
      body: Center(
        child: Text(
          '$_left s',
          style: const TextStyle(fontSize: 56, color: Colors.white30),
        ),
      ),
    );
  }
}
