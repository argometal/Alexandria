import '../models/event.dart';
import '../models/protocol_config.dart';
import '../models/session_id.dart';
import '../models/stimulus.dart';
import '../services/input_parser.dart';
import '../services/stimulus_generator.dart';

class ActiveTrainingSession {
  ActiveTrainingSession() : sessionId = newTrainingSessionId();

  String sessionId;
  ProtocolConfig? config;
  List<Stimulus> sequence = const [];
  List<TrainingEvent> lastImmediate = [];
  List<TrainingEvent> lastDelayed = [];

  void newRun(ProtocolConfig c) {
    sessionId = newTrainingSessionId();
    config = c;
    sequence = generateStimulusSequence(c);
  }

  List<TrainingEvent> buildRecallEvents({
    required String phase,
    required String userInput,
    required int totalLatencyMs,
    required double confidence,
  }) {
    final c = config;
    if (c == null) return [];
    final n = sequence.length;
    if (n == 0) return [];
    final per = (totalLatencyMs / n).round().clamp(1, 1 << 20);
    final isDig = c.modality == ProtocolConfig.modalityDigits;
    final slots = isDig
        ? InputParser.parseDigitsInput(userInput, sequence)
        : InputParser.parseCardsInput(userInput, sequence);
    final t = DateTime.now().toUtc();
    return [
      for (final s in slots)
        TrainingEvent(
          sessionId: sessionId,
          t: t,
          phase: phase,
          modality: c.modality,
          stimulusId: s.expected,
          stimulusPosition: s.position,
          userInput: s.user,
          latencyMs: per,
          confidence: confidence,
          errorType: s.errorType,
        ),
    ];
  }

  List<TrainingEvent> buildEncodeEvents() {
    final c = config;
    if (c == null) return [];
    final t = DateTime.now().toUtc();
    return [
      for (final s in sequence)
        TrainingEvent(
          sessionId: sessionId,
          t: t,
          phase: 'encode',
          modality: c.modality,
          stimulusId: s.id,
          stimulusPosition: s.position,
        ),
    ];
  }
}
