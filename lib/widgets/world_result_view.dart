import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/world_session_record.dart';
import '../theme/app_theme.dart';
import '../theme/responsive.dart';

/// Renders a completed Kinex World session: the Average Performance % hero, a
/// qualitative band, a per-exercise breakdown, an encouraging tip, and session
/// stats. Shared by the post-class result screen and the history detail screen.
class WorldResultView extends StatelessWidget {
  final WorldSessionRecord record;
  const WorldResultView({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final band = WorldBand.of(record.averagePercent);
    final weakest = record.weakest;

    return ListView(
      padding: EdgeInsets.fromLTRB(
          context.r(20), context.r(8), context.r(20), context.r(20)),
      children: [
        // ---- hero: Average Performance % ----
        Container(
          padding: EdgeInsets.symmetric(
              vertical: context.r(28), horizontal: context.r(16)),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: [
              Text('ผลการออกกำลังกายเฉลี่ย',
                  style: thaiSans(
                      size: context.r(16),
                      weight: FontWeight.w600,
                      color: Colors.white70)),
              SizedBox(height: context.r(6)),
              Text('${record.averagePercent.toStringAsFixed(0)}%',
                  style: montserrat(
                      size: context.r(72),
                      weight: FontWeight.w900,
                      color: Colors.white)),
              SizedBox(height: context.r(8)),
              _BandPill(label: band.thaiLabel, color: band.color),
            ],
          ),
        ),
        SizedBox(height: context.r(20)),

        // ---- per-exercise breakdown ----
        Text('รายละเอียดแต่ละท่า',
            style: thaiSans(
                size: context.r(18),
                weight: FontWeight.w800,
                color: Colors.white)),
        SizedBox(height: context.r(10)),
        ...record.exercises.map((e) => _ExerciseBar(score: e)),

        SizedBox(height: context.r(16)),

        // ---- encouraging tip ----
        if (weakest != null)
          Container(
            padding: EdgeInsets.all(context.r(16)),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.tips_and_updates_rounded,
                    color: KColors.orange, size: context.r(24)),
                SizedBox(width: context.r(10)),
                Expanded(
                  child: Text(
                    'คราวหน้าลองโฟกัสท่า “${weakest.name}” ให้มากขึ้นนะ',
                    style: thaiSans(
                        size: context.r(15),
                        weight: FontWeight.w600,
                        color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

        SizedBox(height: context.r(16)),

        // ---- stats ----
        _StatRow(
            label: 'วันที่',
            value: DateFormat('d MMM y · HH:mm').format(record.dateTime)),
        _StatRow(label: 'จำนวนท่า', value: '${record.exercises.length} ท่า'),
        _StatRow(label: 'เวลารวม', value: _fmtDuration(record.durationSeconds)),
      ],
    );
  }

  static String _fmtDuration(double seconds) {
    final s = seconds.round();
    final m = s ~/ 60;
    final r = s % 60;
    return '$m นาที ${r.toString().padLeft(2, '0')} วิ';
  }
}

class _BandPill extends StatelessWidget {
  final String label;
  final Color color;
  const _BandPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: context.r(20), vertical: context.r(8)),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(label,
          style: thaiSans(
              size: context.r(18),
              weight: FontWeight.w800,
              color: Colors.white)),
    );
  }
}

class _ExerciseBar extends StatelessWidget {
  final WorldExerciseScore score;
  const _ExerciseBar({required this.score});

  @override
  Widget build(BuildContext context) {
    final pct = (score.score / 100).clamp(0.0, 1.0);
    return Padding(
      padding: EdgeInsets.only(bottom: context.r(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(score.name,
                    style: montserrat(
                        size: context.r(14),
                        weight: FontWeight.w600,
                        color: Colors.white)),
              ),
              Text('${score.score.toStringAsFixed(0)}%',
                  style: montserrat(
                      size: context.r(14),
                      weight: FontWeight.w800,
                      color: Colors.white)),
            ],
          ),
          SizedBox(height: context.r(6)),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: context.r(10),
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFFB83FF4)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.r(6)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: thaiSans(
                  size: context.r(15),
                  weight: FontWeight.w600,
                  color: Colors.white70)),
          Text(value,
              style: thaiSans(
                  size: context.r(15),
                  weight: FontWeight.w700,
                  color: Colors.white)),
        ],
      ),
    );
  }
}
