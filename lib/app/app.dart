import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import 'router.dart';
import 'theme/theme.dart';

class TawakkalApp extends ConsumerWidget {
  const TawakkalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: AppConfig.appName,
      theme: TawakkalTheme.light(),
      routerConfig: router,
    );
  }
}
