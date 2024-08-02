import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
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
      SqliteExtension.inLibrary(_loadLibrary('vec0'), 'sqlite3_vec_init'),
    );

    return NativeDatabase.createBackgroundConnection(
      await databaseFile(name),
      setup: (db) async {
        db.execute(
          'CREATE VIRTUAL TABLE IF NOT EXISTS chunks using vec0( '
          '  id INTEGER PRIMARY KEY AUTOINCREMENT, '
          '  embedding float[768] '
          ');',
        );
      },
    );
  }));
}

DynamicLibrary _loadLibrary(String name) {
  if (Platform.isIOS || Platform.isMacOS) {
    return DynamicLibrary.open('$name.dylib');
  }
  if (Platform.isAndroid || Platform.isLinux) {
    return DynamicLibrary.open('$name.so');
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open(() {
      if (kDebugMode) {
        return p.normalize(p.join(
          Directory.current.path,
          'extensions',
          '$name.dll',
        ));
      } else {
        final assets = p.normalize(
          p.join(
            'data',
            'flutter_assets',
            'packages',
            'flutter_sqlite_document_search',
            'extensions',
          ),
        );
        final exe = File(Platform.resolvedExecutable).parent.path;
        return p.normalize(p.join(exe, assets, '$name.dll'));
      }
    }());
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}
