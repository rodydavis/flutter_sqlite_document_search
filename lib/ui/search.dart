import 'package:flutter/material.dart';
import 'package:mediapipe_text/mediapipe_text.dart';
import 'package:signals/signals_flutter.dart';

import '../src/database/database.dart';
import 'card.dart';

class SearchDocs extends StatefulWidget {
  const SearchDocs({super.key, required this.textEmbedder});

  final TextEmbedder textEmbedder;

  @override
  State<SearchDocs> createState() => _SearchDocsState();
}

class _SearchDocsState extends State<SearchDocs> {
  final results$ = signal<List<SearchEmbeddingsResult>?>(null);
  final controller = TextEditingController();

  Future<void> search() async {
    final str = controller.text.trim();
    if (str.isEmpty) return;
    final results = await Database.instance.searchChunks(
      str,
      textEmbedder: widget.textEmbedder,
    );
    final list = await results.get();
    results$.value = list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Search Documents'),
        ),
        actions: [
          AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              return IconButton(
                onPressed: controller //
                        .text
                        .isEmpty
                    ? null
                    : () => controller.clear(),
                icon: const Icon(Icons.clear),
              );
            },
          ),
          IconButton(
            onPressed: search,
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: () {
        final results = results$.watch(context);
        if (results != null) {
          if (results.isEmpty) {
            return const Center(child: Text('No document found for query'));
          }
          return ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              final item = results[index];
              // final rank = item.distance.clamp(0, 1);
              // final rankDesc = ((1 - rank) * 100).toStringAsFixed(0);
              final file = File(
                id: item.fileId!,
                path: item.path!,
                content: item.content ?? '',
              );
              return DocCard(
                file: file,
                embedder: widget.textEmbedder,
              );
            },
          );
        }
        return const Center(child: Text('Search for something'));
      }(),
    );
  }
}
