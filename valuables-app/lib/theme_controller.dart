import 'package:flutter/material.dart';

/// Global theme controller used by the app.
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

/// Global notifier for Supabase initialization status
final ValueNotifier<bool> supabaseInitializedNotifier = ValueNotifier(false);
