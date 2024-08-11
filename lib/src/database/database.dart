import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'connection/connection.dart' as impl;
import 'package:google_generative_ai/google_generative_ai.dart';

part 'database.g.dart';

@DriftDatabase(include: {'sql.drift'})
class Database extends _$Database {
  Database() : super(impl.connect('app.v5'));

  Database.forTesting(DatabaseConnection super.connection);

  static Database instance = Database();

  @override
  int get schemaVersion => 1;

  final textEmbedder = GenerativeModel(
    model: 'text-embedding-004',
    apiKey: const String.fromEnvironment('GOOGLE_AI_API_KEY'),
  );

  Future<int> addChunk(
    String text, {
    String? title,
    int? outputDimensionality,
  }) async {
    final result = await textEmbedder.embedContent(
      Content.text(text),
      taskType: TaskType.retrievalDocument,
      title: title,
      outputDimensionality: outputDimensionality,
    );
    await customStatement(
      'INSERT INTO chunks (embedding) VALUES (:embedding)',
      [_serializeFloat32(result.embedding.values)],
    );
    return await getLastId().getSingle();
  }

  Future<Selectable<SearchEmbeddingsResult>> searchChunks(
    String query, {
    String? title,
    int? outputDimensionality,
  }) async {
    final result = await textEmbedder.embedContent(
      Content.text(query),
      taskType: TaskType.retrievalQuery,
      title: title,
      outputDimensionality: outputDimensionality,
    );
    return searchEmbeddings(_serializeFloat32(result.embedding.values));
  }

  Future<void> deleteChunk(int id) async {
    await customStatement(
      'DELETE FROM chunks WHERE id = :id',
      [id],
    );
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          m.database.customStatement(
            'CREATE VIRTUAL TABLE IF NOT EXISTS chunks using vec0( '
            '  id INTEGER PRIMARY KEY AUTOINCREMENT, '
            '  embedding float[768] '
            ');',
          );
        },
      );
}

// Serializes a float32 list into a vector BLOB that sqlite-vec accepts.
Uint8List _serializeFloat32(List<double> vector) {
  final ByteData byteData = ByteData(vector.length * 4); // 4 bytes per float32

  for (int i = 0; i < vector.length; i++) {
    byteData.setFloat32(i * 4, vector[i], Endian.little);
  }

  return byteData.buffer.asUint8List();
}

// Split long text into chunks for embedding
Iterable<(String, int, int)> chunkText(String text) sync* {
  final regex = RegExp(r'((?:[^\n][\n]?)+)');
  final matches = regex.allMatches(text);
  for (final match in matches) {
    // Need to limit to 500 tokens for really long paragraphs
    final str = text.substring(match.start, match.end);
    yield (str, match.start, match.end);
  }
}
