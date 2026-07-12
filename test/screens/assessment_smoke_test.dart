import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kinex_app/data/assessment_session.dart';
import 'package:kinex_app/models/fitness_level.dart';
import 'package:kinex_app/models/person_info.dart';
import 'package:kinex_app/models/test_results.dart';
import 'package:kinex_app/screens/assessment/assessment_landing_page.dart';
import 'package:kinex_app/screens/assessment/assessment_intro_page.dart';
import 'package:kinex_app/screens/assessment/bmi_result_page.dart';
import 'package:kinex_app/screens/assessment/progress_overview_page.dart';
import 'package:kinex_app/screens/assessment/final_summary_page.dart';

/// These pump the pure-Flutter screens to catch runtime build errors that
/// static analysis misses (layout asserts, null result casts).
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  /// A complete SPPB session: balance 3/4, gait 3/4, chair 4/4 → total 10 (Low).
  ProviderContainer seededContainer() {
    final c = ProviderContainer();
    final n = c.read(assessmentSessionProvider.notifier);
    n.setPerson(const PersonInfo(name: 'ทดสอบ', age: 70, gender: Gender.male));
    n.setHeight(const MeasurementResult(170, 'cm'));
    n.setWeight(const MeasurementResult(70, 'kg'));
    n.setBmi(const BmiResult(24.2, BmiBand.namnakKoen));
    n.setBalance(const BalanceResult(
      sideBySideSec: 10,
      semiTandemSec: 10,
      tandemSec: 5, // 3–9.99s → +1  ⇒ 1+1+1 = 3
      points: 3,
    ));
    n.setGait(const GaitResult(seconds: 5.5, unable: false, points: 3));
    n.setChairStand(
        const ChairStandResult(preTestPassed: true, seconds: 10.0, points: 4));
    return c;
  }

  Future<void> pump(WidgetTester tester, ProviderContainer c, Widget w) async {
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(home: w),
    ));
    await tester.pump();
  }

  testWidgets('Landing renders', (tester) async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await pump(tester, c, const AssessmentLandingPage());
    expect(find.text('เริ่มการประเมินใหม่'), findsOneWidget);
  });

  testWidgets('Intro renders', (tester) async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await pump(tester, c, const AssessmentIntroPage());
    expect(find.text('เริ่มเลย'), findsOneWidget);
  });

  testWidgets('BMI result renders a seeded value', (tester) async {
    final c = seededContainer();
    addTearDown(c.dispose);
    await pump(tester, c, const BmiResultPage());
    expect(find.textContaining('24.2'), findsOneWidget);
  });

  testWidgets('Progress overview renders with results', (tester) async {
    final c = seededContainer();
    addTearDown(c.dispose);
    await pump(tester, c, const ProgressOverviewPage());
    expect(find.text('ดูสรุปผล'), findsOneWidget);
  });

  testWidgets('Final summary shows the SPPB total and risk verdict',
      (tester) async {
    final c = seededContainer();
    addTearDown(c.dispose);
    await pump(tester, c, const FinalSummaryPage());
    expect(find.text('บันทึกผล'), findsOneWidget);
    expect(find.text('10'), findsOneWidget); // 3 + 3 + 4 = 10
    expect(find.text('Low Risk'), findsWidgets); // hero + highlighted card
  });
}
