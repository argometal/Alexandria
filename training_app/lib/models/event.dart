class TrainingEvent {
  const TrainingEvent({
    required this.sessionId,
    required this.t,
    required this.phase,
    required this.modality,
    required this.stimulusId,
    required this.stimulusPosition,
    this.userInput,
    this.latencyMs,
    this.confidence,
    this.errorType,
    this.context = const {},
  });

  final String sessionId;
  final DateTime t;
  final String phase; // encode | recall_immediate | recall_delayed
  final String modality;
  final String stimulusId;
  final int stimulusPosition;
  final String? userInput;
  final int? latencyMs;
  final double? confidence;
  final String? errorType;
  final Map<String, dynamic> context;

  Map<String, dynamic> toJson() => {
        'session_id': sessionId,
        't': t.toUtc().toIso8601String(),
        'phase': phase,
        'modality': modality,
        'stimulus_id': stimulusId,
        'stimulus_position': stimulusPosition,
        'user_input': userInput,
        'latency_ms': latencyMs,
        'confidence': confidence,
        'error_type': errorType,
        'context': context,
      };
}
