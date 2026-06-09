import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/screen_provider.dart';
import 'unity_view.dart';

class RootShell extends ConsumerWidget {
  final Widget child;
  const RootShell({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGame = ref.watch(isGameScreenProvider);
    return Stack(
      children: [
        Offstage(offstage: !isGame, child: const UnityView()),
        child,
      ],
    );
  }
}
