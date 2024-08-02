import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:signals/signals_flutter.dart';

import '../src/database/database.dart';

class DocDetails extends StatefulWidget {
  const DocDetails({
    super.key,
    required this.fileId,
  });

  final int fileId;

  @override
  State<DocDetails> createState() => _DocDetailsState();
}

class _DocDetailsState extends State<DocDetails> {
  late final details$ = Database //
      .instance
      .getFileById(widget.fileId)
      .watchSingleOrNull()
      .toSignal();

  Future<void> deleteFile(int fileId) async {
    final db = Database.instance;
    return await db.transaction(() async {
      await db.deleteFileById(fileId);
      final current = await db.getFileEmbeddingsByFileId(fileId).get();
      for (final item in current) {
        await db.deleteChunk(item.chunkId);
      }
      await db.deleteFileEmbeddingByFileId(fileId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Document Details: ${widget.fileId}'),
        actions: [
          IconButton(
            onPressed: () => deleteFile(widget.fileId).then(
              (_) => Navigator.of(context).pop(),
            ),
            icon: const Icon(Icons.delete),
          )
        ],
      ),
      body: details$.watch(context).map(
            data: (result) {
              if (result == null) {
                return const Center(
                  child: Text('Document not found'),
                );
              }
              return SingleChildScrollView(
                child: MarkdownBody(
                  data: result.content ?? '',
                  selectable: true,
                ),
              );
            },
            error: (err) => Center(
              child: Text('Error loading document: $err'),
            ),
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
          ),
    );
  }
}
