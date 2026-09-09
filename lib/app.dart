import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tamam/core/router/app_router.dart';
import 'package:tamam/core/theme/app_theme.dart';

/// The root application widget for Tamam.
class TamamApp extends ConsumerWidget {
  /// Creates a [TamamApp] instance.
  const TamamApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Tamam',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
    );
  }
}
