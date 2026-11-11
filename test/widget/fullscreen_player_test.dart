import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saiful_iptv_player/features/playback/presentation/fullscreen_player_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders fullscreen player and controls', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: FullscreenPlayerPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PLAYBACK ACTIVE'), findsOneWidget);
    expect(find.text('Al Jazeera English HD (1080p 60fps)'), findsOneWidget);
    expect(find.byIcon(Icons.replay_10_rounded), findsOneWidget);
    expect(find.byIcon(Icons.forward_10_rounded), findsOneWidget);
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
  });
}

