import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../models/expense.dart';
import '../models/expense_entity.dart';

final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError('Isar instance must be provided from main.dart');
});

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return ExpenseRepository(isar);
});

final expenseListProvider = StateNotifierProvider<ExpenseListNotifier, List<Expense>>((ref) {
  final repository = ref.watch(expenseRepositoryProvider);
  return ExpenseListNotifier(repository);
});

class ExpenseRepository {
  final Isar _isar;
  final _uuid = const Uuid();

  ExpenseRepository(this._isar);

  Future<List<Expense>> getAllExpenses() async {
    final collection = _isar.collection<ExpenseEntity>();
    final entities = await collection.where().findAll();
    return entities
        .map((entity) => Expense(
              id: entity.uid,
              title: entity.title,
              category: entity.category,
              amount: entity.amount,
              date: entity.date,
              notes: entity.notes,
              receiptPath: entity.receiptPath,
            ))
        .toList(growable: false);
  }

  Future<Expense> addExpense(Expense expense) async {
    final collection = _isar.collection<ExpenseEntity>();
    final id = expense.id!.isEmpty ? _uuid.v4() : expense.id;
    final entity = ExpenseEntity()
      ..uid = id
      ..title = expense.title
      ..category = expense.category
      ..amount = expense.amount
      ..date = expense.date
      ..notes = expense.notes
      ..receiptPath = expense.receiptPath;

    await _isar.writeTxn(() async {
      await collection.put(entity);
    });

    return expense.copyWith(id: id);
  }

  Future<Expense> updateExpense(Expense expense) async {
    final collection = _isar.collection<ExpenseEntity>();
    final entity = await collection.filter().uidEqualTo(expense.id).findFirst();
    if (entity == null) {
      throw StateError('Expense not found');
    }

    entity
      ..title = expense.title
      ..category = expense.category
      ..amount = expense.amount
      ..date = expense.date
      ..notes = expense.notes
      ..receiptPath = expense.receiptPath;

    await _isar.writeTxn(() async {
      await collection.put(entity);
    });

    return expense;
  }

  Future<void> deleteExpense(String id) async {
    final collection = _isar.collection<ExpenseEntity>();
    final entity = await collection.filter().uidEqualTo(id).findFirst();
    if (entity != null) {
      await _isar.writeTxn(() async {
        await collection.delete(entity.id);
      });
    }
  }
}

class ExpenseListNotifier extends StateNotifier<List<Expense>> {
  final ExpenseRepository _repository;

  ExpenseListNotifier(this._repository) : super([]) {
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final expenses = await _repository.getAllExpenses();
    state = List<Expense>.unmodifiable(expenses);
  }

  Future<Expense> addExpense(Expense expense) async {
    debugPrint("Expense Added : ${expense.id}");
    final newExpense = await _repository.addExpense(expense);
    state = [...state, newExpense];
    return newExpense;
  }

  Future<Expense> updateExpense(Expense expense) async {
    final updatedExpense = await _repository.updateExpense(expense);
    state = state
        .map((item) => item.id == updatedExpense.id ? updatedExpense : item)
        .toList(growable: false);
    return updatedExpense;
  }

  Future<void> deleteExpense(String id) async {
    await _repository.deleteExpense(id);
    state = state.where((item) => item.id != id).toList(growable: false);
  }

  void setExpenses(List<Expense> expenses) {
    state = List<Expense>.unmodifiable(expenses);
  }
}
