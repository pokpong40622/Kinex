import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';

class KinexApp extends ConsumerWidget {
  const KinexApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Kinex',
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
      scrollBehavior: const _KinexScrollBehavior(),
      routerConfig: router,
    );
  }
}

class _KinexScrollBehavior extends MaterialScrollBehavior {
  const _KinexScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}
