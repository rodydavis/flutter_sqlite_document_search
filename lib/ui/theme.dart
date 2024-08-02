import 'package:flutter/material.dart';
import 'package:signals/signals.dart';

class AppTheme {
  final light = ThemeData.light();
  final dark = ThemeData.dark();
  final mode = signal(ThemeMode.system);
}
