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
import 'screens/mega_dance_first_pose.dart';
import 'screens/mega_dance_correct.dart';
import 'screens/mega_dance_game.dart';

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
            GoRoute(
                path: '/mega-dance/first-pose',
                builder: (context, _) => const MegaDanceFirstPosePage()),
            GoRoute(
                path: '/mega-dance/correct',
                builder: (context, _) => const MegaDanceCorrectPage()),
          ],
        ),
      ],
    ));
