import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/root_shell.dart';
import 'screens/start_page.dart';
import 'screens/login_page.dart';
import 'screens/home_page.dart';
import 'screens/practice_page.dart';
import 'screens/quest_page.dart';
import 'screens/info_page.dart';
import 'screens/settings_page.dart';
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
import 'screens/world/world_hero_page.dart';
import 'screens/world/world_game_screen.dart';
import 'screens/world/world_result_page.dart';
import 'screens/world/world_history_page.dart';
import 'screens/world/world_history_detail_page.dart';
import 'screens/emg/emg_pin_page.dart';
import 'screens/emg/emg_detail_page.dart';
import 'screens/onboarding/hardware_guide_page.dart';
import 'screens/debug/ble_debug_page.dart';
import 'models/world_session_record.dart';

final routerProvider = Provider<GoRouter>((ref) => GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, _) => const StartPage()),
        GoRoute(path: '/login', builder: (context, _) => const LoginPage()),
        // EMG detail behind a 6-digit gate (full-screen, outside the nav shell).
        GoRoute(path: '/emg/pin', builder: (context, _) => const EmgPinPage()),
        GoRoute(path: '/emg/detail', builder: (context, _) => const EmgDetailPage()),
        // EMG hardware-install guide popup (full-screen, shown on every app entry).
        GoRoute(
            path: '/hardware-guide',
            builder: (context, _) => const HardwareGuidePage()),
        // BLE debug console (connect / send / receive with the ESP32).
        GoRoute(
            path: '/ble-debug', builder: (context, _) => const BleDebugPage()),
        ShellRoute(
          builder: (context, state, child) => RootShell(child: child),
          routes: [
            GoRoute(path: '/home', builder: (context, _) => const HomePage()),
            GoRoute(path: '/practice', builder: (context, _) => const PracticePage()),
            GoRoute(path: '/quest', builder: (context, _) => const QuestPage()),
            GoRoute(path: '/info', builder: (context, _) => const InfoPage()),
            GoRoute(
                path: '/settings', builder: (context, _) => const SettingsPage()),
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
            // Kinex World — instructor-led exercise class (Unity-embedded session).
            GoRoute(
                path: '/world',
                builder: (context, _) => const WorldHeroPage()),
            GoRoute(
                path: '/world/game/:routineId',
                builder: (context, state) => WorldGameScreen(
                    routineId: state.pathParameters['routineId']!)),
            GoRoute(
                path: '/world/result',
                builder: (context, state) => WorldResultPage(
                    record: state.extra as WorldSessionRecord?)),
            GoRoute(
                path: '/world/history',
                builder: (context, _) => const WorldHistoryPage()),
            GoRoute(
                path: '/world/history/:recordId',
                builder: (context, state) => WorldHistoryDetailPage(
                    recordId: state.pathParameters['recordId']!)),
          ],
        ),
      ],
    ));
