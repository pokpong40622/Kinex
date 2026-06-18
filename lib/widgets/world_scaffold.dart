import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';

/// Shared chrome for Kinex World screens: a deep-purple gameplay background
/// (same family as the Home World card), a large back button, a white title,
/// the body, and an optional pinned bottom action area.
class WorldScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final VoidCallback? onBack;
  final Widget? bottom;

  const WorldScaffold({
    super.key,
    required this.title,
    required this.body,
    this.onBack,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6F1BC8), Color(0xFF3B0A78)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                    context.r(16), context.r(12), context.r(16), context.r(8)),
                child: Row(
                  children: [
                    _BackButton(onTap: onBack ?? () => _defaultBack(context)),
                    SizedBox(width: context.r(12)),
                    Expanded(
                      child: Text(
                        title,
                        style: thaiSans(
                            size: context.r(22),
                            weight: FontWeight.w800,
                            color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: body),
              if (bottom != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(context.r(16), context.r(8),
                      context.r(16), context.r(16)),
                  child: bottom!,
                ),
            ],
          ),
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
        width: context.r(48),
        height: context.r(48),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(Icons.arrow_back_rounded,
            size: context.r(24), color: Colors.white),
      ),
    );
  }
}
