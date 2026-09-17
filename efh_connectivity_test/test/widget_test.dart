import 'package:efh_connectivity_test/l10n/app_localizations.dart';
import 'package:efh_connectivity_test/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('localizations load for en and zh', () async {
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    expect(en.appTitle, 'Website Blocking Detection');
    expect(en.navDashboard, 'Check');

    final zh = await AppLocalizations.delegate.load(const Locale('zh'));
    expect(zh.appTitle, '网站屏蔽检测');
    expect(zh.navDashboard, '检测');
  });

  testWidgets('english locale renders english labels', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const EfhConnectivityApp(
        initialLocale: Locale('en'),
        warmUp: false,
        checkUpdates: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Website Blocking Detection'), findsOneWidget);
    expect(find.text('Check'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
  });

  testWidgets('wide layout shows the navigation rail and the dashboard', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const EfhConnectivityApp(
        initialLocale: Locale('zh'),
        warmUp: false,
        checkUpdates: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('网站屏蔽检测'), findsOneWidget);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('检测'), findsOneWidget);
    expect(find.text('开始'), findsOneWidget);
  });

  testWidgets('narrow layout switches between logs and settings', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const EfhConnectivityApp(
        initialLocale: Locale('zh'),
        warmUp: false,
        checkUpdates: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);

    await tester.tap(find.text('日志'));
    await tester.pumpAndSettle();
    expect(find.text('暂无结果'), findsOneWidget);

    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();
    expect(find.text('更新设置'), findsOneWidget);
  });
}
