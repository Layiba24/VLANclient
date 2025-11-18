import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vlc/main.dart';

void main() {
  testWidgets('VLC Clone App basic test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
  await tester.pumpWidget(const MyApp());

    // Verify that the VLC title is displayed
    expect(find.text('VLC Media Player'), findsOneWidget);

    // Verify basic control buttons are present
    expect(find.byIcon(Icons.play_circle_filled), findsWidgets);
    expect(find.byIcon(Icons.skip_previous), findsOneWidget);
    expect(find.byIcon(Icons.skip_next), findsOneWidget);
    expect(find.byIcon(Icons.stop), findsOneWidget);

    // Verify menu items are present
    expect(find.text('Media'), findsOneWidget);
    expect(find.text('Playback'), findsOneWidget);
    expect(find.text('Audio'), findsOneWidget);
    expect(find.text('Video'), findsOneWidget);
  });
}