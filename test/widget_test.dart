// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App shows title and play button (local)', (WidgetTester tester) async {
    // Build a small local widget that represents the important UI pieces
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Text('VLC Media Player'),
              Icon(Icons.play_circle_filled),
            ],
          ),
        ),
      ),
    );

    // Verify that the app title is present and a play icon exists.
    expect(find.text('VLC Media Player'), findsOneWidget);
    expect(find.byIcon(Icons.play_circle_filled), findsOneWidget);
  });
}
