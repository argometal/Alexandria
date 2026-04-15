import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:sqlite3/sqlite3.dart' hide Row;

import '../library_build.dart';
import 'match_cards_store.dart';

const _kBundleFormat = 'alexandria_lb_match_cards';
const _kBundleVersion = 1;

/// Lee `deckName` del `manifest.json` dentro del zip (sin importar).
Future<String?> lbPeekMatchCardsBundleDeckName(String zipAbsolutePath) async {
  final bytes = await File(zipAbsolutePath).readAsBytes();
  final archive = ZipDecoder().decodeBytes(bytes);
  ArchiveFile? manifestFile;
  for (final f in archive) {
    if (!f.isFile) continue;
    var name = f.name.replaceAll(r'\', '/');
    if (name.startsWith('./')) name = name.substring(2);
    if (name == 'manifest.json') {
      manifestFile = f;
      break;
    }
  }
  if (manifestFile == null) return null;
  final raw = manifestFile.content;
  final text = utf8.decode(
    raw is Uint8List ? raw : Uint8List.fromList(List<int>.from(raw as List)),
  );
  final decoded = jsonDecode(text);
  if (decoded is! Map) return null;
  final n = decoded['deckName']?.toString().trim();
  if (n == null || n.isEmpty) return null;
  return n;
}

/// Exporta un mazo (solo `route_key` NULL) a un `.zip` con `manifest.json` + `images/*`.
Future<void> lbExportDeckToZipFile({
  required Database db,
  required int deckId,
  required String zipAbsolutePath,
}) async {
  ensureLibrarySchema(db);
  final deck = db.select('SELECT name FROM lb_match_decks WHERE id = ?', [deckId]);
  if (deck.isEmpty) throw StateError('deck not found');
  final deckName = deck.first['name']! as String;
  final rows = db.select(
    'SELECT image_basename, caption_text, transliteration, gloss '
    'FROM lb_match_pairs WHERE route_key IS NULL AND deck_id = ? ORDER BY id ASC',
    [deckId],
  );
  final pairEntries = <Map<String, Object?>>[];
  final encoder = ZipFileEncoder();
  encoder.create(zipAbsolutePath);
  try {
    var i = 0;
    for (final r in rows) {
      final base = r['image_basename']! as String;
      final cap = r['caption_text']! as String;
      final tr = r['transliteration'] as String?;
      final gl = r['gloss'] as String?;
      final path = '${lbMatchCardsAssetsDir()}${Platform.pathSeparator}$base';
      final f = File(path);
      if (!f.existsSync()) continue;
      final ext = _safeExt(base);
      final arcName = 'images/${i.toString().padLeft(5, '0')}$ext';
      pairEntries.add({
        'caption_text': cap,
        'transliteration': tr,
        'gloss': gl,
        'image': arcName,
      });
      await encoder.addFile(f, arcName, ZipFileEncoder.STORE);
      i++;
    }
    final manifest = <String, Object?>{
      'format': _kBundleFormat,
      'version': _kBundleVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'deckName': deckName,
      'pairs': pairEntries,
    };
    final jsonBytes = utf8.encode(const JsonEncoder.withIndent('  ').convert(manifest));
    encoder.addArchiveFile(
      ArchiveFile('manifest.json', jsonBytes.length, jsonBytes),
    );
  } finally {
    encoder.closeSync();
  }
}

String _safeExt(String basename) {
  final d = basename.lastIndexOf('.');
  if (d < 0 || d >= basename.length - 1) return '.png';
  final e = basename.substring(d).toLowerCase();
  const ok = {'.png', '.jpg', '.jpeg', '.webp', '.gif', '.bmp', '.tif', '.tiff'};
  return ok.contains(e) ? e : '.png';
}

/// Importa pares desde un `.zip` al [deckId] indicado.
/// Devuelve el número de pares insertados.
Future<int> lbImportDeckFromZipFile({
  required Database db,
  required int deckId,
  required String zipAbsolutePath,
}) async {
  ensureLibrarySchema(db);
  final deckCheck = db.select('SELECT id FROM lb_match_decks WHERE id = ?', [deckId]);
  if (deckCheck.isEmpty) throw StateError('deck not found');
  final bytes = await File(zipAbsolutePath).readAsBytes();
  final archive = ZipDecoder().decodeBytes(bytes);
  ArchiveFile? manifestFile;
  final imageFiles = <String, ArchiveFile>{};
  for (final f in archive) {
    if (!f.isFile) continue;
    var name = f.name.replaceAll(r'\', '/');
    if (name.startsWith('./')) name = name.substring(2);
    if (name == 'manifest.json') {
      manifestFile = f;
    } else {
      imageFiles[name] = f;
    }
  }
  if (manifestFile == null) {
    throw const FormatException('ZIP missing manifest.json');
  }
  final raw = manifestFile.content;
  final text = utf8.decode(
    raw is Uint8List ? raw : Uint8List.fromList(List<int>.from(raw as List)),
  );
  final decoded = jsonDecode(text);
  if (decoded is! Map) throw const FormatException('manifest invalid');
  final format = decoded['format']?.toString();
  if (format != _kBundleFormat) {
    throw FormatException('unknown bundle format: $format');
  }
  final pairs = decoded['pairs'];
  if (pairs is! List) throw const FormatException('manifest pairs missing');
  ensureLbMatchCardsDirExists();
  var n = 0;
  for (final p in pairs) {
    if (p is! Map) continue;
    final cap = p['caption_text']?.toString().trim() ?? '';
    if (cap.isEmpty) continue;
    final tr = p['transliteration']?.toString().trim();
    final gl = p['gloss']?.toString().trim();
    final imgRef = p['image']?.toString().trim() ?? '';
    if (imgRef.isEmpty) continue;
    var key = imgRef.replaceAll(r'\', '/');
    if (key.startsWith('./')) key = key.substring(2);
    var af = imageFiles[key];
    af ??= _findImageByBasename(imageFiles, key);
    if (af == null) continue;
    final content = af.content;
    final imgBytes = content is Uint8List
        ? content
        : Uint8List.fromList(List<int>.from(content as List));
    if (imgBytes.isEmpty) continue;
    final ext = _extFromName(key);
    lbInsertMatchPairFromBytes(
      db,
      bytes: imgBytes,
      extensionNoDot: ext,
      captionText: cap,
      transliteration: tr != null && tr.isEmpty ? null : tr,
      gloss: gl != null && gl.isEmpty ? null : gl,
      deckId: deckId,
    );
    n++;
  }
  return n;
}

ArchiveFile? _findImageByBasename(Map<String, ArchiveFile> imageFiles, String key) {
  final leaf = key.contains('/') ? key.substring(key.lastIndexOf('/') + 1) : key;
  for (final e in imageFiles.entries) {
    if (e.key.endsWith(leaf)) return e.value;
  }
  return null;
}

String _extFromName(String path) {
  final leaf = path.contains('/') ? path.substring(path.lastIndexOf('/') + 1) : path;
  final d = leaf.lastIndexOf('.');
  if (d < 0 || d >= leaf.length - 1) return 'png';
  return leaf.substring(d + 1).toLowerCase();
}
