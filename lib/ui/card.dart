import 'package:flutter/material.dart';
import 'package:mediapipe_text/mediapipe_text.dart';

import '../src/database/database.dart';

class DocCard extends StatelessWidget {
  const DocCard({
    super.key,
    required this.file,
    required this.embedder,
  });

  final File file;
  final TextEmbedder embedder;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(file.path),
      subtitle: Text(file.content ?? ''),
      trailing: const Icon(Icons.edit),
      onTap: () async {
        await showContentEdit(context, embedder, file: file);
      },
    );
  }
}

Future<void> showContentEdit(BuildContext context, TextEmbedder embedder,
    {File? file}) async {
  final contentController = TextEditingController(text: file?.content);
  final pathController = TextEditingController(
      text: file?.path ?? DateTime.now().toIso8601String());
  bool deleted = false;
  final controller = showBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return Material(
        color: Colors.transparent,
        child: Card(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: TextField(
                  controller: pathController,
                  decoration: const InputDecoration(
                    labelText: 'Edit title',
                  ),
                ),
                trailing: file != null
                    ? IconButton(
                        onPressed: () async {
                          final nav = Navigator.of(context);
                          await deleteFile(file.id);
                          deleted = true;
                          nav.pop();
                        },
                        icon: const Icon(Icons.delete),
                      )
                    : null,
              ),
              Expanded(
                child: ListTile(
                  title: const Text('Edit content'),
                  subtitle: TextField(
                    controller: contentController,
                    expands: true,
                    maxLines: null,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
  await controller.closed;
  if (deleted) return;
  final text = contentController.text.trim();
  final path = pathController.text.trim();
  if (text.isEmpty) return;
  if (path.isEmpty) return;
  if (file != null) await deleteFile(file.id);
  await addFile(path, text, embedder);
}

Future<void> deleteFile(int fileId) async {
  final db = Database.instance;
  await db.transaction(() async {
    await db.deleteFileById(fileId);
    final current = await db.getFileEmbeddingsByFileId(fileId).get();
    for (final item in current) {
      await db.deleteChunk(item.chunkId);
    }
    await db.deleteFileEmbeddingByFileId(fileId);
  });
}

Future<void> addFile(String path, String content, TextEmbedder embedder) async {
  final db = Database.instance;
  await db.transaction(() async {
    final fileId = await db //
        .insertFile(path, content)
        .then((e) => e.first.id);
    final chunks = chunkText(content);
    for (final chunk in chunks) {
      final chunkId = await db.addChunk(
        chunk.$1,
        textEmbedder: embedder,
      );
      await db.insertFileEmbedding(fileId, chunkId, chunk.$2, chunk.$3);
    }
  });
}
