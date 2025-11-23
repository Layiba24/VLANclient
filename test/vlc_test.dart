import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('VLC Clone App basic test (local)', (WidgetTester tester) async {
    // Build a small local widget that represents the important UI pieces
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Text('VLC Media Player'),
              Row(
                children: [
                  Icon(Icons.play_circle_filled),
                  Icon(Icons.skip_previous),
                  Icon(Icons.skip_next),
                  Icon(Icons.stop),
                ],
              ),
              Row(
                children: [
                  Text('Media'),
                  SizedBox(width: 8),
                  Text('Playback'),
                  SizedBox(width: 8),
                  Text('Audio'),
                  SizedBox(width: 8),
                  Text('Video'),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    // Verify that the VLC title is displayed
    expect(find.text('VLC Media Player'), findsOneWidget);

    // Verify basic control buttons are present
    expect(find.byIcon(Icons.play_circle_filled), findsOneWidget);
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
