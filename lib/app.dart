import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import 'state/shop_providers.dart';

class KinexApp extends ConsumerWidget {
  const KinexApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // Shop/profile state (coins, cosmetics, active theme/character, name):
    // load the persisted value once at startup, then save back on every
    // change. Defaults render immediately; hydration overwrites them once
    // shared_preferences resolves (usually within a frame).
    ref.watch(shopHydrationProvider);
    ref.listen(coinsProvider, (_, _) => persistShop(ref));
    ref.listen(unlockedThemesProvider, (_, _) => persistShop(ref));
    ref.listen(activeThemeProvider, (_, _) => persistShop(ref));
    ref.listen(unlockedCharactersProvider, (_, _) => persistShop(ref));
    ref.listen(activeCharacterProvider, (_, _) => persistShop(ref));
    ref.listen(unlockedGamesProvider, (_, _) => persistShop(ref));
    ref.listen(userNameProvider, (_, _) => persistShop(ref));

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
