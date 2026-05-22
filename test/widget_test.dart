import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amal_app/main.dart';

void main() {
  testWidgets('App açılır', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: AmalApp()));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
