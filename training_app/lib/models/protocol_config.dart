/// "cards" | "digits" — tercer motor, sin LibraryBuild.
class ProtocolConfig {
  const ProtocolConfig({
    required this.modality,
    this.chunkSize = 2,
    this.sequenceLength = 10,
    this.targetSpeedSec = 2.0,
    required this.sessionNumber,
  });

  final String modality; // "cards" | "digits"
  final int chunkSize; // 2 (inicial); 3 = avanzado (no implementado aún)
  final int sequenceLength; // chunks por sesión
  final double targetSpeedSec; // s por estímulo (encode)
  final int sessionNumber; // 1,2,3… (tracking manual)

  static const String modalityCards = 'cards';
  static const String modalityDigits = 'digits';
}
