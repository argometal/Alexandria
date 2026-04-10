import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sqlite3/sqlite3.dart' hide Row;

import 'alexandria_paths.dart';
import 'library_build.dart';

double? _asDouble(Object? v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString());
}

int? _asInt(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.round();
  return int.tryParse(v.toString());
}

/// Formato homogéneo: siempre 2 decimales (recall, estabilidad días, fuerza M, último %).
String _fmtMetric2(Object? v) {
  final d = _asDouble(v);
  if (d == null) return '—';
  return d.toStringAsFixed(2);
}

String _fmtIntCell(Object? v) {
  final i = _asInt(v);
  if (i == null) return '—';
  return '$i';
}

String _fmtNextDue(Object? v) {
  final s = v?.toString().trim() ?? '';
  if (s.isEmpty) return '—';
  final dt = DateTime.tryParse(s);
  if (dt == null) {
    return s.length > 19 ? s.substring(0, 19) : s;
  }
  final l = dt.toLocal();
  final y = l.year.toString().padLeft(4, '0');
  final mo = l.month.toString().padLeft(2, '0');
  final d = l.day.toString().padLeft(2, '0');
  final h = l.hour.toString().padLeft(2, '0');
  final mi = l.minute.toString().padLeft(2, '0');
  return '$y-$mo-$d $h:$mi';
}

/// Tabla de recall / scheduling por objeto + export CSV (realm activo).
class MetricsRecallPage extends StatefulWidget {
  const MetricsRecallPage({super.key, required this.db});

  final Database db;

  @override
  State<MetricsRecallPage> createState() => _MetricsRecallPageState();
}

class _MetricsRecallPageState extends State<MetricsRecallPage> {
  List<Map<String, Object?>>? _rows;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    try {
      ensureLibrarySchema(widget.db);
      final r = widget.db.select('''
        SELECT
          e.key AS key,
          e.title AS title,
          e.parentKey AS parentKey,
          e.recall_score AS recall_score,
          e.memory_strength AS memory_strength,
          e.stability_days AS stability_days,
          e.review_count AS review_count,
          COALESCE(s.fib_index, 0) AS fib_index,
          s.next_due_at AS next_due_at,
          s.last_session_pct AS last_session_pct
        FROM entries e
        LEFT JOIN locus_review_state s ON s.entry_key = e.key
        WHERE e.cognitiveRole = 'object'
        ORDER BY e.parentKey ASC, e.seq ASC, e.key ASC
      ''');
      setState(() {
        _rows = r;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _rows = null;
      });
    }
  }

  Future<void> _exportCsv(BuildContext context) async {
    final rows = _rows;
    if (rows == null || rows.isEmpty) return;

    final buf = StringBuffer();
    buf.writeln(
      'key,title,parentKey,recall_score,stability_days,memory_strength,review_count,fib_index,next_due_at,last_session_pct',
    );
    for (final row in rows) {
      String esc(Object? v) {
        final s = v?.toString() ?? '';
        if (s.contains(',') || s.contains('"') || s.contains('\n')) {
          return '"${s.replaceAll('"', '""')}"';
        }
        return s;
      }

      buf.writeln([
        esc(row['key']),
        esc(row['title']),
        esc(row['parentKey']),
        esc(_fmtMetric2(row['recall_score'])),
        esc(_fmtMetric2(row['stability_days'])),
        esc(_fmtMetric2(row['memory_strength'])),
        esc(_fmtIntCell(row['review_count'])),
        esc(_fmtIntCell(row['fib_index'])),
        esc(_fmtNextDue(row['next_due_at'])),
        esc(_fmtMetric2(row['last_session_pct'])),
      ].join(','));
    }

    final path =
        '${AlexandriaPaths.realmDataRoot()}/export_recall_metrics.csv';
    final f = File(path);
    f.parent.createSync(recursive: true);
    f.writeAsStringSync(buf.toString(), encoding: utf8);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('CSV guardado: $path')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Recall metrics')),
        body: Center(child: Text(_error!)),
      );
    }

    final rows = _rows;
    if (rows == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Recall metrics · ${rows.length} objects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Export CSV',
            onPressed: rows.isEmpty ? null : () => _exportCsv(context),
          ),
        ],
      ),
      body: rows.isEmpty
          ? const Center(child: Text('No object entries in this realm.'))
          : LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      columnSpacing: 16,
                      columns: const [
                        DataColumn(label: Text('Key')),
                        DataColumn(label: Text('Title')),
                        DataColumn(label: Text('Parent')),
                        DataColumn(
                          numeric: true,
                          label: Text('Recall'),
                        ),
                        DataColumn(
                          numeric: true,
                          label: Text('S days'),
                        ),
                        DataColumn(
                          numeric: true,
                          label: Text('M'),
                        ),
                        DataColumn(
                          numeric: true,
                          label: Text('R#'),
                        ),
                        DataColumn(
                          numeric: true,
                          label: Text('Fib'),
                        ),
                        DataColumn(label: Text('Next due')),
                        DataColumn(
                          numeric: true,
                          label: Text('Last %'),
                        ),
                      ],
                      rows: [
                        for (final row in rows)
                          DataRow(
                            cells: [
                              DataCell(Text(
                                row['key']?.toString() ?? '',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                ),
                              )),
                              DataCell(Text(
                                (row['title']?.toString() ?? '').trim().isEmpty
                                    ? '—'
                                    : row['title'].toString(),
                              )),
                              DataCell(Text(row['parentKey']?.toString() ?? '')),
                              DataCell(
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(_fmtMetric2(row['recall_score'])),
                                ),
                              ),
                              DataCell(
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(_fmtMetric2(row['stability_days'])),
                                ),
                              ),
                              DataCell(
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(_fmtMetric2(row['memory_strength'])),
                                ),
                              ),
                              DataCell(
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(_fmtIntCell(row['review_count'])),
                                ),
                              ),
                              DataCell(
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(_fmtIntCell(row['fib_index'])),
                                ),
                              ),
                              DataCell(Text(_fmtNextDue(row['next_due_at']))),
                              DataCell(
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(_fmtMetric2(row['last_session_pct'])),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
