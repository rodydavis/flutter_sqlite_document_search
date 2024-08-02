import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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
  late final docs$ = Database.instance.getFiles().watch().toSignal();
  final loading = signal(false);

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
          final chunkId = await db.addChunk(chunk.$1);
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter AI Docs Search'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const SearchDocs(),
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
