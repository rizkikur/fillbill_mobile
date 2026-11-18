import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fillbill_mobile/app/main_nav_shell.dart';
import 'package:fillbill_mobile/core/config/app_config.dart';
import 'package:fillbill_mobile/core/theme/app_colors.dart';

// ============================================================================
// HERMETIC TEST HARNESS & DUMMY BRANCH PAGES
// ============================================================================

class StatePreservationTestWidget extends StatefulWidget {
  final String title;
  const StatePreservationTestWidget({super.key, required this.title});

  @override
  State<StatePreservationTestWidget> createState() => _StatePreservationTestWidgetState();
}

class _StatePreservationTestWidgetState extends State<StatePreservationTestWidget> {
  int counter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${widget.title} Screen'),
            Text('Counter: $counter', key: Key('${widget.title}_counter')),
            ElevatedButton(
              key: Key('${widget.title}_increment'),
              onPressed: () => setState(() => counter++),
              child: const Text('Increment'),
            ),
          ],
        ),
      ),
    );
  }
}

GoRouter createShellTestRouter({
  String initialLocation = '/home',
}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainNavShell(
            navigationShell: navigationShell,
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const StatePreservationTestWidget(title: 'Home'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/transactions',
                builder: (context, state) => const StatePreservationTestWidget(title: 'Riwayat'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/wallet',
                builder: (context, state) => const StatePreservationTestWidget(title: 'Dompet'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const StatePreservationTestWidget(title: 'Profil'),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

Widget createShellTestApp({required GoRouter router}) {
  return ProviderScope(
    child: MaterialApp.router(
      routerConfig: router,
    ),
  );
}

// ============================================================================
// MAIN TEST SUITE
// ============================================================================

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
    AppConfig.initialize(AppConfig.dev());
  });

  group('MainNavShell Automated Widget Test Suite', () {
    // ------------------------------------------------------------------------
    // 1. Rendering of all tabs and FAB
    // ------------------------------------------------------------------------
    testWidgets('Renders navigation bar, all 4 tabs, and center FAB', (tester) async {
      final router = createShellTestRouter();
      await tester.pumpWidget(createShellTestApp(router: router));
      await tester.pumpAndSettle();

      // Navigation Bar
      expect(find.byKey(const Key('nav_bar')), findsOneWidget);

      // Positional Keys
      expect(find.byKey(const Key('nav_tab_0')), findsOneWidget);
      expect(find.byKey(const Key('nav_tab_1')), findsOneWidget);
      expect(find.byKey(const Key('nav_tab_2')), findsOneWidget);
      expect(find.byKey(const Key('nav_tab_3')), findsOneWidget);

      // Center FAB
      expect(find.byKey(const Key('nav_fab')), findsOneWidget);

      // Semantic Labels
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Riwayat'), findsOneWidget);
      expect(find.text('Dompet'), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);
    });

    // ------------------------------------------------------------------------
    // 2. Active Tab 0 initial state & Pill styling
    // ------------------------------------------------------------------------
    testWidgets('Initial active tab is Tab 0 with neo-green styling and visible Home content', (tester) async {
      final router = createShellTestRouter();
      await tester.pumpWidget(createShellTestApp(router: router));
      await tester.pumpAndSettle();

      // Content of Branch 0 is rendered
      expect(find.text('Home Screen'), findsOneWidget);
      expect(find.text('Riwayat Screen'), findsNothing);

      // Tab 0 has active soft pill container (neoGreenSurface)
      final pillContainers = tester.widgetList<AnimatedContainer>(find.byType(AnimatedContainer));
      final hasActivePill = pillContainers.any((c) {
        final decoration = c.decoration;
        return decoration is BoxDecoration && decoration.color == AppColors.neoGreenSurface;
      });
      expect(hasActivePill, isTrue, reason: 'Active tab must render neoGreenSurface pill background');
    });

    // ------------------------------------------------------------------------
    // 3. Tab switching across all branches
    // ------------------------------------------------------------------------
    testWidgets('Switches branches smoothly to Tab 1, 2, 3, and back to 0', (tester) async {
      final router = createShellTestRouter();
      await tester.pumpWidget(createShellTestApp(router: router));
      await tester.pumpAndSettle();

      // Switch to Tab 1 (Riwayat)
      await tester.tap(find.byKey(const Key('nav_tab_1')));
      await tester.pumpAndSettle();
      expect(find.text('Riwayat Screen'), findsOneWidget);

      // Switch to Tab 2 (Dompet)
      await tester.tap(find.byKey(const Key('nav_tab_2')));
      await tester.pumpAndSettle();
      expect(find.text('Dompet Screen'), findsOneWidget);

      // Switch to Tab 3 (Profil)
      await tester.tap(find.byKey(const Key('nav_tab_3')));
      await tester.pumpAndSettle();
      expect(find.text('Profil Screen'), findsOneWidget);

      // Switch back to Tab 0 (Home)
      await tester.tap(find.byKey(const Key('nav_tab_0')));
      await tester.pumpAndSettle();
      expect(find.text('Home Screen'), findsOneWidget);
    });

    // ------------------------------------------------------------------------
    // 4. Shell state preservation across tab switches
    // ------------------------------------------------------------------------
    testWidgets('Preserves widget state across tab switches (IndexedStack fidelity)', (tester) async {
      final router = createShellTestRouter();
      await tester.pumpWidget(createShellTestApp(router: router));
      await tester.pumpAndSettle();

      // Mutate state in Home: Counter 0 -> 1 -> 2
      expect(find.text('Counter: 0'), findsOneWidget);
      await tester.tap(find.byKey(const Key('Home_increment')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('Home_increment')));
      await tester.pumpAndSettle();
      expect(find.text('Counter: 2'), findsOneWidget);

      // Navigate to Tab 1 (Riwayat)
      await tester.tap(find.byKey(const Key('nav_tab_1')));
      await tester.pumpAndSettle();
      expect(find.text('Riwayat Screen'), findsOneWidget);

      // Mutate state in Riwayat: Counter 0 -> 1
      await tester.tap(find.byKey(const Key('Riwayat_increment')));
      await tester.pumpAndSettle();
      expect(find.text('Counter: 1'), findsOneWidget);

      // Navigate back to Tab 0 (Home)
      await tester.tap(find.byKey(const Key('nav_tab_0')));
      await tester.pumpAndSettle();

      // Home state MUST be preserved (Counter still 2!)
      expect(find.text('Counter: 2'), findsOneWidget);

      // Return to Tab 1 (Riwayat) - Riwayat state MUST still be 1!
      await tester.tap(find.byKey(const Key('nav_tab_1')));
      await tester.pumpAndSettle();
      expect(find.text('Counter: 1'), findsOneWidget);
    });

    // ------------------------------------------------------------------------
    // 5. Semantic Keys Accessibility
    // ------------------------------------------------------------------------
    testWidgets('Tapping semantic keys nav_tab_home, nav_tab_history, nav_tab_wallet, nav_tab_profile switches branches', (tester) async {
      final router = createShellTestRouter();
      await tester.pumpWidget(createShellTestApp(router: router));
      await tester.pumpAndSettle();

      // Tap semantic history
      expect(find.byKey(const Key('nav_tab_history')), findsOneWidget);
      await tester.tap(find.byKey(const Key('nav_tab_history')));
      await tester.pumpAndSettle();
      expect(find.text('Riwayat Screen'), findsOneWidget);

      // Tap semantic wallet
      expect(find.byKey(const Key('nav_tab_wallet')), findsOneWidget);
      await tester.tap(find.byKey(const Key('nav_tab_wallet')));
      await tester.pumpAndSettle();
      expect(find.text('Dompet Screen'), findsOneWidget);

      // Tap semantic profile
      expect(find.byKey(const Key('nav_tab_profile')), findsOneWidget);
      await tester.tap(find.byKey(const Key('nav_tab_profile')));
      await tester.pumpAndSettle();
      expect(find.text('Profil Screen'), findsOneWidget);

      // Tap semantic home
      expect(find.byKey(const Key('nav_tab_home')), findsOneWidget);
      await tester.tap(find.byKey(const Key('nav_tab_home')));
      await tester.pumpAndSettle();
      expect(find.text('Home Screen'), findsOneWidget);
    });

    // ------------------------------------------------------------------------
    // 6. FAB tap behavior (Modal trigger without altering shell branch)
    // ------------------------------------------------------------------------
    testWidgets('Tapping nav_fab does not change active branch index', (tester) async {
      final router = createShellTestRouter();
      await tester.pumpWidget(createShellTestApp(router: router));
      await tester.pumpAndSettle();

      // Start on Home
      expect(find.text('Home Screen'), findsOneWidget);

      // Tap FAB
      await tester.tap(find.byKey(const Key('nav_fab')));
      await tester.pumpAndSettle();

      // Home screen remains current branch behind modal/sheet
      expect(find.text('Home Screen'), findsOneWidget);
    });

    // ------------------------------------------------------------------------
    // 7. Tab 3 Label & Icon synchronization verification
    // ------------------------------------------------------------------------
    testWidgets('Tab 3 displays "Profil" with person icon and no legacy "Menu"', (tester) async {
      final router = createShellTestRouter();
      await tester.pumpWidget(createShellTestApp(router: router));
      await tester.pumpAndSettle();

      expect(find.text('Profil'), findsOneWidget);
      expect(find.text('Menu'), findsNothing);
      expect(find.byIcon(Icons.tune_rounded), findsNothing);
      expect(
        find.byWidgetPredicate((widget) =>
            widget is Icon &&
            (widget.icon == Icons.person_outline_rounded ||
                widget.icon == Icons.person_rounded ||
                widget.icon == Icons.person_outline ||
                widget.icon == Icons.person)),
        findsWidgets,
      );
    });
  });
}
