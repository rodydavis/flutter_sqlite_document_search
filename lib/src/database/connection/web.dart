import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:flutter/foundation.dart';

/// Obtains a database connection for running drift on the web.
DatabaseConnection connect(String name) {
  return DatabaseConnection.delayed(Future(() async {
    final db = await WasmDatabase.open(
      databaseName: name,
      sqlite3Uri: Uri.parse(kDebugMode ? 'sqlite.debug.wasm' : 'sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
      localSetup: (db) async {
        db.execute(
          'CREATE VIRTUAL TABLE IF NOT EXISTS chunks using vec0( '
          '  id INTEGER PRIMARY KEY AUTOINCREMENT, '
          '  embedding float[768] '
          ');',
        );
      },
    );

    if (db.missingFeatures.isNotEmpty) {
      debugPrint(
        'Using ${db.chosenImplementation} due to unsupported '
        'browser features: ${db.missingFeatures}',
      );
    }

    return db.resolvedExecutor;
  }));
}

Future<void> validateDatabaseSchema(GeneratedDatabase database) async {
  // Unfortunately, validating database schemas only works for native platforms
  // right now.
  // As we also have migration tests (see the `Testing migrations` section in
  // the readme of this example), this is not a huge issue.
}
