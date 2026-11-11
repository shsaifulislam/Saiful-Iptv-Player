import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saiful_iptv_player/features/profile/presentation/profile_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders unauthenticated state when not signed in', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ProviderScope(
            child: ProfilePage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Account & Cloud Sync'), findsOneWidget);
    expect(find.text('Sign In or Register'), findsOneWidget);
    expect(
      find.text('Playback and local playlists work offline without an account.'),
      findsOneWidget,
    );
  });
}

