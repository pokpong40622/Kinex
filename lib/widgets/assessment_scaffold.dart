import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';

/// Shared chrome for every fitness-assessment screen: a soft healthcare
/// background, a large back button, a Thai title, the body, and an optional
/// pinned bottom action area. Built for elderly readability — big touch
/// targets, high contrast, large Thai text.
class AssessmentScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final VoidCallback? onBack;
  final Widget? bottom;

  /// Optional slim progress rail shown just under the header (in-test screens).
  final Widget? progress;

  /// Optional "step X of Y" dots, shown under the header when [progress] is
  /// not supplied (e.g. the body-measurement intake screens: person → height
  /// → weight → BMI). 0-based index.
  final int? stepIndex;
  final int? stepCount;

  const AssessmentScaffold({
    super.key,
    required this.title,
    required this.body,
    this.onBack,
    this.bottom,
    this.progress,
    this.stepIndex,
    this.stepCount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KColors.appBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(context.r(16), context.r(14), context.r(16), context.r(10)),
              child: Row(
                children: [
                  _BackButton(onTap: onBack ?? () => _defaultBack(context)),
                  SizedBox(width: context.r(14)),
                  Expanded(
                    child: Text(
                      title,
                      style: thaiSans(
                          size: context.r(22), weight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
            if (progress != null)
              Padding(
                padding: EdgeInsets.fromLTRB(context.r(20), context.r(4), context.r(20), context.r(14)),
                child: progress!,
              )
            else if (stepIndex != null && stepCount != null)
              Padding(
                padding: EdgeInsets.fromLTRB(context.r(20), context.r(2), context.r(20), context.r(14)),
                child: _StepDots(index: stepIndex!, count: stepCount!),
              ),
            Expanded(child: body),
            if (bottom != null)
              Padding(
                padding: EdgeInsets.fromLTRB(context.r(16), context.r(8), context.r(16), context.r(16)),
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
        width: context.r(48),
        height: context.r(48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: KColors.hairline, width: 1),
        ),
        child: Icon(Icons.arrow_back_rounded, size: context.r(24), color: KColors.navyText),
      ),
    );
  }
}

/// Compact "step X of Y" indicator: a row of pill dots (current one wider)
/// plus a short Thai caption. Used by the body-measurement intake screens so
/// they carry the same "where am I" reassurance as the movement-test rail.
class _StepDots extends StatelessWidget {
  final int index; // 0-based current step
  final int count;
  const _StepDots({required this.index, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < count; i++) ...[
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: i == index ? context.r(26) : context.r(8),
            height: context.r(8),
            decoration: BoxDecoration(
              color: i <= index ? KColors.teal : const Color(0xFFCBD5D1),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          if (i < count - 1) SizedBox(width: context.r(6)),
        ],
        SizedBox(width: context.r(10)),
        Text(
          'ขั้นที่ ${index + 1} จาก $count',
          style: thaiSans(
              size: context.r(13), weight: FontWeight.w700, color: KColors.tealDark),
        ),
      ],
    );
  }
}
