import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/app_config.dart';
import 'app.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.initialize();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await _initializeSupabaseIfConfigured();

  final container = ProviderContainer();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  runApp(
    UncontrolledProviderScope(container: container, child: const TawakkalApp()),
  );
}

Future<void> _initializeSupabaseIfConfigured() async {
  if (!AppConfig.hasSupabaseCredentials) {
    return;
  }

  try {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
      debug: false,
    );
  } catch (_) {
    // The app remains usable in guest/offline mode if Supabase is unavailable.
  }
}
