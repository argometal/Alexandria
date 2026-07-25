/// Cómo valoraste el intento de recall (fijo, no porcentaje).
const String kSelfReportGood = 'good';
const String kSelfReportHard = 'hard';
const String kSelfReportFail = 'fail';

const List<String> kSelfReportValues = [
  kSelfReportGood,
  kSelfReportHard,
  kSelfReportFail,
];

String selfReportLabelEs(String code) {
  switch (code) {
    case kSelfReportGood:
      return 'Bien';
    case kSelfReportHard:
      return 'Difícil';
    case kSelfReportFail:
      return 'Fallo';
    default:
      return code;
  }
}
