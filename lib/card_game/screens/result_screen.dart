import 'package:flutter/material.dart';
import '../services/daily_progress_store.dart';
import '../theme/app_theme.dart';
import '../widgets/kawaii_widgets.dart';

/// A soft, celebratory screen shown at the end of every round. There is no
/// "fail" state here on purpose — every attempt gets a warm, proud message.
class ResultScreen extends StatefulWidget {
  final Color color;
  final int correctCount;
  final int total;
  final VoidCallback onReplay;

  const ResultScreen({
    super.key,
    required this.color,
    required this.correctCount,
    required this.total,
    required this.onReplay,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late final int _earnedPoints = DailyProgressStore.pointsForScore(
    widget.correctCount,
  );
  DailyProgress? _progress;

  @override
  void initState() {
    super.initState();
    _savePoints();
  }

  Future<void> _savePoints() async {
    final progress = await DailyProgressStore.addQuizScore(widget.correctCount);
    if (!mounted) return;
    setState(() => _progress = progress);
  }

  String get _message {
    if (widget.total == 0 || widget.correctCount == widget.total) {
      return 'เก่งมากค่ะ! ทำได้ครบทุกข้อเลย';
    }
    if (widget.correctCount >= (widget.total / 2)) {
      return 'ทำได้ดีมากค่ะ วันนี้เรียนรู้เพิ่มขึ้นอีกแล้ว';
    }
    return 'ไม่เป็นไรค่ะ ลองใหม่ได้เรื่อยๆ ทุกครั้งคือการเรียนรู้';
  }

  int get _percent => widget.total == 0
      ? 100
      : ((widget.correctCount / widget.total) * 100).round();

  int get _stars {
    if (_percent >= 80) return 3;
    if (_percent >= 50) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 780),
                    child: Container(
                      margin: const EdgeInsets.all(24),
                      padding: const EdgeInsets.all(38),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .92),
                        borderRadius: BorderRadius.circular(38),
                        border: Border.all(color: Colors.white, width: 6),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.lavenderDark.withValues(
                              alpha: .16,
                            ),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'สรุปผลการเรียนรู้',
                            style: AppTheme.heading(
                              size: 30,
                              color: widget.color,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  SparkleBurst(show: true, color: widget.color),
                                  WigglingBuddy(
                                    active: true,
                                    size: 138,
                                    color: widget.color,
                                  ),
                                ],
                              ),
                              const SizedBox(width: 28),
                              Container(
                                width: 154,
                                height: 154,
                                decoration: BoxDecoration(
                                  color: widget.color.withValues(alpha: .12),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: widget.color,
                                    width: 10,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '$_percent%',
                                      style: AppTheme.heading(
                                        size: 38,
                                        color: widget.color,
                                      ),
                                    ),
                                    Text(
                                      'คะแนน',
                                      style: AppTheme.body(
                                        size: 20,
                                        weight: FontWeight.w700,
                                        color: AppColors.inkLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              3,
                              (i) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                child: Icon(
                                  Icons.star_rounded,
                                  size: 48,
                                  color: i < _stars
                                      ? AppColors.sunYellow
                                      : AppColors.inkLight.withValues(
                                          alpha: .18,
                                        ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _message,
                            textAlign: TextAlign.center,
                            style: AppTheme.heading(size: 34),
                          ),
                          const SizedBox(height: 10),
                          if (widget.total > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: widget.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(26),
                              ),
                              child: Text(
                                'ตอบถูก ${widget.correctCount} จาก ${widget.total} ข้อ',
                                style: AppTheme.body(
                                  size: 24,
                                  weight: FontWeight.w700,
                                  color: widget.color,
                                ),
                              ),
                            ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.happyGreen.withValues(
                                alpha: 0.14,
                              ),
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(
                                color: AppColors.happyGreen,
                                width: 5,
                              ),
                            ),
                            child: Text(
                              _progress == null
                                  ? 'กำลังเก็บแต้ม...'
                                  : 'ได้รับ $_earnedPoints แต้ม • วันนี้ ${_progress!.points} / ${_progress!.goal} แต้ม',
                              textAlign: TextAlign.center,
                              style: AppTheme.body(
                                size: 22,
                                weight: FontWeight.w800,
                                color: AppColors.happyGreen,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 14,
                            runSpacing: 14,
                            children: [
                              SoftButton(
                                label: 'เล่นอีกครั้ง',
                                color: widget.color,
                                icon: Icons.refresh_rounded,
                                onPressed: widget.onReplay,
                              ),
                              SoftButton(
                                label: 'เลือกโหมดอื่น',
                                color: widget.color,
                                filled: false,
                                icon: Icons.grid_view_rounded,
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  Navigator.of(context).pop();
                                },
                              ),
                              SoftButton(
                                label: 'กลับหน้าหลัก',
                                color: AppColors.warmBrown,
                                filled: false,
                                icon: Icons.home_rounded,
                                onPressed: () {
                                  Navigator.of(
                                    context,
                                  ).popUntil((route) => route.isFirst);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
