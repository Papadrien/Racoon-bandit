import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raccoon_bandit/app.dart';

void main() {
  testWidgets('HomeScreen affiche le logo et le bouton Jouer', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const RaccoonBanditApp());
    expect(find.text('RACCOON'), findsOneWidget);
    expect(find.text('BANDIT'), findsOneWidget);
    expect(find.text('JOUER'), findsOneWidget);
  });
}
