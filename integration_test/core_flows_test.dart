import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:schoolable/main.dart' as app;

const bool _runE2E = bool.fromEnvironment('E2E_RUN', defaultValue: false);
const String _email = String.fromEnvironment('E2E_EMAIL');
const String _password = String.fromEnvironment('E2E_PASSWORD');
final bool _shouldRun = _runE2E && _email.isNotEmpty && _password.isNotEmpty;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'login and navigate core tabs',
    (tester) async {
      debugPrint('E2E: start app');
      await app.main();
      await tester.pumpAndSettle();

      final hasLoginForm = tester.any(find.byType(TextField)) &&
          tester.any(find.widgetWithText(ElevatedButton, 'Sign In'));
      if (hasLoginForm) {
        debugPrint('E2E: login screen detected');
        await tester.enterText(find.byType(TextField).at(0), _email);
        await tester.enterText(find.byType(TextField).at(1), _password);
        await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
        await tester.pump(const Duration(seconds: 10));
        debugPrint('E2E: login submitted');
      } else {
        debugPrint('E2E: already logged in');
        await tester.pump(const Duration(seconds: 2));
      }

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Tasks'), findsOneWidget);
      expect(find.text('Check-in'), findsOneWidget);
      expect(find.text('Reports'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      final homeScroll = find.byType(CustomScrollView);
      Future<void> tryScrollTo(Finder target) async {
        if (!tester.any(homeScroll)) {
          return;
        }
        try {
          await tester.scrollUntilVisible(
            target,
            200,
            scrollable: homeScroll,
          );
          await tester.pumpAndSettle(const Duration(seconds: 2));
        } catch (_) {}
      }
      Future<void> tapBack() async {
        if (tester.any(find.byIcon(Icons.arrow_back_ios))) {
          await tester.tap(find.byIcon(Icons.arrow_back_ios).first);
          await tester.pump(const Duration(seconds: 2));
          return;
        }
        if (tester.any(find.byIcon(Icons.arrow_back))) {
          await tester.tap(find.byIcon(Icons.arrow_back).first);
          await tester.pump(const Duration(seconds: 2));
          return;
        }
        await tester.pageBack();
        await tester.pump(const Duration(seconds: 2));
      }

      if (tester.any(find.byIcon(Icons.notifications_outlined))) {
        debugPrint('E2E: open notifications');
        await tester.ensureVisible(find.byIcon(Icons.notifications_outlined));
        await tester.tap(find.byIcon(Icons.notifications_outlined));
        await tester.pump(const Duration(seconds: 5));
        expect(find.text('Notifications'), findsOneWidget);
        final hasNoNotifications = tester.any(find.text('No notifications'));
        final hasRecentUpdates = tester.any(find.text('Recent Updates'));
        final hasActionRequired = tester.any(find.text('Action Required'));
        expect(
          hasNoNotifications || hasRecentUpdates || hasActionRequired,
          isTrue,
        );
        if (!hasNoNotifications && tester.any(find.text('Announcement'))) {
          debugPrint('E2E: open announcement detail from notifications');
          await tester.tap(find.text('Announcement').first);
          await tester.pump(const Duration(seconds: 5));
          expect(find.text('Details'), findsWidgets);
          await tapBack();
        }
        if (hasActionRequired && tester.any(find.text('Tap to review'))) {
          debugPrint('E2E: open compliance detail from notifications');
          await tester.tap(find.text('Tap to review').first);
          await tester.pump(const Duration(seconds: 5));
          expect(find.text('Compliance Required'), findsWidgets);
          if (tester.any(find.text('Acknowledge'))) {
            await tester.tap(find.text('Acknowledge'));
            await tester.pump(const Duration(seconds: 5));
            expect(find.text('Compliance'), findsWidgets);
            await tapBack();
          } else {
            await tapBack();
          }
        }
        await tapBack();
      }

      debugPrint('E2E: announcements section');
      await tryScrollTo(find.text('Announcements'));
      if (tester.any(find.text('Announcements')) &&
          tester.any(find.text('Announcement'))) {
        await tester.tap(find.text('Announcement').first);
        await tester.pump(const Duration(seconds: 5));
        expect(find.text('Details'), findsWidgets);
        await tapBack();
      }

      debugPrint('E2E: compliance section');
      await tryScrollTo(find.text('See all'));
      if (tester.any(find.text('See all'))) {
        await tester.tap(find.text('See all'));
        await tester.pump(const Duration(seconds: 5));
        expect(find.text('Compliance'), findsWidgets);
        final hasNoCompliance = tester.any(find.text('No compliance items'));
        final hasComplianceItems = tester.any(find.text('Action Required'));
        expect(hasNoCompliance || hasComplianceItems, isTrue);
        await tapBack();
      }

      debugPrint('E2E: tasks tab');
      await tester.tap(find.text('Tasks'));
      await tester.pump(const Duration(seconds: 10));
      final hasTasksIntro =
          tester.any(find.text('Your workstream at a glance'));
      final hasNoTasks = tester.any(find.text('No tasks found'));
      final hasTaskMetrics = tester.any(find.text('In progress')) ||
          tester.any(find.text('Overdue')) ||
          tester.any(find.text('Done'));
      expect(hasTasksIntro || hasNoTasks || hasTaskMetrics, isTrue);

      if (tester.any(find.byIcon(Icons.search_rounded))) {
        debugPrint('E2E: tasks search');
        await tester.tap(find.byIcon(Icons.search_rounded).first);
        await tester.pump(const Duration(seconds: 5));
        expect(find.text('Search tasks'), findsOneWidget);
        await tapBack();
      }

      if (tester.any(find.byIcon(Icons.tune_rounded))) {
        debugPrint('E2E: tasks filter sheet');
        await tester.tap(find.byIcon(Icons.tune_rounded).first);
        await tester.pump(const Duration(seconds: 5));
        expect(find.text('Filter by status'), findsOneWidget);
        await tapBack();
      }

      debugPrint('E2E: check-in tab');
      await tester.tap(find.text('Check-in'));
      await tester.pump(const Duration(seconds: 10));
      expect(find.text('Check In'), findsWidgets);
      if (tester.any(find.byIcon(Icons.history))) {
        await tester.tap(find.byIcon(Icons.history));
        await tester.pump(const Duration(seconds: 5));
        expect(find.text('Attendance History'), findsOneWidget);
        await tapBack();
      }

      debugPrint('E2E: reports tab');
      await tester.tap(find.text('Reports'));
      await tester.pump(const Duration(seconds: 10));
      expect(find.text('Daily Reports'), findsWidgets);
      if (tester.any(find.byIcon(Icons.history_rounded))) {
        await tester.tap(find.byIcon(Icons.history_rounded));
        await tester.pump(const Duration(seconds: 5));
        expect(find.text('Report History'), findsOneWidget);
        await tapBack();
      }

      debugPrint('E2E: profile tab');
      await tester.tap(find.text('Profile'));
      await tester.pump(const Duration(seconds: 10));
      expect(find.text('Settings'), findsWidgets);
      if (tester.any(find.text('Security'))) {
        await tester.tap(find.text('Security'));
        await tester.pump(const Duration(seconds: 5));
        expect(find.text('Security'), findsWidgets);
        await tapBack();
      }

      if (tester.any(find.text('Apply for leave'))) {
        debugPrint('E2E: leave flow');
        await tester.ensureVisible(find.text('Apply for leave'));
        await tester.tap(find.text('Apply for leave'));
        await tester.pump(const Duration(seconds: 5));
        expect(find.text('Apply for Leave'), findsWidgets);
        await tapBack();
      }
      debugPrint('E2E: complete');
    },
    skip: !_shouldRun,
  );
}
