import 'package:sqlite3/sqlite3.dart';

void main() {
  final db = sqlite3.open(r'C:\Alexandria\data\alexandria.db');
  final n = db.select('SELECT COUNT(*) AS c FROM entries').first['c'];
  db.dispose();
  print(n);
}
