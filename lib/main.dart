import 'package:flutter/material.dart';
import 'package:signals/signals.dart';
import 'package:signals/signals_flutter_extended.dart';

import 'ui/app.dart';
import 'ui/theme.dart';

void main() {
  runApp(
    SignalProvider.value(
      value: signal(AppTheme()),
      child: const App(),
    ),
  );
}
