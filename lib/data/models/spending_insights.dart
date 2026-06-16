// lib/data/models/spending_insights.dart

class CategoryTotal {
  final String category;
  final double amount;

  const CategoryTotal({required this.category, required this.amount});
}

class SpendingInsights {
  final int expenseCount;
  final double total;
  final List<CategoryTotal> categoryTotals; // sorted descending by amount

  const SpendingInsights({
    required this.expenseCount,
    required this.total,
    required this.categoryTotals,
  });

  CategoryTotal? get topCategory => categoryTotals.isEmpty ? null : categoryTotals.first;
}