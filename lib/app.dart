import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/api/providers.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/server_setup_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/sessions/sessions_screen.dart';
import 'features/sessions/session_detail_screen.dart';
import 'features/sessions/create_session_screen.dart';
import 'features/sessions/smart_session_wizard_screen.dart';
import 'features/conversation/conversation_screen.dart';
import 'features/approvals/approvals_screen.dart';
import 'features/approvals/approval_detail_screen.dart';
import 'features/questions/questions_screen.dart';
import 'features/proof/proof_screen.dart';
import 'features/proof/proof_detail_screen.dart';
import 'features/tokens/tokens_screen.dart';
import 'features/providers/providers_screen.dart';
import 'features/computer_actions/computer_actions_screen.dart';
import 'features/screenshots/screenshots_screen.dart';
import 'features/screenshots/screenshot_detail_screen.dart';
import 'features/ui_tests/ui_tests_screen.dart';
import 'features/settings/settings_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final isConfigured = ref.watch(isConfiguredProvider);
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: isConfigured ? '/dashboard' : '/setup',
    redirect: (context, state) {
      final configured = ref.read(isConfiguredProvider);
      if (!configured && state.matchedLocation != '/setup') {
        return '/setup';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/setup',
        builder: (context, state) => const ServerSetupScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/sessions',
            builder: (context, state) => const SessionsScreen(),
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) => const CreateSessionScreen(),
              ),
              GoRoute(
                path: 'smart-create',
                builder: (context, state) => const SmartSessionWizardScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    SessionDetailScreen(sessionId: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'conversation',
                    builder: (context, state) =>
                        ConversationScreen(sessionId: state.pathParameters['id']!),
                  ),
                  GoRoute(
                    path: 'proof',
                    builder: (context, state) =>
                        ProofScreen(sessionId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/approvals',
            builder: (context, state) => const ApprovalsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    ApprovalDetailScreen(approvalId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/questions',
            builder: (context, state) => const QuestionsScreen(),
          ),
          GoRoute(
            path: '/proof',
            builder: (context, state) => const ProofScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    ProofDetailScreen(proofId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/tokens',
            builder: (context, state) => const TokensScreen(),
          ),
          GoRoute(
            path: '/providers',
            builder: (context, state) => const ProvidersScreen(),
          ),
          GoRoute(
            path: '/computer-actions',
            builder: (context, state) => const ComputerActionsScreen(),
          ),
          GoRoute(
            path: '/screenshots',
            builder: (context, state) => const ScreenshotsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    ScreenshotDetailScreen(screenshotId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/ui-tests',
            builder: (context, state) => const UiTestsScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});

class EternalShiftApp extends ConsumerWidget {
  const EternalShiftApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Eternal Shift',
      theme: AppTheme.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  static const _destinations = [
    (path: '/dashboard', icon: Icons.home_rounded, label: 'Dashboard'),
    (path: '/sessions', icon: Icons.layers_rounded, label: 'Sessions'),
    (path: '/approvals', icon: Icons.approval_rounded, label: 'Approvals'),
    (path: '/questions', icon: Icons.help_outline_rounded, label: 'Questions'),
    (path: '/settings', icon: Icons.settings_rounded, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
          context.go(_destinations[index].path);
        },
        destinations: _destinations
            .map((d) => NavigationDestination(
                  icon: Icon(d.icon),
                  label: d.label,
                ))
            .toList(),
      ),
    );
  }
}
