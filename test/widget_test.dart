// Basic Flutter widget test for Snake Game.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:snake_game/main.dart';
import 'package:snake_game/views/widgets/game_board.dart';

void main() {
  testWidgets('Snake Game app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SnakeGameApp());
    // Flame's GameWidget animates continuously; don't pumpAndSettle.
    await tester.pump(const Duration(milliseconds: 50));

    // Verify that the Settings action is present.
    expect(find.byIcon(Icons.settings), findsOneWidget);

    // Verify that the game board is shown.
    expect(find.byType(GameBoard), findsOneWidget);
  });
}
