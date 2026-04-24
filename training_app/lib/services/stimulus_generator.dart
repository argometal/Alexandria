import 'dart:math' as math;

import '../models/protocol_config.dart';
import '../models/stimulus.dart';

/// Rango cartas: A 2-9 T J Q K + palo S H D C (una letra c/u).
const String _kRanks = 'A23456789TJQK';
const String _kSuits = 'SHDC';

String _cardCode(int rankIndex, int suitIndex) {
  return '${_kRanks[rankIndex]}${_kSuits[suitIndex]}';
}

/// Pares (rank,suit) únicos, sin repetición en toda la sesión.
List<Stimulus> generateStimulusSequence(ProtocolConfig config) {
  final n = config.sequenceLength;
  final c = config.chunkSize;
  if (c != 2) {
    throw UnimplementedError('Solo chunkSize=2 en v1');
  }
  if (config.modality == ProtocolConfig.modalityCards) {
    return _genCards(n, c);
  }
  if (config.modality == ProtocolConfig.modalityDigits) {
    return _genDigits(n, c);
  }
  throw ArgumentError('modality: ${config.modality}');
}

List<Stimulus> _genCards(int sequenceLength, int chunkSize) {
  final need = sequenceLength * chunkSize;
  if (need > 52) {
    throw ArgumentError('Máx 26 pares (52 cartas), reduce sequenceLength o chunkSize');
  }
  final pool = <String>[];
  for (var r = 0; r < _kRanks.length; r++) {
    for (var s = 0; s < _kSuits.length; s++) {
      pool.add(_cardCode(r, s));
    }
  }
  pool.shuffle(math.Random());
  final out = <Stimulus>[];
  for (var i = 0; i < sequenceLength; i++) {
    final a = pool.removeLast();
    final b = pool.removeLast();
    final id = '$a-$b';
    out.add(Stimulus(id: id, position: i));
  }
  return out;
}

List<Stimulus> _genDigits(int sequenceLength, int chunkSize) {
  if (chunkSize != 2) {
    throw UnimplementedError('Dígitos: solo v1 con chunkSize=2 (reservado).');
  }
  if (sequenceLength > 100) {
    throw ArgumentError('Máx 100 valores 00-99 sin repetir');
  }
  final all = List.generate(100, (i) => i.toString().padLeft(2, '0'));
  all.shuffle(math.Random());
  return [
    for (var i = 0; i < sequenceLength; i++)
      Stimulus(id: all.removeLast(), position: i),
  ];
}
