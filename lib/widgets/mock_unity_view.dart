import 'package:flutter/material.dart';

class MockUnityView extends StatelessWidget {
  const MockUnityView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.black,
      child: Center(
        child: Text(
          'Unity Player [Mock]',
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
      ),
    );
  }
}
