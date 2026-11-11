import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saiful_iptv_player/app/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home navigation opens playlists', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: SaifulIPTVApp()));
    await tester.pumpAndSettle();

    expect(find.text('Your library'), findsOneWidget);
    await tester.tap(find.text('Playlists').first);
    await tester.pumpAndSettle();

    expect(find.text('No playlists yet'), findsOneWidget);
  });

  testWidgets('compact layout shows bottom navigation', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: SaifulIPTVApp()));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    await tester.tap(find.text('Live TV').last);
    await tester.pumpAndSettle();

    expect(find.text('PLAYLIST REQUIRED'), findsOneWidget);
  });

  testWidgets('playlist form rejects invalid URLs', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: SaifulIPTVApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Playlists').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add playlist'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'My channels');
    await tester.enterText(find.byType(TextFormField).at(1), 'not a URL');
    await tester.tap(find.text('Add').last);
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid HTTP or HTTPS URL'), findsOneWidget);
  });
}
