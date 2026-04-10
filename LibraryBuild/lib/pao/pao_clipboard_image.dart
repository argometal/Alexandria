import 'dart:async';
import 'dart:typed_data';

import 'package:super_clipboard/super_clipboard.dart';

/// Lee el primer bitmap del portapapeles del sistema (misma lógica que el locus editor).
Future<({Uint8List bytes, String ext})?> readFirstImageFromSystemClipboard() async {
  final clipboard = SystemClipboard.instance;
  if (clipboard == null) return null;
  try {
    final reader = await clipboard.read();
    const formats = [
      Formats.png,
      Formats.jpeg,
      Formats.webp,
      Formats.gif,
      Formats.bmp,
      Formats.tiff,
    ];
    for (final fmt in formats) {
      if (!reader.canProvide(fmt)) continue;
      final bytes = await _readDataReaderFile(reader, fmt);
      if (bytes != null && bytes.isNotEmpty) {
        return (bytes: bytes, ext: _extForFormat(fmt));
      }
    }
  } catch (_) {}
  return null;
}

Future<Uint8List?> _readDataReaderFile(DataReader reader, FileFormat format) async {
  final c = Completer<Uint8List?>();
  final progress = reader.getFile(
    format,
    (file) async {
      try {
        final all = await file.readAll();
        if (!c.isCompleted) c.complete(all);
      } catch (_) {
        if (!c.isCompleted) c.complete(null);
      }
    },
    onError: (_) {
      if (!c.isCompleted) c.complete(null);
    },
  );
  if (progress == null && !c.isCompleted) c.complete(null);
  return c.future;
}

String _extForFormat(FileFormat fmt) {
  if (fmt == Formats.png) return 'png';
  if (fmt == Formats.jpeg) return 'jpg';
  if (fmt == Formats.webp) return 'webp';
  if (fmt == Formats.gif) return 'gif';
  if (fmt == Formats.bmp) return 'bmp';
  if (fmt == Formats.tiff) return 'tiff';
  return 'png';
}
