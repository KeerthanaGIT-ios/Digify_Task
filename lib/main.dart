import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/navigation/app_router.dart';
import 'core/storage/hive_service.dart';
import 'core/theme/app_theme.dart';

void main() async {
  // Ensure Flutter engine is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive and open database box
  final hiveService = HiveService();
  await hiveService.init();

  runApp(
    ProviderScope(
      overrides: [
        // Provide the pre-initialized HiveService instance
        hiveServiceProvider.overrideWithValue(hiveService),
      ],
      child: const MovieDiscoveryApp(),
    ),
  );
}

class MovieDiscoveryApp extends ConsumerWidget {
  const MovieDiscoveryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Movie Discovery',
      theme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
