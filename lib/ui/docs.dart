import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mediapipe_text/mediapipe_text.dart';
import 'package:signals/signals_flutter.dart';

import '../src/database/database.dart';
import 'details.dart';
import 'search.dart';

class Docs extends StatefulWidget {
  const Docs({super.key});

  @override
  State<Docs> createState() => _DocsState();
}

class _DocsState extends State<Docs> {
  Future<void> loadModel(BuildContext context) async {
    ByteData? embedderBytes = await DefaultAssetBundle.of(context).load(
      'assets/universal-sentence-encoder.tflite',
    );

    embedder.value = TextEmbedder(
      TextEmbedderOptions.fromAssetBuffer(
        embedderBytes.buffer.asUint8List(),
      ),
    );
  }

  late final docs$ = Database.instance.getFiles().watch().toSignal();
  final loading = signal(false);
  final embedder = signal<TextEmbedder?>(null);

  Future<void> addFile() async {
    loading.value = true;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'md', 'markdown', 'html'],
      );
      if (result == null || result.xFiles.isEmpty) {
        loading.value = false;
        return;
      }
      final file = result.xFiles.first;
      final str = await file.readAsString();
      final db = Database.instance;
      await db.transaction(() async {
        final fileId = await db //
            .insertFile(file.path, str)
            .then((e) => e.first.id);
        final chunks = chunkText(str);
        for (final chunk in chunks) {
          final chunkId = await db.addChunk(
            chunk.$1,
            textEmbedder: embedder()!,
          );
          await db.insertFileEmbedding(fileId, chunkId, chunk.$2, chunk.$3);
        }
      });
    } catch (err) {
      debugPrint('error embedding content: $err');
    } finally {
      loading.value = false;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadModel(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (embedder.watch(context) == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Flutter AI Docs Search'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter AI Docs Search'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => SearchDocs(
                  textEmbedder: embedder()!,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (loading.watch(context)) const LinearProgressIndicator(),
          Expanded(
            child: docs$.watch(context).map(
                  data: (items) {
                    if (items.isEmpty) {
                      return const Center(
                        child: Text('No documents found'),
                      );
                    }
                    return ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return ListTile(
                          title: Text(item.path),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => DocDetails(fileId: item.id),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  error: (err) => Center(
                    child: Text('Error loading documents: $err'),
                  ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: loading.watch(context) ? null : addFile,
        child: const Icon(Icons.add),
      ),
    );
  }
}
