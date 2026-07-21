import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import 'state/shop_providers.dart';
import 'state/accent_theme.dart';
import 'state/assessment_profile.dart';
import 'theme/app_theme.dart';

class KinexApp extends ConsumerWidget {
  const KinexApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // Apply the equipped accent colour set (shop "ธีมสี") to KColors before any
    // screen builds. Re-runs whenever the user picks a different set.
    final accent = ref.watch(accentSetProvider);
    KColors.applyAccentSet(accent);

    // Shop/profile state (coins, cosmetics, active theme/character, name):
    // load the persisted value once at startup, then save back on every
    // change. Defaults render immediately; hydration overwrites them once
    // shared_preferences resolves (usually within a frame).
    ref.watch(shopHydrationProvider);
    // Hydrate the persisted assessment profile early so a returning user's
    // name/age/height/weight are ready to prefill when they start an assessment.
    ref.watch(savedProfileProvider);
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
      // Recolour the WHOLE app the instant a new accent set is equipped. Routes use
      // const page builders, so mutating KColors alone doesn't repaint the current
      // page — keying the navigator subtree by the accent index forces a fresh build
      // against the new colours. Navigation STATE lives in the go_router delegate
      // (stable routerProvider), so the current route is preserved; only in-page
      // state resets — an acceptable, tidy reveal after a confirmed theme change.
      builder: (context, child) =>
          KeyedSubtree(key: ValueKey(accent), child: child!),
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
