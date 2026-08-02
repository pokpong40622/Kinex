import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Device-consistent sizing. Values are authored against a 412x915 baseline
/// (a typical phone) and scaled to the current device via MediaQuery, so the
/// UI keeps the same proportions on small phones, tall tablets, and short/wide
/// screens alike.
extension ResponsiveContext on BuildContext {
  Size get _screen => MediaQuery.sizeOf(this);

  /// Scale a baseline (412x915) dp value to this device. Uses whichever axis
  /// (width or height) is more constrained, so content that packs a fixed
  /// vertical budget (headers, carousels, CTAs) shrinks correctly on a short
  /// screen instead of overflowing. Clamped so it never gets absurdly small
  /// or large on extreme screens.
  double r(double baseline) {
    final wScale = _screen.width / 412.0;
    final hScale = _screen.height / 915.0;
    return baseline * math.min(wScale, hScale).clamp(0.85, 1.4);
  }

  /// Percent of screen width, e.g. `context.w(0.9)` for a 90%-wide page margin.
  double w(double fraction) => _screen.width * fraction;

  /// Percent of screen height, e.g. `context.h(0.3)` for a 30%-tall section.
  double h(double fraction) => _screen.height * fraction;

  /// True for tablets (shortest side >= 600dp), per Android's own convention.
  bool get isTablet => _screen.shortestSide >= 600;

  double get sw => _screen.width;
  double get sh => _screen.height;
}
