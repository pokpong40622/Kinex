import 'package:flutter/material.dart';
import 'mock_unity_view.dart';

const _kUseRealUnity = bool.fromEnvironment('USE_REAL_UNITY', defaultValue: false);

class UnityView extends StatelessWidget {
  const UnityView({super.key});

  @override
  Widget build(BuildContext context) {
    if (_kUseRealUnity) {
      // Stage 2: replace with real flutter_embed_unity widget
      return const SizedBox.expand();
    }
    return const MockUnityView();
  }
}
