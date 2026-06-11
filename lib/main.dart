import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app.dart';

void main() {
  // The clinic tablet runs offline, so never try to fetch fonts over the
  // network (it throws and spams the log every rebuild). Use bundled/system
  // fallbacks instead. Bundle the exact .ttf files later for pixel-perfect text.
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const ProviderScope(child: KinexApp()));
}
