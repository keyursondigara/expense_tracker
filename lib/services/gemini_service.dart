import 'dart:io';

import 'package:expense_tracker/core/constants/categories.dart';
import 'package:expense_tracker/data/models/spending_insights.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:intl/intl.dart';

import '../data/models/expense.dart';

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});

class ReceiptScanResult {
  final String title;
  final String category;
  final double amount;
  final DateTime date;
  final String? notes;
  final String? receiptPath;

  ReceiptScanResult({
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    this.notes,
    this.receiptPath,
  });

  Expense toExpense(String id) {
    return Expense(
      id: id,
      title: title,
      category: category,
      amount: amount,
      date: date,
      notes: notes,
      receiptPath: receiptPath,
    );
  }
}

class GeminiService {
  GeminiService({String? apiKey});


  Future<ReceiptScanResult> analyzeReceiptImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);

    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    final recognizedText = await textRecognizer.processImage(inputImage);

    await textRecognizer.close();

    final text = recognizedText.text;

    final amount = _extractAmount(text);

    final date = _extractDate(text);

    final title = _extractTitle(text);

    final category = _detectCategory(text);

    return ReceiptScanResult(
      title: title,
      category: category,
      amount: amount,
      date: date,
      notes: _extractNotes(_detectCategory(text)),
      receiptPath: imageFile.path,
    );
  }

  double _extractAmount(String text) {
  final lines = text.split('\n');

  final totalKeywords = [
    'total',
    'grand total',
    'net amount',
    'amount payable',
    'payable',
    'bill amount',
    'final amount',
  ];


  // Find amount near total keyword
  for (int i = 0; i < lines.length; i++) {

    final line = lines[i].toLowerCase();


    for (final keyword in totalKeywords) {

      if (line.contains(keyword)) {

        final amountRegex = RegExp(
          r'(\d+[,.]?\d*\.\d{1,2}|\d+[,.]?\d*)'
        );


        final match = amountRegex.firstMatch(lines[i]);


        if(match != null){

          return double.parse(
            match.group(0)!
              .replaceAll(',', '')
          );

        }


        // Check next line also
        if(i + 1 < lines.length){

          final nextMatch =
              amountRegex.firstMatch(lines[i + 1]);


          if(nextMatch != null){

            return double.parse(
              nextMatch.group(0)!
                .replaceAll(',', '')
            );

          }
        }
      }
    }
  }


  return 0;
}

String _extractNotes(String category) {
  switch (category) {
    case 'Food':
      return 'Food expense receipt scanned.';

    case 'Shopping':
      return 'Shopping expense receipt scanned.';

    case 'Travel':
      return 'Travel expense receipt scanned.';

    case 'Utilities':
      return 'Utility bill receipt scanned.';

    case 'Entertainment':
      return 'Entertainment expense receipt scanned.';

    default:
      return 'Other expense receipt scanned.';
  }
}
  
  DateTime _extractDate(String text) {
    final regex = RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}');

    final match = regex.firstMatch(text);

    if (match != null) {
      try {
        return DateFormat("dd/MM/yyyy").parse(match.group(0)!);
      } catch (_) {}
    }

    return DateTime.now();
  }

  String _extractTitle(String text) {
    final lines = text.split('\n').where((e) => e.trim().length > 3).toList();

    if (lines.isNotEmpty) {
      return lines.first.trim();
    }

    return "Receipt";
  }

  String _detectCategory(String text) {
    final value = text.toLowerCase();

    final categoryKeywords = {
      'Food': [
        'restaurant',
        'cafe',
        'coffee',
        'food',
        'pizza',
        'burger',
        'swiggy',
        'zomato',
        'meal',
        'dining',
      ],

      'Shopping': [
        'amazon',
        'flipkart',
        'mall',
        'store',
        'clothing',
        'fashion',
        'shopping',
      ],

      'Travel': [
        'uber',
        'ola',
        'taxi',
        'flight',
        'airline',
        'bus',
        'train',
        'hotel',
        'travel',
      ],

      'Utilities': [
        'electricity',
        'water',
        'gas',
        'internet',
        'wifi',
        'recharge',
        'bill',
      ],

      'Entertainment': [
        'movie',
        'cinema',
        'netflix',
        'spotify',
        'game',
        'concert',
      ],
    };

    for (final category in expenseCategories) {
      if (category == 'Others') {
        continue;
      }

      final keywords = categoryKeywords[category] ?? [];

      for (final keyword in keywords) {
        if (value.contains(keyword)) {
          return category;
        }
      }
    }

    return 'Others';
  }

  // In lib/services/gemini_service.dart
// Replace generateSpendingInsights with this method:

SpendingInsights generateSpendingInsights(List<Expense> expenses) {
  if (expenses.isEmpty) {
    return const SpendingInsights(
      expenseCount: 0,
      total: 0,
      categoryTotals: [],
    );
  }

  final total = expenses.fold<double>(0, (sum, e) => sum + e.amount);

  final Map<String, double> totalsMap = {};
  for (final expense in expenses) {
    totalsMap[expense.category] = (totalsMap[expense.category] ?? 0) + expense.amount;
  }

  final categoryTotals = totalsMap.entries
      .map((e) => CategoryTotal(category: e.key, amount: e.value))
      .toList()
    ..sort((a, b) => b.amount.compareTo(a.amount));

  return SpendingInsights(
    expenseCount: expenses.length,
    total: total,
    categoryTotals: categoryTotals,
  );
}
}
