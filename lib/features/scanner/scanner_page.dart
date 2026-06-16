import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/models/expense.dart';
import '../../services/gemini_service.dart';
import '../expenses/expense_form_page.dart';

class ScannerPage extends ConsumerStatefulWidget {
  const ScannerPage({super.key});

  @override
  ConsumerState<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends ConsumerState<ScannerPage> {
  ReceiptScanResult? _scanResult;
  bool _isProcessing = false;
  String? _errorMessage;

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _scanResult = null;
    });

    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        imageQuality: 80,
      );
      if (file == null) {
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      final result = await ref
          .read(geminiServiceProvider)
          .analyzeReceiptImage(File(file.path));
      setState(() {
        _scanResult = result;
      });
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Receipt Scanner'),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
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
                children: const [
                  Text(
                    'Smart receipt scanning',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Use the camera or gallery to scan receipts and add expenses instantly.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF6D6D78)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('Scan receipt with camera'),
              onPressed: _isProcessing ? null : () => _pickImage(ImageSource.camera),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.photo_library),
              label: const Text('Choose receipt from gallery'),
              onPressed: _isProcessing ? null : () => _pickImage(ImageSource.gallery),
            ),
            const SizedBox(height: 24),
            if (_isProcessing) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 16),
              const Text(
                'Analyzing receipt image…',
                textAlign: TextAlign.center,
              ),
            ],
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_scanResult != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Receipt preview',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(label: 'Title', value: _scanResult!.title),
                      _InfoRow(label: 'Category', value: _scanResult!.category),
                      _InfoRow(label: 'Amount', value: '\$${_scanResult!.amount.toStringAsFixed(2)}'),
                      _InfoRow(label: 'Date', value: _scanResult!.date.toLocal().toIso8601String().split('T').first),
                      if (_scanResult!.notes != null) ...[
                        const SizedBox(height: 10),
                        const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(_scanResult!.notes!),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _openExpenseForm,
                child: const Text('Confirm and Add Expense'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openExpenseForm() async {
    if (_scanResult == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExpenseFormPage(
          isFromScanner: true,
          expense: Expense(
            id: '',
            title: _scanResult!.title,
            category: _scanResult!.category,
            amount: _scanResult!.amount,
            date: _scanResult!.date,
            notes: _scanResult!.notes,
            receiptPath: _scanResult!.receiptPath,
          ),
        ),
      ),
    );

    if (!mounted) return;

    setState(() {
      _scanResult = null;
      _errorMessage = null;
    });
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label',
              style: const TextStyle(fontSize: 13, color: Color(0xFF6D6D78)),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
