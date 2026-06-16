// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

import 'package:expense_tracker/data/models/expense_entity.dart';
import 'package:expense_tracker/data/repositories/expense_repository.dart';
import 'package:expense_tracker/main.dart';

void main() {
  testWidgets('Expense tracker app loads', (WidgetTester tester) async {
    final tempDir = await Directory.systemTemp.createTemp('expense_tracker_test');
    final isar = await Isar.open(
      [ExpenseEntitySchema],
      directory: tempDir.path,
      name: 'test',
    );

    addTearDown(() async {
      await isar.close(deleteFromDisk: true);
      await tempDir.delete(recursive: true);
    });

    await tester.pumpWidget(ProviderScope(
      overrides: [isarProvider.overrideWithValue(isar)],
      child: const ExpenseTrackerApp(),
    ));

    await tester.pumpAndSettle();

    expect(find.text('Expenses'), findsOneWidget);
  });
}
