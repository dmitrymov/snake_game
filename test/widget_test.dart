// Basic Flutter widget test for Snake Game.

import 'package:flutter_test/flutter_test.dart';

import 'package:snake_game/main.dart';

void main() {
  testWidgets('Snake Game app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SnakeGameApp());

    // Verify that the Snake Game title appears.
    expect(find.text('Snake Game'), findsOneWidget);
    
    // Verify that the Start Game button appears.
    expect(find.text('Start Game'), findsOneWidget);
    
    // Verify that initial score is 0.
    expect(find.text('0'), findsAtLeastNWidgets(1));
  });
}
