// lib/presentation/pages/insights_page.dart

import 'dart:math' as math;

import 'package:expense_tracker/data/models/expense.dart';
import 'package:expense_tracker/data/models/spending_insights.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/expense_repository.dart';
import '../../services/gemini_service.dart';


final _insightsProvider = Provider.family<SpendingInsights, List<Expense>>(
  (ref, expenses) {
    final service = ref.read(geminiServiceProvider);
    return service.generateSpendingInsights(List.of(expenses));
  },
);

const List<Color> _kPalette = [
  Color(0xFF3266AD),
  Color(0xFF73726C),
  Color(0xFF1D9E75),
  Color(0xFFBA7517),
  Color(0xFFD4537E),
  Color(0xFF7F77DD),
  Color(0xFF0F6E56),
  Color(0xFF993C1D),
];

Color _colorFor(int index) => _kPalette[index % _kPalette.length];


class InsightsPage extends ConsumerWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expenseListProvider);
    final insights = ref.watch(_insightsProvider(expenses));

    return Scaffold(
      backgroundColor: const Color(0xFFF6F5FF),
      appBar: AppBar(
        title: const Text('Spending Insights'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: insights.expenseCount == 0
          ? const _EmptyState()
          : _InsightsBody(insights: insights),
    );
  }
}


class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.deepPurple.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.insights_outlined, size: 48, color: Color(0xFF5E35B1)),
            ),
            const SizedBox(height: 18),
            const Text(
              'Insights are waiting',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            const Text(
              'Add a few expenses and come back to discover your spending patterns.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Color(0xFF64646A)),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightsBody extends StatelessWidget {
  final SpendingInsights insights;

  const _InsightsBody({required this.insights});

  String _formatAmount(double amount) {
    final str = amount.toStringAsFixed(0);
    final buffer = StringBuffer();
    final offset = str.length % 3;
    for (int i = 0; i < str.length; i++) {
      if (i != 0 && (i - offset) % 3 == 0) buffer.write(',');
      buffer.write(str[i]);
    }
    return '\$$buffer';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _InsightsHeader(),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: 'Total spent',
                  value: _formatAmount(insights.total),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  label: 'Expenses',
                  value: '${insights.expenseCount}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _CardLabel('Category breakdown'),
                const SizedBox(height: 12),
                _Legend(categoryTotals: insights.categoryTotals, total: insights.total),
                const SizedBox(height: 20),
                SizedBox(
                  height: 220,
                  child: _DonutChart(
                    categoryTotals: insights.categoryTotals,
                    total: insights.total,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.07), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF888780))),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A))),
        ],
      ),
    );
  }
}


class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.07), width: 0.5),
      ),
      child: child,
    );
  }
}

class _CardLabel extends StatelessWidget {
  final String text;

  const _CardLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF888780)));
  }
}

class _InsightsHeader extends StatelessWidget {
  const _InsightsHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6D52F5), Color(0xFF6242E2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Your spending at a glance',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 10),
          Text(
            'Smart insights to help you shop and save better.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final List<CategoryTotal> categoryTotals;
  final double total;

  const _Legend({required this.categoryTotals, required this.total});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: List.generate(categoryTotals.length, (i) {
        final cat = categoryTotals[i];
        final pct = (cat.amount / total * 100).round();
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                  color: _colorFor(i), borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 4),
            Text('${cat.category} $pct%',
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF888780))),
          ],
        );
      }),
    );
  }
}


class _DonutChart extends StatefulWidget {
  final List<CategoryTotal> categoryTotals;
  final double total;

  const _DonutChart({required this.categoryTotals, required this.total});

  @override
  State<_DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<_DonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  int? _tappedIndex;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => GestureDetector(
        onTapDown: (details) {
          final box = context.findRenderObject() as RenderBox;
          final local = box.globalToLocal(details.globalPosition);
          final center = Offset(box.size.width / 2, box.size.height / 2);
          final dx = local.dx - center.dx;
          final dy = local.dy - center.dy;
          final dist = math.sqrt(dx * dx + dy * dy);
          final radius = math.min(box.size.width, box.size.height) / 2;
          if (dist < radius * 0.45 || dist > radius * 0.98) {
            setState(() => _tappedIndex = null);
            return;
          }
          double angle = math.atan2(dy, dx) + math.pi / 2;
          if (angle < 0) angle += 2 * math.pi;
          double sweep = 0;
          for (int i = 0; i < widget.categoryTotals.length; i++) {
            sweep +=
                (widget.categoryTotals[i].amount / widget.total) * 2 * math.pi;
            if (angle < sweep) {
              setState(() => _tappedIndex = i);
              return;
            }
          }
          setState(() => _tappedIndex = null);
        },
        child: CustomPaint(
          size: Size.infinite,
          painter: _DonutPainter(
            categoryTotals: widget.categoryTotals,
            total: widget.total,
            progress: _anim.value,
            tappedIndex: _tappedIndex,
            totalLabel: '\$${widget.total.toStringAsFixed(0)}',
            countLabel: '${widget.categoryTotals.length} categories',
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<CategoryTotal> categoryTotals;
  final double total;
  final double progress;
  final int? tappedIndex;
  final String totalLabel;
  final String countLabel;

  _DonutPainter({
    required this.categoryTotals,
    required this.total,
    required this.progress,
    required this.totalLabel,
    required this.countLabel,
    this.tappedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    final strokeWidth = radius * 0.38;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    double startAngle = -math.pi / 2;
    for (int i = 0; i < categoryTotals.length; i++) {
      final sweepAngle =
          (categoryTotals[i].amount / total) * 2 * math.pi * progress;
      paint.color =
          _colorFor(i).withValues(alpha: i == tappedIndex ? 1.0 : 0.85);
      final r = i == tappedIndex ? radius + 6 : radius;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        startAngle,
        math.max(sweepAngle - 0.025, 0),
        false,
        paint,
      );
      startAngle += sweepAngle;
    }

    if (tappedIndex != null) {
      final cat = categoryTotals[tappedIndex!];
      final pct = (cat.amount / total * 100).round();
      final amt = cat.amount >= 1000
          ? '\$${(cat.amount / 1000).toStringAsFixed(1)}k'
          : '\$${cat.amount.toStringAsFixed(0)}';
      _drawCenter(canvas, center, cat.category, amt, '$pct%', _colorFor(tappedIndex!));
    } else {
      _drawCenter(canvas, center, 'Total', totalLabel, countLabel, const Color(0xFF888780));
    }
  }

  void _drawCenter(Canvas canvas, Offset center, String top, String mid,
      String bot, Color accentColor) {
    void drawText(String text, double yOffset, TextStyle style) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, center.translate(-tp.width / 2, yOffset));
    }

    drawText(top, -36,
        const TextStyle(fontSize: 12, color: Color(0xFF888780), fontWeight: FontWeight.w400));
    drawText(mid, -14,
        const TextStyle(fontSize: 20, color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600));
    drawText(bot, 12,
        TextStyle(fontSize: 12, color: accentColor, fontWeight: FontWeight.w500));
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.progress != progress || old.tappedIndex != tappedIndex;
}