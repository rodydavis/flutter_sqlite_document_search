import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite_vec/sqlite_vec.dart' as sqlite_vec;
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

Future<File> databaseFile(String name) async {
  // We use `path_provider` to find a suitable path to store our data in.
  final appDir = await getApplicationDocumentsDirectory();
  final dbPath = p.join(appDir.path, '$name.db');
  return File(dbPath);
}

/// Obtains a database connection for running drift in a Dart VM.
DatabaseConnection connect(String name) {
  return DatabaseConnection.delayed(Future(() async {
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();

      final cachebase = (await getTemporaryDirectory()).path;

      // We can't access /tmp on Android, which sqlite3 would try by default.
      // Explicitly tell it about the correct temporary directory.
      sqlite3.tempDirectory = cachebase;
    }

    sqlite3.ensureExtensionLoaded(
      SqliteExtension.inLibrary(sqlite_vec.vec0, 'sqlite3_vec_init'),
    );

    return NativeDatabase.createBackgroundConnection(
      await databaseFile(name),
    );
  }));
}
