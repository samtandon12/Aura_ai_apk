import 'package:aura_ai/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AuraApp renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: AuraApp()));
    await tester.pump();
    expect(find.text('Aura AI'), findsWidgets);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 500));
  });
}
