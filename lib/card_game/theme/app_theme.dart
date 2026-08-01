import 'package:flutter/material.dart';

/// Warm, cheerful, low-pressure visual language for the whole app.
///
/// Note: the reference brief asks for a Baloo/Fredoka-style rounded font,
/// but those families don't ship Thai glyphs. Kanit is the closest rounded,
/// friendly, highly-legible Google Font with full Thai coverage, so it
/// stands in for Latin *and* Thai text everywhere.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFFCFFFF1);
  static const Color backgroundSoft = Color(0xFFE8FFF8);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF0876AD);
  static const Color inkLight = Color(0xFF4B91AD);

  static const Color lavender = Color(0xFF159FF0);
  static const Color lavenderDark = Color(0xFF0876C9);
  static const Color lavenderSoft = Color(0xFFDFF5FF);

  // Topic / mascot signature colors.
  static const Color teal = Color(0xFF13BFA7);
  static const Color skyBlue = Color(0xFF159FF0);
  static const Color sunYellow = Color(0xFFF5B900);
  static const Color orange = Color(0xFFFF7900);
  static const Color coralPink = Color(0xFFFF6F91);
  static const Color warmBrown = Color(0xFFD86A16);

  static const Color happyGreen = Color(0xFF70D900);
  static const Color gentleRed = Color(0xFFFF6B6B);

  static const List<Color> topicColors = [
    teal,
    skyBlue,
    sunYellow,
    orange,
    coralPink,
  ];
}

class AppTheme {
  AppTheme._();

  static const double _headingScale = 1.12;
  static const double _bodyScale = 1.18;

  static ThemeData get theme {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.lavender,
        brightness: Brightness.light,
        surface: AppColors.background,
      ),
      fontFamily: 'Kanit',
    );
    return base.copyWith(
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeThroughPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeThroughPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeThroughPageTransitionsBuilder(),
          TargetPlatform.windows: FadeThroughPageTransitionsBuilder(),
          TargetPlatform.linux: FadeThroughPageTransitionsBuilder(),
          TargetPlatform.fuchsia: FadeThroughPageTransitionsBuilder(),
        },
      ),
      textTheme: base.textTheme.apply(
        fontFamily: 'Kanit',
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      iconTheme: const IconThemeData(color: AppColors.ink),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        linearTrackColor: AppColors.lavenderSoft,
      ),
    );
  }

  static TextStyle heading({double size = 30, Color? color}) => TextStyle(
    fontFamily: 'Kanit',
    fontSize: size * _headingScale,
    fontWeight: FontWeight.w700,
    color: color ?? AppColors.ink,
    height: 1.25,
  );

  static TextStyle body({double size = 20, Color? color, FontWeight? weight}) =>
      TextStyle(
        fontFamily: 'Kanit',
        fontSize: size * _bodyScale,
        fontWeight: weight ?? FontWeight.w500,
        color: color ?? AppColors.ink,
        height: 1.3,
      );
}

class FadeThroughPageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeThroughPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    if (reduceMotion) return child;

    return AnimatedBuilder(
      animation: Listenable.merge([animation, secondaryAnimation]),
      child: child,
      builder: (context, child) {
        final incoming = _interval(
          animation.value,
          begin: 0.46,
          end: 1,
          curve: Curves.easeOutCubic,
        );
        final outgoing =
            1 -
            _interval(
              secondaryAnimation.value,
              begin: 0,
              end: 0.34,
              curve: Curves.easeOut,
            );
        return Opacity(opacity: incoming * outgoing, child: child);
      },
    );
  }

  double _interval(
    double value, {
    required double begin,
    required double end,
    required Curve curve,
  }) {
    if (value <= begin) return 0;
    if (value >= end) return 1;
    return curve.transform((value - begin) / (end - begin));
  }
}
