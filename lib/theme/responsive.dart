import 'package:flutter/material.dart';

/// Device-consistent sizing. Values are authored against a 412dp-wide baseline
/// (a typical phone) and scaled to the current device width via MediaQuery, so
/// the UI keeps the same proportions on small phones and large tablets.
extension ResponsiveContext on BuildContext {
  Size get _screen => MediaQuery.sizeOf(this);

  /// Scale a baseline (412dp-width) dp value to this device. Clamped so it
  /// never gets absurdly small or large on extreme screens.
  double r(double baseline) =>
      baseline * (_screen.width / 412.0).clamp(0.85, 1.4);

  double get sw => _screen.width;
  double get sh => _screen.height;
}
