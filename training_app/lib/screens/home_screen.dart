import 'package:flutter/material.dart';

import '../app_state/training_orchestrator.dart';
import '../models/protocol_config.dart';
import '../services/session_store.dart';
import 'encode_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.sessionStore});

  final SessionStore sessionStore;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _modality = ProtocolConfig.modalityCards;
  int _length = 4; // 4 pares = prueba rápida; subir a 10 en producción
  final double _speed = 2.0;
  int _sessionN = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training lab'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Motor de entrenamiento (cartas y números, JSONL). Tercer motor — sin Alexandria/LB.\n[ACUERDO_CHAT_DEEP]',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 16),
          const Text('Modalidad', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: ProtocolConfig.modalityCards,
                label: Text('Cartas'),
                icon: Icon(Icons.style),
              ),
              ButtonSegment(
                value: ProtocolConfig.modalityDigits,
                label: Text('Números'),
                icon: Icon(Icons.pin),
              ),
            ],
            selected: {_modality},
            onSelectionChanged: (s) {
              if (s.isEmpty) return;
              setState(() => _modality = s.first);
            },
          ),
          const SizedBox(height: 20),
          Text('Longitud de la secuencia: $_length'),
          Slider(
            value: _length.toDouble(),
            min: 1,
            max: 20,
            divisions: 19,
            label: '$_length',
            onChanged: (v) {
              setState(() => _length = v.round());
            },
          ),
          const Text(
            'Ritmo encode: 2 s/estímulo (cambio manual en config más adelante).',
            style: TextStyle(fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _start,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Iniciar sesión'),
          ),
        ],
      ),
    );
  }

  void _start() {
    final c = ProtocolConfig(
      modality: _modality,
      chunkSize: 2,
      sequenceLength: _length,
      targetSpeedSec: _speed,
      sessionNumber: _sessionN,
    );
    setState(() => _sessionN++);
    final s = ActiveTrainingSession()..newRun(c);
    if (!mounted) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => EncodeScreen(
          session: s,
          store: widget.sessionStore,
        ),
      ),
    );
  }
}
