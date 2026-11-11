import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saiful_iptv_player/features/home/presentation/home_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget createHomeScreen() {
    return const MaterialApp(
      home: Scaffold(
        body: ProviderScope(
          child: HomePage(),
        ),
      ),
    );
  }

  testWidgets('renders home screen with hero banner and carousels', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createHomeScreen());
    await tester.pumpAndSettle();

    expect(find.text('SAIFUL IPTV'), findsOneWidget);
    expect(find.text('Welcome to Saiful IPTV Player'), findsOneWidget);
    expect(find.text('Continue Watching'), findsOneWidget);
    expect(find.text('Live TV Channels'), findsOneWidget);
    expect(find.text('My Favorites'), findsOneWidget);
  });
}

