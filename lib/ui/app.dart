import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:signals/signals_flutter_extended.dart';

import 'docs.dart';
import 'theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = SignalProvider.of<AppTheme>(context)();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme.light,
      darkTheme: theme.dark,
      themeMode: theme.mode.watch(context),
      home: const Docs(),
    );
  }
}
