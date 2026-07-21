import 'package:flutter/material.dart';
import '../data/content.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/kawaii_widgets.dart';
import '../widgets/pictogram_painter.dart';
import 'result_screen.dart';

class TrueFalseScreen extends StatefulWidget {
  final Topic topic;
  const TrueFalseScreen({super.key, required this.topic});

  @override
  State<TrueFalseScreen> createState() => _TrueFalseScreenState();
}

class _TrueFalseScreenState extends State<TrueFalseScreen> {
  late final List<TfQuestion> _questions = tfQuestions[widget.topic.id]!;
  int _index = 0;
  bool? _selected;
  int _correctCount = 0;

  TfQuestion get _q => _questions[_index];

  void _select(bool value) {
    if (_selected != null) return;
    setState(() {
      _selected = value;
      if (value == _q.correctAnswer) _correctCount++;
    });
  }

  void _next() {
    if (_index == _questions.length - 1) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            color: widget.topic.color,
            correctCount: _correctCount,
            total: _questions.length,
            onReplay: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => TrueFalseScreen(topic: widget.topic),
              ),
            ),
          ),
        ),
      );
      return;
    }
    setState(() {
      _index++;
      _selected = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.topic.color;
    final answered = _selected != null;
    final isCorrect = answered && _selected == _q.correctAnswer;

    return Scaffold(
      body: SafeArea(
        child: CenteredGameArea(
          maxWidth: 1000,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KawaiiTopBar(
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppColors.ink,
                          size: 34,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'ถูก หรือ ผิด · ${widget.topic.title.replaceAll('\n', ' ')}',
                          style: AppTheme.body(
                            size: 22,
                            weight: FontWeight.w700,
                            color: AppColors.inkLight,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        'ข้อ ${_index + 1} / ${_questions.length}',
                        style: AppTheme.body(
                          size: 22,
                          weight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: (_index + (answered ? 1 : 0)) / _questions.length,
                    minHeight: 12,
                    backgroundColor: color.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          KawaiiCard(
                            borderColor: color,
                            borderWidth: 9,
                            radius: 34,
                            padding: const EdgeInsets.all(30),
                            child: Column(
                              children: [
                                Container(
                                  width: 112,
                                  height: 112,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: PictogramIcon(
                                      type: _q.illustration,
                                      size: 74,
                                      accent: color,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _q.statement,
                                  textAlign: TextAlign.center,
                                  style: AppTheme.body(
                                    size: 28,
                                    weight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 34),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TrueFalseButton(
                                isTrue: true,
                                onTap: answered ? null : () => _select(true),
                                selected: _selected == true,
                                showAsCorrect:
                                    answered && _q.correctAnswer == true,
                              ),
                              const SizedBox(width: 34),
                              TrueFalseButton(
                                isTrue: false,
                                onTap: answered ? null : () => _select(false),
                                selected: _selected == false,
                                showAsCorrect:
                                    answered && _q.correctAnswer == false,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (answered)
                  FeedbackBanner(
                    correct: isCorrect,
                    message: isCorrect
                        ? 'เก่งมากค่ะ! ตอบถูกต้องเลย'
                        : 'ไม่เป็นไรนะคะ คำตอบที่ใช่คือ "${_q.correctAnswer ? 'ถูก' : 'ผิด'}"',
                    nextLabel: _index == _questions.length - 1
                        ? 'ดูผล'
                        : 'ข้อต่อไป',
                    onNext: _next,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
