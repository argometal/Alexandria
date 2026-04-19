import 'go_engine.dart';

/// Definición de un problema 9×9 (una jugada objetivo; respuestas alternativas opcionales).
///
/// El **catálogo integrado** vive aquí para no mezclar con el motor. Futuros packs
/// pueden cargarse por JSON/asset aparte sin tocar [GoBoard].
class GoProblem {
  const GoProblem({
    required this.id,
    required this.titleL10nKey,
    required this.hintL10nKey,
    required this.cells,
    required this.toPlay,
    required this.solution,
    this.alsoValid = const [],
  });

  final String id;

  /// Clave en AppLocalizations (ej. `goProblemCapTitle`).
  final String titleL10nKey;

  final String hintL10nKey;

  /// 81 celdas: [Stone.empty.code], negras, blancas.
  final List<int> cells;

  final int toPlay;
  final int solution;
  final List<int> alsoValid;

  bool accepts(int moveIndex) =>
      moveIndex == solution || alsoValid.contains(moveIndex);

  GoBoard initialBoard() => GoBoard.problemStart(
        initialCells: cells,
        toPlay: toPlay,
      );
}

/// Catálogo mínimo embebido (unos pocos KB). Packs grandes → assets aparte.
final List<GoProblem> kGoBuiltinProblems = [
  // Captura en atari: blanca rodeada salvo un punto; negras juegan ahí.
  // W(4,4), B en (3,4),(4,3),(5,4); libertad en (4,5) → índice 41.
  GoProblem(
    id: 'cap_atari_01',
    titleL10nKey: 'goProblemCapTitle',
    hintL10nKey: 'goProblemCapHint',
    cells: () {
      final g = List<int>.filled(81, 0);
      g[31] = Stone.black.code;
      g[39] = Stone.black.code;
      g[40] = Stone.white.code;
      g[49] = Stone.black.code;
      return g;
    }(),
    toPlay: Stone.black.code,
    solution: 41,
  ),
  // Conectar dos piedras negras horizontales.
  GoProblem(
    id: 'connect_01',
    titleL10nKey: 'goProblemConnectTitle',
    hintL10nKey: 'goProblemConnectHint',
    cells: () {
      final g = List<int>.filled(81, 0);
      g[40] = Stone.black.code;
      g[42] = Stone.black.code;
      return g;
    }(),
    toPlay: Stone.black.code,
    solution: 41,
  ),
  // Conectar verticalmente dos piedras negras.
  GoProblem(
    id: 'bridge_01',
    titleL10nKey: 'goProblemBridgeTitle',
    hintL10nKey: 'goProblemBridgeHint',
    cells: () {
      final g = List<int>.filled(81, 0);
      g[31] = Stone.black.code;
      g[49] = Stone.black.code;
      return g;
    }(),
    toPlay: Stone.black.code,
    solution: 40,
  ),
];
