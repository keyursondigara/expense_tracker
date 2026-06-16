import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/categories.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/expense.dart';
import '../../data/repositories/expense_repository.dart';

class ExpenseFormPage extends ConsumerStatefulWidget {
  const ExpenseFormPage({super.key, this.expense, this.isFromScanner = false});

  final Expense? expense;
  final bool isFromScanner;

  @override
  ConsumerState<ExpenseFormPage> createState() => _ExpenseFormPageState();
}

class _ExpenseFormPageState extends ConsumerState<ExpenseFormPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;
  late DateTime _selectedDate;
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    _titleController = TextEditingController(text: expense?.title ?? '');
    _amountController = TextEditingController(
      text: expense?.amount.toStringAsFixed(2) ?? '',
    );
    _notesController = TextEditingController(text: expense?.notes ?? '');
    _selectedDate = expense?.date ?? DateTime.now();
    _selectedCategory = expense?.category ?? expenseCategories.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.expense != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Expense' : 'Add Expense'),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditing ? 'Update expense details' : 'Add a new expense',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isEditing
                          ? 'Make changes and save your expense.'
                          : 'Enter details to keep your spending under control.',
                      style: const TextStyle(fontSize: 14, color: Color(0xFF6D6D78)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: expenseCategories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes (optional)'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Date: ${dateFormat.format(_selectedDate)}',
                        style: const TextStyle(fontSize: 14, color: Color(0xFF4F4F4F)),
                      ),
                    ),
                    TextButton(onPressed: _chooseDate, child: const Text('Change')),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => _saveExpense(context),
                child: Text(isEditing ? 'Save Changes' : 'Add Expense'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _chooseDate() async {
    final chosenDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (chosenDate != null) {
      setState(() {
        _selectedDate = chosenDate;
      });
    }
  }

  Future<void> _saveExpense(BuildContext context) async {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;

    if (title.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid title and amount.')),
      );
      return;
    }

    final expense = Expense(
      id:
           (widget.expense?.id != null &&
            widget.expense!.id.isNotEmpty)
        ? widget.expense!.id
        : _selectedDate.millisecondsSinceEpoch.toString(),

      title: title,

      category: _selectedCategory,

      amount: amount,

      date: _selectedDate,

      notes:
          _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),

      receiptPath:
          widget.expense?.receiptPath,
    );

    debugPrint("Expense object: ${widget.expense != null}");
    debugPrint("Expense ID: ${expense.toMap()}");

    final notifier = ref.read(expenseListProvider.notifier);
    final navigator = Navigator.of(context);
    final isNewExpense = widget.expense == null || widget.expense!.id.isEmpty;

    if (isNewExpense) {
      debugPrint("Adding new expense: ${expense.toMap()}");
      await notifier.addExpense(expense);
    } else {
      await notifier.updateExpense(expense);
    }

    if (!mounted) {
      return;
    }

    navigator.pop();
  }
}
