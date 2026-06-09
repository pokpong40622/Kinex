import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/screen_provider.dart';

class GameScreenWrapper extends ConsumerStatefulWidget {
  final Widget child;
  const GameScreenWrapper({required this.child, super.key});

  @override
  ConsumerState<GameScreenWrapper> createState() => _GameScreenWrapperState();
}

class _GameScreenWrapperState extends ConsumerState<GameScreenWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(isGameScreenProvider.notifier).state = true;
    });
  }

  @override
  void dispose() {
    ref.read(isGameScreenProvider.notifier).state = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
