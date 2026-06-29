import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Placeholder destination behind the 6-digit EMG gate. Intentionally blank
/// white for now (only a back affordance so the user can leave).
class EmgDetailPage extends StatelessWidget {
  const EmgDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topLeft,
          child: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.black54),
          ),
        ),
      ),
    );
  }
}
