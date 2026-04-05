import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
// [CHANGE 104] Removed path_provider import. Runtime root now fixed to C:\Alexandria\data.
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:file_selector/file_selector.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final runtime = await _initRuntime();

  // ---- RAZ13 bridge watcher ----
  final bridge = Directory(p.join(runtime.rootPath, 'bridge'));
  if (!bridge.existsSync()) {
    bridge.createSync(recursive: true);
  }


 Future<void> _handleBridgeOpenKey(RuntimeContext runtime, String bridgePath) async {
  final f = File(p.join(bridgePath, 'open_key.txt'));
  if (!f.existsSync()) return;

  final key = f.readAsStringSync().trim();
  f.deleteSync();

  if (key.isEmpty) return;

  print("BRIDGE_OPEN_KEY: $key");

  final rows = await runtime.db.query(
    'entries',
    where: 'key = ?',
    whereArgs: [key],
    limit: 1,
  );

if (rows.isEmpty) {
  final slotMatch = RegExp(r'^(.*)__SLOT_(\d+)$').firstMatch(key);

  if (slotMatch == null) {
    // [SCOPE:BRIDGE_MISSING_SLOT] key faltante que no es slot
    print("BRIDGE_OPEN_KEY_MISSING: $key");
    return;
  }

  final parentKey = slotMatch.group(1)!;
  final seq = int.tryParse(slotMatch.group(2)!) ?? 0;

  final parentRows = await runtime.db.query(
    'entries',
    where: 'key = ?',
    whereArgs: [parentKey],
    limit: 1,
  );

  if (parentRows.isEmpty) {
    print("BRIDGE_OPEN_KEY_PARENT_MISSING: $parentKey");
    return;
  }

  final now = DateTime.now().toIso8601String();

  // [SCOPE:BRIDGE_MATERIALIZE_SLOT] materializa la row exacta del slot recibido
  await runtime.db.insert('entries', {
    'key': key,
    'title': 'Seed ${seq.toString().padLeft(2, '0')}',
    'layer': 'seed',
    'entryType': 'seed',
    'capacity': 20,
    'parentKey': parentKey,
    'seq': seq,
    'body_text': jsonEncode([
      {'t': 'p', 'text': ''}
    ]),
    'createdAt': now,
    'updatedAt': now,
    'version': 1,
  });

  print("BRIDGE_OPEN_KEY_MATERIALIZED: $key parent=$parentKey seq=$seq");
}

/*   if (rows.isEmpty) {
    // [SCOPE:BRIDGE_MISSING_SLOT] bridge no materializa; solo abre keys existentes
    print("BRIDGE_OPEN_KEY_MISSING: $key");
    return;
  } */

  final activeFile = File(p.join(bridgePath, 'active_key.txt'));
  activeFile.writeAsStringSync(key);

  if (key != runtime.entryKey) {
    print("BRIDGE_OPEN_KEY_APPLIED: from=${runtime.entryKey} to=$key");
    runtime.entryKey = key;
    await runtime.onOpenKey?.call();
  }
}
  
  var _bridgeBusy = false;

  Timer.periodic(const Duration(milliseconds: 350), (t) async {
    if (_bridgeBusy) return;
    _bridgeBusy = true;
    try {
      await _handleBridgeOpenKey(runtime, bridge.path);
    } finally {
      _bridgeBusy = false;
    }
  });
  // ---- end bridge ----

  runApp(MyApp(runtime));
}

Future<RuntimeContext> _initRuntime() async {
  // =m09

  // NEW ROOT: C:\Alexandria\data
  final root = Directory(r'C:\Alexandria\data');

  final assetsDir = Directory(p.join(root.path, 'assets'));
  final dbFile = File(p.join(root.path, 'alexandria.db'));

/*   // Old location (migration source)
  final oldSupportDir = await getApplicationSupportDirectory();
  final oldRoot = Directory(p.join(oldSupportDir.path, 'Alexandria'));
  final oldDbFile = File(p.join(oldRoot.path, 'alexandria.db'));
  final oldAssetsDir = Directory(p.join(oldRoot.path, 'assets')); */

  if (!root.existsSync()) root.createSync(recursive: true);
  if (!assetsDir.existsSync()) assetsDir.createSync(recursive: true);

  // [CHANGE 99] Removed accidental C# block from Dart runtime init.
  // main.dart must only contain Flutter/Dart runtime setup here.

  // ==m09

  if (!root.existsSync()) root.createSync(recursive: true);
  if (!assetsDir.existsSync()) assetsDir.createSync(recursive: true);

  final db = await databaseFactory.openDatabase(dbFile.path);

  await db.execute('''
    CREATE TABLE IF NOT EXISTS entries (
      key TEXT PRIMARY KEY,
      createdAt TEXT,
      updatedAt TEXT
    );
  ''');

  // ---- base table ----
  await db.execute('''
    CREATE TABLE IF NOT EXISTS entries (
      key TEXT PRIMARY KEY,
      createdAt TEXT,
      updatedAt TEXT
    );
  ''');

  // ---- RAZ10 / RAZ12 migrations (idempotent) ----
  await db.execute('ALTER TABLE entries ADD COLUMN title TEXT;').catchError((_) {});
  await db.execute('ALTER TABLE entries ADD COLUMN layer TEXT;').catchError((_) {});
  await db.execute('ALTER TABLE entries ADD COLUMN parentKey TEXT;').catchError((_) {});
  await db.execute('ALTER TABLE entries ADD COLUMN seq INTEGER;').catchError((_) {});
  await db.execute('ALTER TABLE entries ADD COLUMN body_text TEXT;').catchError((_) {});

  await db.execute('ALTER TABLE entries ADD COLUMN entryType TEXT;').catchError((_) {});
  await db.execute('ALTER TABLE entries ADD COLUMN entryState TEXT NOT NULL DEFAULT "active";').catchError((_) {});
  await db.execute('ALTER TABLE entries ADD COLUMN capacity INTEGER;').catchError((_) {});
  await db.execute('ALTER TABLE entries ADD COLUMN version INTEGER NOT NULL DEFAULT 1;').catchError((_) {});
  // ---- end migrations ----

  await db.execute('''
      CREATE TABLE IF NOT EXISTS assets (
        assetKey TEXT PRIMARY KEY,
        entryKey TEXT NOT NULL,
        fileName TEXT NOT NULL,
        mime TEXT NOT NULL DEFAULT '',
        role TEXT NOT NULL DEFAULT '',
        createdAt TEXT NOT NULL
      );
    ''');

  await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_assets_entry ON assets(entryKey);');
  await db.execute("ALTER TABLE assets ADD COLUMN role TEXT NOT NULL DEFAULT '';")
      .catchError((_) {});

  const parcourKey = 'PARCOUR_MAIN';

  final existingParcour = await db.query(
    'entries',
    where: 'key = ?',
    whereArgs: [parcourKey],
  );

  if (existingParcour.isEmpty) {
    final now = DateTime.now().toIso8601String();
      await db.insert('entries', {
        'key': parcourKey,
        'layer': 'parcour',
        'entryType': 'parcour',
        'entryState': 'active',
        'capacity': 20,
        'parentKey': null,
        'seq': 0,
        'body_text': jsonEncode([
          {'t': 'p', 'text': ''}
      ]),
      'createdAt': now,
      'updatedAt': now,
    });
  }

  // ---- seed 10 to 20 loci for PARCOUR_MAIN (conservative: insert only if missing) ----
   for (var i = 1; i <= 20; i++) {

    final key = 'KEY_FRAME_${i.toString().padLeft(2, '0')}';
    final row = await db.query('entries', where: 'key = ?', whereArgs: [key]);

    if (row.isEmpty) {
      final now = DateTime.now().toIso8601String();
      await db.insert('entries', {
        'key': key,
        'layer': 'locus',
        'entryType': 'locus',
        'entryState': 'active',
        'capacity': 20,
        'parentKey': 'PARCOUR_MAIN',
        'seq': i,
        'body_text': jsonEncode([
          {'t': 'p', 'text': ''}
        ]),
        'createdAt': now,
        'updatedAt': now,
      });
    }
  }



// ---- end seed ----

  // =0611

  return RuntimeContext(
    db: db,
    rootPath: root.path,
    assetsPath: assetsDir.path,
    entryKey: 'KEY_FRAME_01',
  );

}

class RuntimeContext {
  final Database db;
  final String rootPath;
  final String assetsPath;
  String entryKey;

  Future<void> Function()? onOpenKey;

  RuntimeContext({
    required this.db,
    required this.rootPath,
    required this.assetsPath,
    required this.entryKey,
  });
}

Future<List<Map<String, Object?>>> getChildren(Database db, String parentKey) async {
  if (parentKey.trim().isEmpty) return [];

  return db.query(
    'entries',
    where: 'parentKey = ?',
    whereArgs: [parentKey.trim()],
    orderBy: 'seq ASC, createdAt ASC',
  );
}

Future<int> getChildrenCount(Database db, String parentKey) async {
  if (parentKey.trim().isEmpty) return 0;

  final row = await db.rawQuery(
    'SELECT COUNT(*) AS c FROM entries WHERE parentKey = ?',
    [parentKey.trim()],
  );

  final value = row.isEmpty ? 0 : (row.first['c'] as int? ?? 0);
  return value;
}

Future<int> getNextSeq(Database db, String parentKey) async {
  if (parentKey.trim().isEmpty) return 1;

  final row = await db.rawQuery(
    'SELECT COALESCE(MAX(seq), 0) AS m FROM entries WHERE parentKey = ?',
    [parentKey.trim()],
  );

  final maxSeq = row.isEmpty ? 0 : (row.first['m'] as int? ?? 0);
  return maxSeq + 1;
}

Future<void> recompactChildren(Database db, String parentKey) async {
  if (parentKey.trim().isEmpty) return;

  final rows = await db.query(
    'entries',
    columns: ['key', 'seq', 'createdAt'],
    where: 'parentKey = ?',
    whereArgs: [parentKey.trim()],
    orderBy: 'seq ASC, createdAt ASC',
  );

  final batch = db.batch();

  for (var i = 0; i < rows.length; i++) {
    batch.update(
      'entries',
      {
        'seq': i + 1,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'key = ?',
      whereArgs: [rows[i]['key']],
    );
  }

  await batch.commit(noResult: true);
}

Future<void> deleteChildEntry(
  Database db,
  String childKey,
  String assetsPath,
) async {

  final rows = await db.query(
    'entries',
    columns: ['parentKey', 'seq'],
    where: 'key = ?',
    whereArgs: [childKey.trim()],
    limit: 1,
  );

  if (rows.isEmpty) return;

  final parentKey = (rows.first['parentKey'] ?? '').toString().trim();
  final seq = (rows.first['seq'] as int?) ?? 0;

  final assetRows = await db.query(
    'assets',
    columns: ['fileName'],
    where: 'entryKey = ?',
    whereArgs: [childKey.trim()],
  );

  for (final a in assetRows) {
    final fileName = (a['fileName'] ?? '').toString();
    if (fileName.isEmpty) continue;

    final f = File(p.join(assetsPath, childKey.trim(), fileName));
    if (f.existsSync()) {
      try {
        await f.delete();
      } catch (_) {}
    }
  }

  final dir = Directory(p.join(assetsPath, childKey.trim()));
  if (dir.existsSync()) {
    try {
      await dir.delete(recursive: true);
    } catch (_) {}
  }

  await db.delete(
    'assets',
    where: 'entryKey = ?',
    whereArgs: [childKey.trim()],
  );

  final originalRows = await db.query(
    'entries',
    columns: ['entryType'],
    where: 'key = ?',
    whereArgs: [childKey.trim()],
    limit: 1,
  );

  final originalType = originalRows.isEmpty
      ? ''
      : (originalRows.first['entryType']?.toString() ?? '').trim();

  await db.update(
    'entries',
    {
      'title': 'Seed ${seq.toString().padLeft(2, '0')}',
      'layer': 'seed',
      'body_text': '[{"t":"p","text":""}]',
      'entryType': originalType,
      'entryState': 'seed',
      'capacity': 0,
      'updatedAt': DateTime.now().toIso8601String(),
      'version': 1,
    },
    where: 'key = ?',
    whereArgs: [childKey.trim()],
  );

}
// 269-B
Future<Map<String, Object?>?> createChildEntry(
  Database db,
  String parentKey,
  String assetsPath, {
  List<Map<String, dynamic>>? sourceBlocks,
}) async {
  final parentRows = await db.query(
    'entries',
    where: 'key = ?',
    whereArgs: [parentKey],
    limit: 1,
  );

  if (parentRows.isEmpty) return null;

  final parent = parentRows.first;
  final parentType = (parent['entryType']?.toString() ?? '').trim();
  final parentCapacity = (parent['capacity'] as int?) ?? 0;
  final parentBodyText = (parent['body_text']?.toString() ?? '').trim();

  final childrenCount = await getChildrenCount(db, parentKey);
  if (parentCapacity > 0 && childrenCount >= parentCapacity) {
    return null;
  }

  String childType = 'object';
  int childCapacity = 0;

  if (parentType == 'parcour') {
    childType = 'locus';
    childCapacity = 10;
  } else if (parentType == 'locus') {
    childType = 'object';
    childCapacity = 10;
  }

  final nextSeq = await getNextSeq(db, parentKey);
  final now = DateTime.now().toIso8601String();

  final reusableRows = await db.query(
    'entries',
    where: 'parentKey = ? AND seq = ?',
    whereArgs: [parentKey, nextSeq],
    limit: 1,
  );

  final bool reusingExistingRow = reusableRows.isNotEmpty;
  final String childKey = reusingExistingRow
      ? (reusableRows.first['key']?.toString() ?? '')
      : 'KEY_${DateTime.now().microsecondsSinceEpoch}_${nextSeq.toString().padLeft(2, '0')}';

  if (childKey.trim().isEmpty) return null;

  final inheritedBodyText =
      (sourceBlocks != null && sourceBlocks.isNotEmpty)
          ? jsonEncode(sourceBlocks)
          : (parentBodyText.isNotEmpty
              ? parentBodyText
              : jsonEncode([
                  {'t': 'p', 'text': ''}
                ]));

  List<dynamic> decodedBlocks;
  try {
    decodedBlocks = jsonDecode(inheritedBodyText) as List<dynamic>;
  } catch (_) {
    decodedBlocks = [
      {'t': 'p', 'text': ''}
    ];
  }

  final usedAssetKeys = <String>{};
  for (final b in decodedBlocks) {
    if (b is Map && (b['t'] ?? '').toString() == 'img' && b['assetKey'] != null) {
      usedAssetKeys.add(b['assetKey'].toString());
    }
  }

  final parentAssets = await db.query(
    'assets',
    where: 'entryKey = ?',
    whereArgs: [parentKey],
  );

  final filteredAssets = parentAssets
      .where((a) => usedAssetKeys.contains((a['assetKey'] ?? '').toString()))
      .toList();

  final Map<String, String> assetKeyMap = {};

  for (final a in filteredAssets) {
    final oldAssetKey = (a['assetKey'] ?? '').toString();
    final fileName = (a['fileName'] ?? '').toString();
    if (oldAssetKey.isEmpty || fileName.isEmpty) continue;

    final src = p.join(assetsPath, parentKey, fileName);
    final dst = p.join(assetsPath, childKey, fileName);

    final srcFile = File(src);
    if (!srcFile.existsSync()) continue;

    await Directory(p.dirname(dst)).create(recursive: true);
    await srcFile.copy(dst);

    final newAssetKey =
        'AST_${DateTime.now().microsecondsSinceEpoch}_${fileName.hashCode}';

    assetKeyMap[oldAssetKey] = newAssetKey;

    await db.insert('assets', {
      'assetKey': newAssetKey,
      'entryKey': childKey,
      'fileName': fileName,
      'mime': (a['mime'] ?? '').toString(),
      'role': (a['role'] ?? '').toString(),
      'createdAt': now,
    });
  }

  final rewrittenBlocks = decodedBlocks.map((b) {
    if (b is Map) {
      final copy = Map<String, dynamic>.from(b);
      if ((copy['t'] ?? '').toString() == 'img') {
        final oldAssetKey = (copy['assetKey'] ?? '').toString();
        if (assetKeyMap.containsKey(oldAssetKey)) {
          copy['assetKey'] = assetKeyMap[oldAssetKey];
        }
      }
      return copy;
    }
    return b;
  }).toList();

  final row = <String, Object?>{
    'key': childKey,
    'title': 'Child $nextSeq',
    'layer': childType,
    'entryType': childType,
    'entryState': 'active',
    'capacity': childCapacity,
    'parentKey': parentKey,
    'seq': nextSeq,
    'body_text': jsonEncode(rewrittenBlocks),
    'createdAt': reusingExistingRow
        ? (reusableRows.first['createdAt'] ?? now)
        : now,
    'updatedAt': now,
    'version': 1,
  };

  if (reusingExistingRow) {
    await db.update(
      'entries',
      row,
      where: 'key = ?',
      whereArgs: [childKey],
    );
  } else {
    await db.insert('entries', row);
  }

  return row;
}
// =269-B


  // 064Fix
  class MyApp extends StatelessWidget {
    final RuntimeContext runtime;
    const MyApp(this.runtime, {super.key});
    @override
    Widget build(BuildContext context) {

/*          // 999 -Original  brown Style  
       return MaterialApp(
        title: 'Alexandria 12',
        home: EditorTest(runtime),
      ); 
      */
      // 999 -Black -Godot Style
          return MaterialApp(
            title: 'Alexandria 12',
            theme: ThemeData(
              brightness: Brightness.dark,
              scaffoldBackgroundColor: const Color(0xFF111318),
              canvasColor: const Color(0xFF111318),
              primaryColor: const Color(0xFF1E232B),
              cardColor: const Color(0xFFF2F2F2),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF0D0F13),
                elevation: 0,
                foregroundColor: Colors.white70,
              ),
              textTheme: const TextTheme(
                bodyMedium: TextStyle(color: Colors.white70),
                titleMedium: TextStyle(color: Colors.white),
              ),
            ),
            home: EditorTest(runtime),
       // =999 -Black -Godot Style           
);
      

    }
  }
    //== 0641

  /*     @override

  // } */

  class EditorTest extends StatefulWidget {
    final RuntimeContext runtime;

    const EditorTest(this.runtime, {super.key});

    @override
    State<EditorTest> createState() => _EditorTestState();
  }

  // =b07

  class _EditorTestState extends State<EditorTest> {
    final controller = TextEditingController();

    List<Map<String, Object?>> assets = [];
    List<Map<String, Object?>> children = [];
    // =060
    // R12B07: body_text as JSON blocks

    List<Map<String, dynamic>> docBlocks = [];
    int activePIndex = -1; // index of paragraph bound to controller

    // R12-060: block-based paragraph editing
    final Map<int, TextEditingController> _pCtrls = {};
    final Map<int, FocusNode> _pFocus = {};

    int focusedIndex = -1;
    String? focusedAssetKey;
    String _activeEntryKey = '';
    Timer? _bridgeKeyTimer;
    final Set<int> selectedBlockIndexes = <int>{};

    // ==060
    // ==b07

    @override
    void initState() {
      super.initState();
      widget.runtime.onOpenKey = () async {
        await _loadDoc();
        await _loadAssets();
        await _loadChildren();
      };

      _activeEntryKey = widget.runtime.entryKey;

      _loadDoc();
      _loadAssets();
      _loadChildren();

      _bridgeKeyTimer = Timer.periodic(const Duration(milliseconds: 200), (_) async {
        final k = widget.runtime.entryKey;
        if (k != _activeEntryKey && k.trim().isNotEmpty) {
          _activeEntryKey = k;
          await _loadDoc();
          await _loadAssets();
          await _loadChildren();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Open KEY: $k')),
            );
          }
        }
      });
    }
    // ===b02

    Future<void> _loadChildren() async {
      final rows = await getChildren(widget.runtime.db, widget.runtime.entryKey);
      if (!mounted) return;

      setState(() {
        children = rows;
      });
    }

    Future<void> _openEntry(String key) async {
      final nextKey = key.trim();
      if (nextKey.isEmpty) return;

      widget.runtime.entryKey = nextKey;
      _activeEntryKey = nextKey;

      await _loadDoc();
      await _loadAssets();
      await _loadChildren();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Open child: $nextKey')),
        );
      }
    }

    // 
    void _toggleBlockSelection(int index) {
      setState(() {
        if (selectedBlockIndexes.contains(index)) {
          selectedBlockIndexes.remove(index);
        } else {
          selectedBlockIndexes.add(index);
        }
      });
    }
    // =

    Future<void> _loadDoc() async {    

      final rows = await widget.runtime.db.query(
        'entries',
        where: 'key = ?',
        whereArgs: [widget.runtime.entryKey],
      );

      final raw = (rows.isNotEmpty ? (rows.first['body_text'] as String? ?? '') : '');

      // Parse JSON blocks; fallback to single paragraph
      List<Map<String, dynamic>> blocks = [];
      try {
        
        final decoded = raw.trim().startsWith('[') ? jsonDecode(raw) : const <dynamic>[];
        if (decoded is List) {
          blocks = decoded
              .whereType<Map>()
              .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
              .map((m) => <String, dynamic>{
                    't': (m['t'] ?? 'p').toString(),
                    if (m.containsKey('text')) 'text': (m['text'] ?? '').toString(),
                    if (m.containsKey('assetKey')) 'assetKey': (m['assetKey'] ?? '').toString(),
                  })
              .toList();
        }
      } catch (_) {
      // ignore
      }
      // =0612
      if (blocks.isEmpty) {
        final seed = raw.trim().isEmpty ? '' : raw;
        blocks = <Map<String, dynamic>>[
          {'t': 'p', 'text': seed}
        ];
      }
      // ==0612
      // =052

      int firstP = -1;
      for (var i = 0; i < blocks.length; i++) {
        if ((blocks[i]['t'] ?? '') == 'p') {
          firstP = i;
          break;
        }
      }

      // ==602

      setState(() {
        docBlocks = blocks;
        activePIndex = firstP;
        controller.text =
            (firstP >= 0) ? (blocks[firstP]['text'] ?? '').toString() : '';
      });

      // R12-060: rebuild per-block controllers on reload
      _pCtrls.clear();
      _pFocus.clear();
      focusedIndex = -1;
      selectedBlockIndexes.clear();

      // ==602
    }

     // ==052

    // =b02

    Future<void> _loadAssets() async {
      final rows = await widget.runtime.db.query(
        'assets',
        where: 'entryKey = ?',
        whereArgs: [widget.runtime.entryKey],
        orderBy: 'createdAt DESC',
      );

      setState(() {
        assets = rows;
      });
    }

    // ==b02
    // =03 scoPE: R12B04 — [PIPELINE:INGEST_FILE_TO_ASSETS_DB_REFRESH]

    // =05
      Future<void> _pickAndIngest() async {
    final typeGroup = XTypeGroup(
      label: 'Images',
      extensions: <String>['png', 'jpg', 'jpeg', 'gif', 'bmp', 'webp'],
    );

    final xfile = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
    if (xfile == null) return;

    final src = File(xfile.path);
    if (!src.existsSync()) return;

    final ext = p.extension(xfile.path).toLowerCase();
    final mime = (ext == '.png')
        ? 'image/png'
        : (ext == '.jpg' || ext == '.jpeg')
            ? 'image/jpeg'
            : (ext == '.gif')
                ? 'image/gif'
                : (ext == '.bmp')
                    ? 'image/bmp'
                    : (ext == '.webp')
                        ? 'image/webp'
                        : '';
    // =08

    final assetKey = await _ingestFile(src, mime: mime);
    if (assetKey == null) return;
    // 09
    //=0621

    setState(() {
      final insertAt = (focusedIndex >= 0 &&
              focusedIndex < docBlocks.length)
          ? (focusedIndex + 1)
          : docBlocks.length;

      docBlocks.insert(insertAt, {'t': 'img', 'assetKey': assetKey});
    });
    //==0621
    final now = DateTime.now().toIso8601String();
    final jsonBody = jsonEncode(docBlocks);

    await widget.runtime.db.update(
      'entries',
      {
        'body_text': jsonBody,
        'updatedAt': now,
      },
      where: 'key = ?',
      whereArgs: [widget.runtime.entryKey],
    );

    await _loadDoc();
    // 09
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image inserted into document')),
      );
    }

    // ==08
    }


    Future<String?> _ingestFile(File src, {String mime = ''}) async {

   
    // ==05
    
    final key = widget.runtime.entryKey;

    final now = DateTime.now().toIso8601String();
    final ext = p.extension(src.path).toLowerCase();
    final safeExt = (ext.isEmpty) ? '.bin' : ext;

    final entryDir = Directory(p.join(widget.runtime.assetsPath, key));
    if (!entryDir.existsSync()) entryDir.createSync(recursive: true);

    final fileName = '${DateTime.now().millisecondsSinceEpoch}$safeExt';
    final dstPath = p.join(entryDir.path, fileName);
    await src.copy(dstPath);

    final assetKey = 'A_${DateTime.now().microsecondsSinceEpoch}';

    await widget.runtime.db.insert('assets', {
      'assetKey': assetKey,
      'entryKey': key,
      'fileName': fileName,
      'mime': mime,
      'createdAt': now,
    });
    // =08

    await _loadAssets();
    return assetKey;
    }

    // ==08
    // ==0601
    // ==08

    TextEditingController _pCtrl(int blockIndex, String initialText) {
      final existing = _pCtrls[blockIndex];
      if (existing != null) {
        if (existing.text != initialText) {
          existing.text = initialText;
        }
        return existing;
      }

      final c = TextEditingController(text: initialText);
      c.addListener(() {
        if (blockIndex >= 0 &&
            blockIndex < docBlocks.length &&
            (docBlocks[blockIndex]['t'] ?? '') == 'p') {
          docBlocks[blockIndex]['text'] = c.text;
        }
      });

      _pCtrls[blockIndex] = c;
      return c;
    }

    FocusNode _pNode(int blockIndex) {
      final existing = _pFocus[blockIndex];
      if (existing != null) return existing;

      final n = FocusNode(debugLabel: 'p_$blockIndex');
      n.addListener(() {
        if (n.hasFocus) {
          setState(() => focusedIndex = blockIndex);
        }
      });

      _pFocus[blockIndex] = n;
      return n;
    }

   // ==0601f

    Future<String> getAlexandriaRoot() async {
      final root = Directory(r'C:\Alexandria\data');

      if (!root.existsSync()) {
        root.createSync(recursive: true);
      }

      return root.path;
    }

    // =0604



    
    Future<void> saveRealm(String realmName) async {
      
      final base = await getAlexandriaRoot();   // C:\Alexandria\data
      final realmsDir = Directory(p.join(base, 'realms'));
      if (!realmsDir.existsSync()) realmsDir.createSync(recursive: true);

      final target = Directory(p.join(realmsDir.path, realmName));
      if (!target.existsSync()) target.createSync(recursive: true);

      final dbSrc = File(p.join(base, 'alexandria.db'));
      final dbDst = File(p.join(target.path, 'alexandria.db'));
      dbSrc.copySync(dbDst.path);

      final assetsSrc = Directory(p.join(base, 'assets'));
      final assetsDst = Directory(p.join(target.path, 'assets'));

      if (assetsDst.existsSync()) assetsDst.deleteSync(recursive: true);
      assetsDst.createSync(recursive: true);

      for (var entity in assetsSrc.listSync(recursive: true)) {
        final rel = entity.path.substring(assetsSrc.path.length + 1);
        final newPath = p.join(assetsDst.path, rel);

        if (entity is File) {
          File(newPath).createSync(recursive: true);
          entity.copySync(newPath);
        }
      }

      print("REALM_SAVED: $realmName");
    }



    Future<void> _saveText() async {
        final now = DateTime.now().toIso8601String();

        // R12-060: persist current docBlocks as-is (no normalization)
        final safeBlocks = docBlocks.isEmpty
            ? <Map<String, dynamic>>[
                {'t': 'p', 'text': ''}
              ]
            : docBlocks;
        final jsonBody = jsonEncode(safeBlocks);

      await widget.runtime.db.update(
        'entries',
        {
          'body_text': jsonBody,
          'updatedAt': now,
        },
        where: 'key = ?',
        whereArgs: [widget.runtime.entryKey],
        );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved (Ctrl+S)')),
        );
      }
    }

    // ==0604
    // =0631
    // Hotkeys block
    void _showHotkeys() {
      showDialog<void>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Hotkeys'),
            content: const SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('F1  — Show this help'),
                  SizedBox(height: 6),
                  Text('Ctrl+S  — Save'),
                  SizedBox(height: 6),
                  Text('Ctrl+R  — Reload'),
                  SizedBox(height: 6),
                  Text('Ctrl+Shift+N  — Create Child'),
                  SizedBox(height: 6),
                  Text('Ctrl+V  — Paste'),
                  SizedBox(height: 6),
                  Text('Ctrl+Enter — New paragraph / Split'),
                  SizedBox(height: 6),
                  Text('Ctrl+Shift+O  — Open / ingest image'),
                  SizedBox(height: 6),
                  Text('Alt+O  — Open / ingest image'),
                  SizedBox(height: 6),
                  Text('Alt+Up  — Move block up'),
                  SizedBox(height: 6),
                  Text('Alt+Down  — Move block down'),
                  SizedBox(height: 6),
                  Text('Alt+Delete  — Delete block'),
                  SizedBox(height: 6),
                  Text('Ctrl+H  — Set asset role hero'),
                  SizedBox(height: 6),
                  Text('Ctrl+P  — Set asset role parcour'),
                  SizedBox(height: 6),
                  Text('Ctrl+N  — Clear asset role'),
                  SizedBox(height: 6),
                  Text('Ctrl+Shift+Delete  — Delete current child'),
                  SizedBox(height: 6),
                  Text('Ctrl+Shift+R  — Recompact current parent children'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    }

    // ==064b
    // =0644
    
    Future<void> _setFocusedAssetRole(String role) async {
      if (focusedAssetKey == null || focusedAssetKey!.isEmpty) return;

      await widget.runtime.db.update(
        'assets',
        {'role': role},
        where: 'assetKey = ?',
        whereArgs: [focusedAssetKey],
      );

      await _loadAssets();

      if (context.mounted) {
        final label = role.isEmpty ? 'cleared' : role;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Asset role -> $label')),
        );
      }
    }

    Future<void> _deleteFocusedBlock() async {
      if (focusedIndex < 0 || focusedIndex >= docBlocks.length) return;

      setState(() {
        docBlocks.removeAt(focusedIndex);

        _pCtrls.clear();
        _pFocus.clear();

        if (docBlocks.isEmpty) {
          docBlocks = <Map<String, dynamic>>[
            {'t': 'p', 'text': ''}
          ];
          focusedIndex = 0;
        } else if (focusedIndex >= docBlocks.length) {
          focusedIndex = docBlocks.length - 1;
        }
      });

      await _saveText();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Block deleted')),
        );
      }
    }  


Future<void> _moveBlock(int delta) async {


      if (focusedIndex < 0 || focusedIndex >= docBlocks.length) return;

      final from = focusedIndex;
      final to = from + delta;
      if (to < 0 || to >= docBlocks.length) return;

      setState(() {
        final tmp = docBlocks[from];
        docBlocks[from] = docBlocks[to];
        docBlocks[to] = tmp;

        // index-based caches can desync after reorder
        _pCtrls.clear();
        _pFocus.clear();

        focusedIndex = to;
      });

      await _saveText();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Moved block (focusedIndex=$focusedIndex)')),
        );
      }
    }
            // ==0644

    @override
    void dispose() {
      _bridgeKeyTimer?.cancel();
      super.dispose();
    }

    @override
    Widget build(BuildContext context) {
      // ==0631
      return Scaffold(
        // =0632
        appBar: AppBar(
          title: const Text('Locus Builder'),
          actions: [
          // 269
            PopupMenuButton<String>(

              onSelected: (v) async {
                if (v == 'save_realm') {
                  await saveRealm("realm_01");
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Realm saved: realm_01')),
                    );
                  }
                  return;
                }

                if (v == 'hotkeys') {
                  _showHotkeys();
                  return;
                }


                 // =271
                if (v == 'structure') {
                  final rows = await widget.runtime.db.query(
                    'entries',
                    columns: ['entryType', 'title'],
                    where: 'key = ?',
                    whereArgs: [widget.runtime.entryKey],
                    limit: 1,
                  );

                  final current = rows.isNotEmpty ? rows.first : <String, Object?>{};
                  final currentType = (current['entryType']?.toString() ?? '').trim();

                  String structureTitle = 'Children';
                  String emptyLabel = 'No children';

                  if (currentType == 'parcour') {
                    structureTitle = 'Locus / Stations';
                    emptyLabel = 'No locus yet';
                  } else if (currentType == 'locus') {
                    structureTitle = 'Objects / Children';
                    emptyLabel = 'No objects yet';
                  }

                  final directChildren = await getChildren(
                    widget.runtime.db,
                    widget.runtime.entryKey,
                  );

                  final Map<String, List<Map<String, Object?>>> nestedByParent = {};

                  if (currentType == 'parcour') {
                    for (final locusRow in directChildren) {
                      final locusKey = (locusRow['key']?.toString() ?? '').trim();
                      if (locusKey.isEmpty) continue;

                      nestedByParent[locusKey] = await getChildren(
                        widget.runtime.db,
                        locusKey,
                      );
                    }
                  }

                  await showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (sheetContext) {
                      Widget buildSimpleList(List<Map<String, Object?>> rows) {
                        if (rows.isEmpty) {
                          return Center(child: Text(emptyLabel));
                        }

                        return ListView.builder(
                          itemCount: rows.length,
                          itemBuilder: (context, index) {
                            final childRow = rows[index];
                            final seq = childRow['seq']?.toString() ?? '';
                            final title = childRow['title']?.toString() ?? '';
                            final key = childRow['key']?.toString() ?? '';
                            final entryType = childRow['entryType']?.toString() ?? '';

                            return ListTile(
                              dense: true,
                              title: Text('$seq · $title'),
                              subtitle: Text('$entryType · $key'),
                              onTap: () async {
                                Navigator.of(sheetContext).pop();
                                await _openEntry(key);
                              },
                            );
                          },
                        );
                      }

                      Widget buildParcourTree() {
                        if (directChildren.isEmpty) {
                          return Center(child: Text(emptyLabel));
                        }

                        return ListView(
                          children: [
                            for (final locusRow in directChildren) ...[
                              Builder(
                                builder: (context) {
                                  final locusSeq = locusRow['seq']?.toString() ?? '';
                                  final locusTitle = locusRow['title']?.toString() ?? '';
                                  final locusKey = locusRow['key']?.toString() ?? '';
                                  final objects = nestedByParent[locusKey] ?? const <Map<String, Object?>>[];

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ListTile(
                                        dense: true,
                                        title: Text('$locusSeq · $locusTitle'),
                                        subtitle: Text('locus · $locusKey'),
                                        onTap: () async {
                                          Navigator.of(sheetContext).pop();
                                          await _openEntry(locusKey);
                                        },
                                      ),
                                      if (objects.isEmpty)
                                        const Padding(
                                          padding: EdgeInsets.only(left: 24, right: 12, bottom: 8),
                                          child: Text('No objects yet'),
                                        )
                                      else
                                        ...objects.map((objectRow) {
                                          final objectSeq = objectRow['seq']?.toString() ?? '';
                                          final objectTitle = objectRow['title']?.toString() ?? '';
                                          final objectKey = objectRow['key']?.toString() ?? '';

                                          return ListTile(
                                            dense: true,
                                            contentPadding: const EdgeInsets.only(left: 32, right: 16),
                                            leading: const Icon(Icons.subdirectory_arrow_right, size: 18),
                                            title: Text('$objectSeq · $objectTitle'),
                                            subtitle: Text('object · $objectKey'),
                                            onTap: () async {
                                              Navigator.of(sheetContext).pop();
                                              await _openEntry(objectKey);
                                            },
                                          );
                                        }),
                                      const Divider(height: 1),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ],
                        );
                      }

                      return SafeArea(
                        child: SizedBox(
                          height: MediaQuery.of(sheetContext).size.height * 0.70,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                child: Text(
                                  '$structureTitle — ${widget.runtime.entryKey}',
                                  style: Theme.of(sheetContext).textTheme.titleMedium,
                                ),
                              ),
                              const Divider(height: 1),
                              Expanded(
                                child: currentType == 'parcour'
                                    ? buildParcourTree()
                                    : buildSimpleList(directChildren),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
                // =271
                
              },
              // MenuTress puntos
              itemBuilder: (context) => const [
                PopupMenuItem<String>(
                  value: 'save_realm',
                  child: Text('Save Realm'),
                ),
                PopupMenuItem<String>(
                  value: 'structure',
                  child: Text('Structure'),
                ),
                PopupMenuItem<String>(
                  value: 'hotkeys',
                  child: Text('Hotkeys (F1)'),
                ),
              ],


            ),

            // =269

          ],
        ),
              // ==0632
              // =03
        body: Shortcuts(
                // =0633
          shortcuts: <LogicalKeySet, Intent>{ 
                LogicalKeySet(LogicalKeyboardKey.f1): const _HelpIntent(),
                  // ==0633
                LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS): const _SaveIntent(),
                LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyR): const _ReloadIntent(),
                LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyN): const _CreateChildIntent(),
                // =09
                LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyV): const _PasteIntent(),
                LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyO): const _OpenIntent(),
                              // =0613
                LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.keyO): const _OpenIntent(),
                LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowUp): const _MoveUpIntent(),
                LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowDown): const _MoveDownIntent(),

                LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.enter): const _NewParaIntent(),
                LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.delete): const _DeleteBlockIntent(),
                LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyH): const _HeroRoleIntent(),
                LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyP): const _ParcourRoleIntent(),    
                LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN): const _ClearRoleIntent(),
                LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.delete): const _DeleteChildIntent(),
                LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyR): const _RecompactChildrenIntent(),

                  // ==0613
                  // ==09
          },
          child: Actions(
              actions: <Type, Action<Intent>>{
                    // =0634
                _HelpIntent: CallbackAction<_HelpIntent>(onInvoke: (_) {
                  _showHotkeys();
                  return null;
                }),
                  // ==0634    
                _SaveIntent: CallbackAction<_SaveIntent>(onInvoke: (_) async {
                  await _saveText();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Saved (Ctrl+S)')),
                    );
                  }
                  return null;
                }),
                
                _CreateChildIntent: CallbackAction<_CreateChildIntent>(onInvoke: (_) async {

                  final created = await createChildEntry(
                    widget.runtime.db,
                    widget.runtime.entryKey,
                    widget.runtime.assetsPath,
                  );

                  await _loadChildren();

                  if (created == null) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('capacity reached')),
                      );
                    }
                    return null;
                  }

                  final newKey = (created['key']?.toString() ?? '').trim();
                  if (newKey.isNotEmpty) {
                    await _openEntry(newKey);
                  }

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Child created (Ctrl+Shift+N)')),
                    );
                  }
                  return null;
                }),
                // ==
                _ReloadIntent: CallbackAction<_ReloadIntent>(onInvoke: (_) async {
                // =07
                  await _loadDoc();
                  await _loadAssets();
                  await _loadChildren();
                  return null;
                }),
                // ==07


                // =05
                // =0616
                _PasteIntent: CallbackAction<_PasteIntent>(onInvoke: (_) async {
                  // Ctrl+V: prioridad imagen (super_clipboard) -> fallback texto
                  try {
                    final sys = SystemClipboard.instance;
                    if (sys != null) {
                      final reader = await sys.read();
                      for (final item in reader.items) {
                        if (!item.canProvide(Formats.png)) continue;

                        final completer = Completer<List<int>?>();
                        item.getFile(
                          Formats.png,
                          (f) async {
                            try {
                              final data = await f.readAll();
                              completer.complete(data);
                            } catch (_) {
                              completer.complete(null);
                            }
                          },
                          onError: (_) => completer.complete(null),
                        );

                        final bytes = await completer.future;
                        if (bytes == null || bytes.isEmpty) continue;

                        final tmp = File(p.join(
                          Directory.systemTemp.path,
                          'raz_clip_${DateTime.now().microsecondsSinceEpoch}.png',
                        ));
                        await tmp.writeAsBytes(bytes);

                        final assetKey = await _ingestFile(tmp, mime: 'image/png');
                        if (assetKey != null && assetKey.isNotEmpty) {
                          setState(() {
                            final insertAt = (focusedIndex >= 0 && focusedIndex < docBlocks.length)
                                ? (focusedIndex + 1)
                                : docBlocks.length;
                            docBlocks.insert(insertAt, {'t': 'img', 'assetKey': assetKey});
                          });

                          await _saveText();

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Pasted image (Ctrl+V)')),
                            );
                          }
                          return null;
                        }
                      }
                    }
                  } catch (_) {
                    // ignore -> cae a texto
                  }

                  // Texto (fallback)
                  if (focusedIndex < 0 ||
                      focusedIndex >= docBlocks.length ||
                      (docBlocks[focusedIndex]['t'] ?? '') != 'p') {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Paste: focus a paragraph first')),
                      );
                    }
                    return null;
                  }

                  final data = await Clipboard.getData('text/plain');
                  final clip = (data?.text ?? '');
                  if (clip.isEmpty) return null;

                  final ctrl = _pCtrls[focusedIndex];
                  if (ctrl == null) return null;

                  final text = ctrl.text;
                  final sel = ctrl.selection;
                  final start = sel.isValid ? sel.start : text.length;
                  final end = sel.isValid ? sel.end : text.length;

                  final s = start < 0 ? 0 : (start > text.length ? text.length : start);
                  final e = end < 0 ? 0 : (end > text.length ? text.length : end);

                  final merged = text.replaceRange(s, e, clip);
                  ctrl.text = merged;
                  ctrl.selection = TextSelection.collapsed(offset: s + clip.length);

                  docBlocks[focusedIndex]['text'] = ctrl.text;

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Pasted text (Ctrl+V)')),
                    );
                  }
                  return null;
                }),
                                
                // =0616
                // =09
                _OpenIntent: CallbackAction<_OpenIntent>(onInvoke: (_) async {
                  await _pickAndIngest();
                  return null;
                }),
                // =0644
                _MoveUpIntent: CallbackAction<_MoveUpIntent>(onInvoke: (_) async {
                  await _moveBlock(-1);
                  return null;
                }),
                _MoveDownIntent: CallbackAction<_MoveDownIntent>(onInvoke: (_) async {
                  await _moveBlock(1);
                  return null;
                }),
                // ==0644
                // =0617

                _HeroRoleIntent: CallbackAction<_HeroRoleIntent>(onInvoke: (_) async {
                  await _setFocusedAssetRole("hero");
                  return null;
                }),

                _ParcourRoleIntent: CallbackAction<_ParcourRoleIntent>(onInvoke: (_) async {
                  await _setFocusedAssetRole("parcour");
                  return null;
                }),

                _ClearRoleIntent: CallbackAction<_ClearRoleIntent>(onInvoke: (_) async {
                  await _setFocusedAssetRole("");
                  return null;
                }),

                _DeleteChildIntent: CallbackAction<_DeleteChildIntent>(onInvoke: (_) async {
                  final currentKey = widget.runtime.entryKey.trim();
                  if (currentKey.isEmpty) return null;

                  final rows = await widget.runtime.db.query(
                    'entries',
                    columns: ['parentKey'],
                    where: 'key = ?',
                    whereArgs: [currentKey],
                    limit: 1,
                  );

                  final parentKey = rows.isNotEmpty
                      ? (rows.first['parentKey']?.toString() ?? '').trim()
                      : '';

                  if (parentKey.isEmpty) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Delete child: current entry has no parent')),
                      );
                    }
                    return null;
                  }

                  await deleteChildEntry(
                    widget.runtime.db,
                    currentKey,
                    widget.runtime.assetsPath,
                  );

                  await _openEntry(parentKey);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Child deleted (Ctrl+Shift+Delete)')),
                    );
                  }
                  return null;
                }),

                _RecompactChildrenIntent: CallbackAction<_RecompactChildrenIntent>(onInvoke: (_) async {
                  final currentKey = widget.runtime.entryKey.trim();
                  if (currentKey.isEmpty) return null;

                  await recompactChildren(widget.runtime.db, currentKey);
                  await _loadChildren();

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Children recompact done (Ctrl+Shift+R)')),
                    );
                  }
                  return null;
                }),


                // 277

                _NewParaIntent: CallbackAction<_NewParaIntent>(onInvoke: (_) async {

                  if (focusedIndex < 0 ||
                      focusedIndex >= docBlocks.length ||
                      (docBlocks[focusedIndex]['t'] ?? '') != 'p') {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Split: focus a paragraph first')),
                      );
                    }
                    return null;
                  }

                  final c = _pCtrls[focusedIndex];
                  if (c == null) return null;

                  final text = c.text;
                  final sel = c.selection;
                  final cut = sel.isValid ? sel.baseOffset : text.length;
                  final safeCut = (cut < 0) ? 0 : (cut > text.length ? text.length : cut);

                  final before = text.substring(0, safeCut);
                  final after = text.substring(safeCut);

                  setState(() {
                    docBlocks[focusedIndex]['text'] = before;
                    docBlocks.insert(focusedIndex + 1, {'t': 'p', 'text': after});
                  });

                  await _saveText();

                  final newIndex = focusedIndex + 1;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final n = _pFocus[newIndex];
                    if (n != null) {
                      n.requestFocus();
                    }
                  });

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Split paragraph (Ctrl+Enter)')),
                    );
                  }
                  return null;
                }),

                _DeleteBlockIntent: CallbackAction<_DeleteBlockIntent>(onInvoke: (_) async {
                  await _deleteFocusedBlock();
                  return null;
                }),
                // =277
                       // =0617
                            // ==09
                              // ==05

              },
              child: Focus(
                autofocus: true,
                child: Column(
                  children: [
                          // ==03
                          // =0605

                  const SizedBox(height: 0),

                  ElevatedButton(
                    onPressed: _saveText,
                    child: const Text('Save Document'),
                  ),

                  const SizedBox(height: 12),
                  FutureBuilder<List<Map<String, Object?>>>(


                    future: widget.runtime.db.query(
                      'entries',
                      columns: ['title', 'key', 'entryType', 'parentKey'],
                      where: 'key = ?',
                      whereArgs: [widget.runtime.entryKey],
                      limit: 1,
                    ),
                    builder: (context, snap) {
                      final row = (snap.data != null && snap.data!.isNotEmpty)
                          ? snap.data!.first
                          : <String, Object?>{};
                      final title = (row['title']?.toString() ?? '').trim();
                      final key = (row['key']?.toString() ?? widget.runtime.entryKey).trim();
                      final entryType = (row['entryType']?.toString() ?? '').trim();
                      final parentKey = (row['parentKey']?.toString() ?? '').trim();

                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Type: $entryType'),
                                  Text('Title: ${title.isEmpty ? "(untitled)" : title}'),
                                  Text('Key: $key'),
                                  Text('Parent: ${parentKey.isEmpty ? "-" : parentKey}'),
                                ],
                              ),
                            ),
                            if (parentKey.isNotEmpty)
                              TextButton.icon(
                                onPressed: () async {
                                  await _openEntry(parentKey);
                                },
                                icon: const Icon(Icons.arrow_upward),
                                label: const Text('Back to Parent'),
                              ),
                          ],
                        ),
                      );
                    },
                  ),

                      // =07

                  const SizedBox(height: 12),
                  const Divider(),
                  Text("Document Inline (blocks: ${docBlocks.length})"),
                  // =264

                Expanded(
                  child: ListView.builder(
                    itemCount: docBlocks.length,
                    itemBuilder: (context, index) {
                      final b = docBlocks[index];
                      final t = (b['t'] ?? 'p').toString();
                      if (t == 'img') {
                        final assetKey = (b['assetKey'] ?? '').toString();
                        final row = assets.cast<Map<String, Object?>>().firstWhere(
                              (x) => (x['assetKey']?.toString() ?? '') == assetKey,
                              orElse: () => <String, Object?>{},
                            );
                        final fileName = (row['fileName']?.toString() ?? '');

                        final role = (row['role']?.toString() ?? '').trim();
                        final isParcourRole = role == 'parcour';
                        final isHeroRole = role == 'hero';

                        

                        // [CHANGE 40]
                        // Highlight parcour assets inside inline document view.
                        // Parcour images represent navigation maps for Gatekeeper,
                        // so they must be visually distinguishable from normal recall images.

                        final fullPath = fileName.isEmpty
                            ? ''
                            : p.join(widget.runtime.assetsPath, widget.runtime.entryKey, fileName);


                        // Cambio 273A.9

                        final f = fullPath.isEmpty ? null : File(fullPath);
                        final isSelected = selectedBlockIndexes.contains(index);

                        final Color borderColor = isParcourRole
                            ? (isSelected
                                ? Colors.amber
                                : (focusedIndex == index ? Colors.orange : Colors.amber))
                            : (isSelected
                                ? Colors.green
                                : (focusedIndex == index ? Colors.blue : Colors.transparent));

                        final double borderWidth = isParcourRole
                            ? (isSelected || focusedIndex == index ? 3.0 : 2.0)
                            : (isSelected || focusedIndex == index ? 2.0 : 0.0);

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Focus(
                            focusNode: _pNode(index),
                            child: GestureDetector(
                              onTap: () {
                                focusedAssetKey = assetKey;
                                focusedIndex = index;
                                _pNode(index).requestFocus();
                                _toggleBlockSelection(index);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                
                                  color: isParcourRole
                                      ? Colors.amber.withOpacity(0.18)
                                      : (isHeroRole ? Colors.cyan.withOpacity(0.18) : null),

                                  border: Border.all(
                                    color: borderColor,
                                    width: borderWidth,
                                  ),
                               
                                  borderRadius: BorderRadius.circular(6.0),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                                      child: Text(

                                        isParcourRole
                                            ? "IMG: $assetKey  [COLLAGE]"
                                                : (isHeroRole ? "IMG: $assetKey  [HERO]" : "IMG: $assetKey"),

                                        style: TextStyle(
                                          fontWeight: (isParcourRole || isHeroRole) ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),




                                    if (f != null && f.existsSync())
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(maxHeight: 280),
                                        child: Image.file(f, fit: BoxFit.contain),
                                      )
                                    else
                                      const Text("(missing file)"),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );                        // ==0607
                        // Cambio 273A.9
                      }

                      // =0606
                      // paragraph block (editable)
                      final blockIndex = docBlocks.indexOf(b);
                      final text = (b['text'] ?? '').toString();
                      final isSelected = selectedBlockIndexes.contains(blockIndex);

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: GestureDetector(
                          onTap: () {
                            focusedIndex = blockIndex;
                            _pNode(blockIndex).requestFocus();
                            _toggleBlockSelection(blockIndex);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected
                                    ? Colors.green
                                    : (focusedIndex == blockIndex ? Colors.blue : Colors.transparent),
                                width: isSelected || focusedIndex == blockIndex ? 2 : 0,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: TextField(
                              controller: _pCtrl(blockIndex, text),
                              focusNode: _pNode(blockIndex),
                              maxLines: null,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                        ),
                      );                      // ==0606
                      
                    },
                  ),
                ),

                const Divider(),

                // [CHANGE 39] Hide gallery assets section temporarily.
                // Keep asset loading and ingest logic intact.
                // Only remove the gallery widget from the visible UI.
                if (false) ...[
                  Text("Gallery (assets for ${widget.runtime.entryKey})"),
                  SizedBox(
                    height: 170,
                    child: assets.isEmpty
                        ? const Center(child: Text("No images yet"))
                        : ListView.builder(
                            itemCount: assets.length,
                            itemBuilder: (context, index) {
                              final item = assets[index];
                              final fileName = item['fileName'] as String;
                              final fullPath = p.join(
                                widget.runtime.assetsPath,
                                widget.runtime.entryKey,
                                fileName,
                              );
                              final f = File(fullPath);

                              return ListTile(
                                dense: true,
                                leading: SizedBox(
                                  width: 56,
                                  height: 56,
                                  child: f.existsSync()
                                      ? Image.file(f, fit: BoxFit.cover)
                                      : const Icon(Icons.broken_image),
                                ),
                                title: Text(fileName),
                              );
                            },
                          ),
                  ),
                ],

                const SizedBox(height: 8),

              // ==07
              // 03
                            ],
                ),
              ),
            ),
        ),
      );
    }
    //==03
    // =03
  }

class _SaveIntent extends Intent {
  const _SaveIntent();
}

class _ReloadIntent extends Intent {
  const _ReloadIntent();
}

class _PasteIntent extends Intent {
  const _PasteIntent();
}

class _HelpIntent extends Intent {
  const _HelpIntent();
}
// =09
// Raz -12 Godot 13.6
class _OpenIntent extends Intent {
  const _OpenIntent();
}

class _CreateChildIntent extends Intent {
  const _CreateChildIntent();
}

class _MoveUpIntent extends Intent {
  const _MoveUpIntent();
}

class _MoveDownIntent extends Intent {
  const _MoveDownIntent();
}

class _NewParaIntent extends Intent {
  const _NewParaIntent();
}

class _DeleteBlockIntent extends Intent {
  const _DeleteBlockIntent();
}

class _HeroRoleIntent extends Intent {
  const _HeroRoleIntent();
}

class _ParcourRoleIntent extends Intent {
  const _ParcourRoleIntent();
}

class _ClearRoleIntent extends Intent {
  const _ClearRoleIntent();
}

class _DeleteChildIntent extends Intent {
  const _DeleteChildIntent();
}

class _RecompactChildrenIntent extends Intent {
  const _RecompactChildrenIntent();
}
//= Raz -12 Godot 13.6

// ==09

// ==03