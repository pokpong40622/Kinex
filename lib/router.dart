import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/root_shell.dart';
import 'screens/start_page.dart';
import 'screens/login_page.dart';
import 'screens/home_page.dart';
import 'screens/practice_page.dart';
import 'screens/quest_page.dart';
import 'screens/info_page.dart';
import 'screens/mega_dance_start.dart';
import 'screens/mega_dance_game.dart';
import 'screens/assessment/assessment_landing_page.dart';
import 'screens/assessment/assessment_intro_page.dart';
import 'screens/assessment/person_info_page.dart';
import 'screens/assessment/height_input_page.dart';
import 'screens/assessment/weight_input_page.dart';
import 'screens/assessment/bmi_result_page.dart';
import 'screens/assessment/progress_overview_page.dart';
import 'screens/assessment/test_instruction_page.dart';
import 'screens/assessment/camera_calibration_page.dart';
import 'screens/assessment/live_assessment_page.dart';
import 'screens/assessment/manual_entry_page.dart';
import 'screens/assessment/test_result_page.dart';
import 'screens/assessment/final_summary_page.dart';
import 'screens/assessment/history_list_page.dart';
import 'screens/assessment/history_detail_page.dart';

final routerProvider = Provider<GoRouter>((ref) => GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, _) => const StartPage()),
        GoRoute(path: '/login', builder: (context, _) => const LoginPage()),
        ShellRoute(
          builder: (context, state, child) => RootShell(child: child),
          routes: [
            GoRoute(path: '/home', builder: (context, _) => const HomePage()),
            GoRoute(path: '/practice', builder: (context, _) => const PracticePage()),
            GoRoute(path: '/quest', builder: (context, _) => const QuestPage()),
            GoRoute(path: '/info', builder: (context, _) => const InfoPage()),
            GoRoute(
                path: '/mega-dance',
                builder: (context, _) => const MegaDanceStartPage()),
            // Real embedded Unity game (MEGA DANCE).
            GoRoute(
                path: '/mega-dance/game',
                builder: (context, _) => const MegaDanceGameScreen()),
            // Fitness-assessment module (pure Flutter). More routes added per phase.
            GoRoute(
                path: '/assessment',
                builder: (context, _) => const AssessmentLandingPage()),
            GoRoute(
                path: '/assessment/intro',
                builder: (context, _) => const AssessmentIntroPage()),
            GoRoute(
                path: '/assessment/person',
                builder: (context, _) => const PersonInfoPage()),
            GoRoute(
                path: '/assessment/height',
                builder: (context, _) => const HeightInputPage()),
            GoRoute(
                path: '/assessment/weight',
                builder: (context, _) => const WeightInputPage()),
            GoRoute(
                path: '/assessment/bmi',
                builder: (context, _) => const BmiResultPage()),
            GoRoute(
                path: '/assessment/progress',
                builder: (context, _) => const ProgressOverviewPage()),
            GoRoute(
                path: '/assessment/test/:testId/instructions',
                builder: (context, state) => TestInstructionPage(
                    testId: state.pathParameters['testId']!)),
            GoRoute(
                path: '/assessment/test/:testId/calibrate',
                builder: (context, state) => CameraCalibrationPage(
                    testId: state.pathParameters['testId']!)),
            GoRoute(
                path: '/assessment/test/:testId/live',
                builder: (context, state) =>
                    LiveAssessmentPage(testId: state.pathParameters['testId']!)),
            GoRoute(
                path: '/assessment/test/:testId/manual',
                builder: (context, state) =>
                    ManualEntryPage(testId: state.pathParameters['testId']!)),
            GoRoute(
                path: '/assessment/test/:testId/result',
                builder: (context, state) =>
                    TestResultPage(testId: state.pathParameters['testId']!)),
            GoRoute(
                path: '/assessment/summary',
                builder: (context, _) => const FinalSummaryPage()),
            GoRoute(
                path: '/assessment/history',
                builder: (context, _) => const HistoryListPage()),
            GoRoute(
                path: '/assessment/history/:recordId',
                builder: (context, state) => HistoryDetailPage(
                    recordId: state.pathParameters['recordId']!)),
          ],
        ),
      ],
    ));
