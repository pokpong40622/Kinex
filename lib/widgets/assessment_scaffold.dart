import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

/// Shared chrome for every fitness-assessment screen: a soft healthcare
/// background, a large back button, a Thai title, the body, and an optional
/// pinned bottom action area. Built for elderly readability — big touch
/// targets, high contrast, large Thai text.
class AssessmentScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final VoidCallback? onBack;
  final Widget? bottom;

  const AssessmentScaffold({
    super.key,
    required this.title,
    required this.body,
    this.onBack,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF6F4), // soft teal-tinted white
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  _BackButton(onTap: onBack ?? () => _defaultBack(context)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: thaiSans(size: 22, weight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: body),
            if (bottom != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: bottom!,
              ),
          ],
        ),
      ),
    );
  }

  void _defaultBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
                color: Color(0x22000000), blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: const Icon(Icons.arrow_back_rounded, color: KColors.navyText),
      ),
    );
  }
}
