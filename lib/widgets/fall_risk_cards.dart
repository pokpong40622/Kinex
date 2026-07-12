import 'package:flutter/material.dart';
import '../models/fall_risk.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';

/// Colours for the three fall-risk bands (from the interpretation slide).
Color fallRiskColor(FallRisk risk) => switch (risk) {
      FallRisk.high => const Color(0xFFA6342B), // deep red
      FallRisk.moderate => const Color(0xFFB08A2E), // gold
      FallRisk.low => const Color(0xFF2E7D52), // green
    };

/// Small rounded pill showing a fall-risk band (history list, home).
class FallRiskBadge extends StatelessWidget {
  final FallRisk risk;
  final double fontSize;
  const FallRiskBadge(this.risk, {super.key, this.fontSize = 16});

  @override
  Widget build(BuildContext context) {
    final c = fallRiskColor(risk);
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: fontSize, vertical: fontSize * 0.4),
      decoration: BoxDecoration(
        color: c.withAlpha(28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c, width: 1.5),
      ),
      child: Text(risk.thaiShort,
          style: thaiSans(size: fontSize, weight: FontWeight.w800, color: c)),
    );
  }
}

/// Big hero: the 0–12 total in a coloured circle + the risk verdict + meaning.
class FallRiskHero extends StatelessWidget {
  final int total;
  final FallRisk risk;
  const FallRiskHero({super.key, required this.total, required this.risk});

  @override
  Widget build(BuildContext context) {
    final c = fallRiskColor(risk);
    final d = context.r(140);
    return Container(
      width: double.infinity,
      padding:
          EdgeInsets.symmetric(vertical: context.r(24), horizontal: context.r(16)),
      decoration: cardDecoration(),
      child: Column(
        children: [
          Text('คะแนนรวม SPPB',
              style: thaiSans(size: context.r(16), weight: FontWeight.w700)),
          SizedBox(height: context.r(12)),
          Container(
            width: d,
            height: d,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$total',
                    style: thaiSans(
                        size: context.r(52),
                        weight: FontWeight.w900,
                        color: Colors.white)),
                Text('จาก 12 คะแนน',
                    style: thaiSans(
                        size: context.r(13),
                        weight: FontWeight.w700,
                        color: Colors.white)),
              ],
            ),
          ),
          SizedBox(height: context.r(14)),
          Text(risk.englishLabel,
              style: thaiSans(
                  size: context.r(20), weight: FontWeight.w800, color: c)),
          Text(risk.thaiLabel,
              style: thaiSans(size: context.r(18), weight: FontWeight.w800)),
          SizedBox(height: context.r(8)),
          Text(risk.thaiDescription,
              textAlign: TextAlign.center,
              style: thaiSans(
                  size: context.r(14),
                  weight: FontWeight.w600,
                  color: KColors.navyText.withAlpha(180))),
        ],
      ),
    );
  }
}

/// The three interpretation cards (High / Moderate / Low), stacked, with the
/// participant's band highlighted — mirrors the reference slide.
class FallRiskCards extends StatelessWidget {
  final FallRisk active;
  const FallRiskCards({super.key, required this.active});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final r in FallRisk.values)
          Padding(
            padding: EdgeInsets.only(bottom: context.r(10)),
            child: _RiskCard(risk: r, active: r == active),
          ),
      ],
    );
  }
}

class _RiskCard extends StatelessWidget {
  final FallRisk risk;
  final bool active;
  const _RiskCard({required this.risk, required this.active});

  @override
  Widget build(BuildContext context) {
    final c = fallRiskColor(risk);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.r(14)),
      decoration: BoxDecoration(
        color: active ? c.withAlpha(22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: active ? c : const Color(0x22000000),
            width: active ? 2 : 1),
      ),
      child: Row(
        children: [
          Container(
            width: context.r(64),
            height: context.r(64),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? c : c.withAlpha(120),
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(risk.scoreRange,
                    style: thaiSans(
                        size: context.r(15),
                        weight: FontWeight.w900,
                        color: Colors.white)),
                Text('คะแนน',
                    style: thaiSans(
                        size: context.r(9),
                        weight: FontWeight.w700,
                        color: Colors.white)),
              ],
            ),
          ),
          SizedBox(width: context.r(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${risk.englishLabel} · ${risk.thaiLabel}',
                    style: thaiSans(
                        size: context.r(15),
                        weight: FontWeight.w800,
                        color: c)),
                SizedBox(height: context.r(2)),
                Text(risk.thaiDescription,
                    style: thaiSans(
                        size: context.r(12.5),
                        weight: FontWeight.w600,
                        color: KColors.navyText.withAlpha(170))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
