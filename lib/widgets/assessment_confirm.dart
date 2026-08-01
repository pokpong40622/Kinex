import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';
import 'assessment_button.dart';

/// Senior-sized confirm dialog for the assessment module: big tap targets,
/// matches [AssessmentButton] styling. Replaces ad-hoc [AlertDialog] confirms.
///
/// Returns `true` only if the user tapped the confirm button; back/barrier
/// dismiss and cancel both resolve to `false`.
Future<bool> showSeniorConfirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'ยืนยัน',
  String cancelLabel = 'ยกเลิก',
  bool danger = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.r(24)),
      ),
      child: Padding(
        padding: EdgeInsets.all(context.r(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: thaiSans(
                  size: context.r(20),
                  weight: FontWeight.w800,
                  color: KColors.navyText),
            ),
            SizedBox(height: context.r(12)),
            Text(
              message,
              textAlign: TextAlign.center,
              style: thaiSans(
                  size: context.r(16),
                  weight: FontWeight.w500,
                  color: KColors.darkText.withAlpha(180)),
            ),
            SizedBox(height: context.r(24)),
            if (danger)
              _DangerButton(
                label: confirmLabel,
                onTap: () => Navigator.of(context).pop(true),
              )
            else
              AssessmentButton(
                label: confirmLabel,
                onTap: () => Navigator.of(context).pop(true),
              ),
            SizedBox(height: context.r(12)),
            AssessmentButton(
              label: cancelLabel,
              primary: false,
              onTap: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    ),
  );

  return result ?? false;
}

/// Destructive-styled confirm button: same shape/size as [AssessmentButton]'s
/// primary look, but red — AssessmentButton itself has no color override.
class _DangerButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DangerButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: context.r(18)),
        decoration: BoxDecoration(
          color: const Color(0xFFD32F2F),
          borderRadius: BorderRadius.circular(context.r(18)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: thaiSans(
              size: context.r(20), weight: FontWeight.w800, color: Colors.white),
        ),
      ),
    );
  }
}
