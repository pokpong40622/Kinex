import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';

/// Status of a single step in [StepProgressTracker].
enum StepStatus { done, current, pending }

/// One row in [StepProgressTracker].
class StepItem {
  final String label;
  final StepStatus status;
  final Widget? trailing;

  const StepItem({required this.label, required this.status, this.trailing});
}

/// Vertical checklist showing the assessment's overall progress: a circle per
/// step (done = filled teal check, current = teal ring, pending = grey ring
/// with its number), the step label, an optional trailing badge, and a
/// connector line between rows.
class StepProgressTracker extends StatelessWidget {
  final List<StepItem> items;

  const StepProgressTracker({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          _StepRow(
            item: items[i],
            number: i + 1,
            isLast: i == items.length - 1,
          ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  final StepItem item;
  final int number;
  final bool isLast;

  const _StepRow({
    required this.item,
    required this.number,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              _StepCircle(status: item.status, number: number),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: item.status == StepStatus.done
                        ? KColors.teal
                        : KColors.navyText.withAlpha(40),
                  ),
                ),
            ],
          ),
          SizedBox(width: context.r(14)),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: context.r(24)),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.label,
                      style: thaiSans(
                        size: context.r(16),
                        weight: item.status == StepStatus.current
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: item.status == StepStatus.pending
                            ? KColors.navyText.withAlpha(140)
                            : KColors.navyText,
                      ),
                    ),
                  ),
                  if (item.trailing != null) ...[
                    SizedBox(width: context.r(8)),
                    item.trailing!,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepCircle extends StatelessWidget {
  final StepStatus status;
  final int number;

  const _StepCircle({required this.status, required this.number});

  @override
  Widget build(BuildContext context) {
    final size = context.r(32);
    switch (status) {
      case StepStatus.done:
        return Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: KColors.teal,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check_rounded, color: Colors.white, size: context.r(20)),
        );
      case StepStatus.current:
        return Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: KColors.teal, width: 2.5),
          ),
          child: Text('$number',
              style: thaiSans(
                  size: context.r(14), weight: FontWeight.w800, color: KColors.teal)),
        );
      case StepStatus.pending:
        return Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: KColors.navyText.withAlpha(60), width: 2),
          ),
          child: Text('$number',
              style: thaiSans(
                  size: context.r(14),
                  weight: FontWeight.w700,
                  color: KColors.navyText.withAlpha(140))),
        );
    }
  }
}
