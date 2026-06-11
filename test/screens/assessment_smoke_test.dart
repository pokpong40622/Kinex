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
/// static analysis misses (e.g. the dynamic `.level` casts, layout asserts).
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  ProviderContainer seededContainer() {
    final c = ProviderContainer();
    final n = c.read(assessmentSessionProvider.notifier);
    n.setPerson(const PersonInfo(name: 'ทดสอบ', age: 70, gender: Gender.male));
    n.setHeight(const MeasurementResult(170, 'cm'));
    n.setWeight(const MeasurementResult(70, 'kg'));
    n.setBmi(const BmiResult(24.2, BmiBand.namnakKoen));
    n.setBackScratch(const BestOfTwoResult(FitnessLevel.di));
    n.setSitAndReach(const BestOfTwoResult(FitnessLevel.dimak));
    n.setArmCurl(const RepCountResult(13, FitnessLevel.dimak));
    n.setChairStand(const RepCountResult(9, FitnessLevel.dimak));
    n.setStepTest(const RepCountResult(70, FitnessLevel.dimak));
    n.setTug(const TimedResult(10.5, FitnessLevel.dimak));
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

  testWidgets('Final summary computes overall and renders all results',
      (tester) async {
    final c = seededContainer();
    addTearDown(c.dispose);
    await pump(tester, c, const FinalSummaryPage());
    expect(find.text('บันทึกผล'), findsOneWidget);
  });
}
