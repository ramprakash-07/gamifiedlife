// ─────────────────────────────────────────────────────────────────────────────
//  Finance Screen — Expense Tracker with Line & Pie Charts
//  Glassmorphism cards · Orbitron/Inter fonts · 8pt grid
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../database_helper.dart';
import '../theme/app_theme.dart';

const List<String> _categories = [
  'Food',
  'Tech',
  'Travel',
  'Health',
  'Education',
  'Entertainment',
  'Other',
];

const List<Color> _categoryColors = [
  Color(0xFFFF6B6B), // Food
  Color(0xFF4ECDC4), // Tech
  Color(0xFFFFE66D), // Travel
  Color(0xFF95E1D3), // Health
  Color(0xFFA29BFE), // Education
  Color(0xFFFF85A2), // Entertainment
  Color(0xFF6B7A8D), // Other
];

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  List<Expense> _monthExpenses = [];
  bool _loading = true;
  double _totalMonth = 0;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final now = DateTime.now();
    final expenses = await DatabaseHelper.instance
        .getExpensesForMonth(now.year, now.month);
    double total = 0;
    for (final e in expenses) {
      total += e.amount;
    }
    if (mounted) {
      setState(() {
        _monthExpenses = expenses;
        _totalMonth = total;
        _loading = false;
      });
    }
  }

  void _showAddExpenseSheet() {
    final amountController = TextEditingController();
    String selectedCategory = _categories[0];

    showModalBottomSheet(
      context: context,
      backgroundColor: glassDialogBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: kNeonCyan.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'LOG EXPENSE',
                    style: orbitronStyle(fontSize: 16, letterSpacing: 3),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    autofocus: true,
                    style: interStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                    ),
                    cursorColor: kNeonCyan,
                    decoration: glassInputDecoration(
                      hintText: '0.00',
                      prefixText: '₹ ',
                      prefixStyle: interStyle(
                        color: kNeonCyan.withOpacity(0.7),
                        fontSize: 24,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.asMap().entries.map((entry) {
                      final isSelected = entry.value == selectedCategory;
                      return GestureDetector(
                        onTap: () {
                          setSheetState(
                              () => selectedCategory = entry.value);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _categoryColors[entry.key].withOpacity(0.15)
                                : Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? _categoryColors[entry.key]
                                  : Colors.white.withOpacity(0.08),
                            ),
                          ),
                          child: Text(
                            entry.value,
                            style: interStyle(
                              color: isSelected
                                  ? _categoryColors[entry.key]
                                  : kDimText,
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kNeonCyan.withOpacity(0.15),
                        foregroundColor: kNeonCyan,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                              color: kNeonCyan.withOpacity(0.3)),
                        ),
                      ),
                      onPressed: () async {
                        final amount =
                            double.tryParse(amountController.text.trim());
                        if (amount == null || amount <= 0) return;

                        await DatabaseHelper.instance.insertExpense(Expense(
                          amount: amount,
                          category: selectedCategory,
                          dateTimestamp:
                              DateTime.now().millisecondsSinceEpoch,
                        ));

                        if (mounted) Navigator.pop(ctx);
                        _loadExpenses();
                      },
                      child: Text(
                        'ADD EXPENSE',
                        style: orbitronStyle(
                          fontSize: 12,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<FlSpot> _buildDailySpots() {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final dailyTotals = List<double>.filled(daysInMonth, 0);

    for (final expense in _monthExpenses) {
      final day = expense.date.day;
      if (day >= 1 && day <= daysInMonth) {
        dailyTotals[day - 1] += expense.amount;
      }
    }

    return List.generate(
      daysInMonth,
      (i) => FlSpot(i.toDouble(), dailyTotals[i]),
    );
  }

  List<PieChartSectionData> _buildPieSections() {
    final Map<String, double> categoryTotals = {};
    for (final expense in _monthExpenses) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }

    if (categoryTotals.isEmpty) return [];

    return categoryTotals.entries.map((entry) {
      final catIndex = _categories.indexOf(entry.key);
      final color =
          catIndex >= 0 ? _categoryColors[catIndex] : _categoryColors.last;
      final percentage = (entry.value / _totalMonth * 100);

      return PieChartSectionData(
        value: entry.value,
        color: color,
        title: '${percentage.toStringAsFixed(0)}%',
        titleStyle: interStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
        radius: 50,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(
          child: CircularProgressIndicator(
              color: kNeonCyan, strokeWidth: 2));
    }

    final now = DateTime.now();
    final monthLabel = DateFormat('MMMM yyyy').format(now);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _monthExpenses.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.account_balance_wallet_outlined,
                      color: kNeonCyan.withOpacity(0.3), size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'No expenses logged.\nTap + to track spending.',
                    textAlign: TextAlign.center,
                    style: interStyle(color: kDimText, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Month header ──
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        monthLabel.toUpperCase(),
                        style: orbitronStyle(
                          fontSize: 12,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        '₹ ${_totalMonth.toStringAsFixed(2)}',
                        style: orbitronStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Daily spending line chart ──
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    height: 200,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DAILY SPENDING',
                          style: orbitronStyle(
                            fontSize: 10,
                            color: kDimText,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: Colors.white.withOpacity(0.04),
                                  strokeWidth: 1,
                                ),
                              ),
                              titlesData: FlTitlesData(
                                rightTitles: const AxisTitles(
                                    sideTitles:
                                        SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(
                                    sideTitles:
                                        SideTitles(showTitles: false)),
                                leftTitles: const AxisTitles(
                                    sideTitles:
                                        SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 22,
                                    interval: 5,
                                    getTitlesWidget: (value, meta) {
                                      final day = value.toInt() + 1;
                                      return Text(
                                        '$day',
                                        style: interStyle(
                                          color: kDimText.withOpacity(0.6),
                                          fontSize: 9,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: _buildDailySpots(),
                                  isCurved: true,
                                  color: kNeonCyan,
                                  barWidth: 2,
                                  dotData: const FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: kNeonCyan.withOpacity(0.06),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Category pie chart ──
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BY CATEGORY',
                        style: orbitronStyle(
                          fontSize: 10,
                          color: kDimText,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 180,
                        child: PieChart(
                          PieChartData(
                            sections: _buildPieSections(),
                            centerSpaceRadius: 40,
                            sectionsSpace: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Legend
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: _categories.asMap().entries.map((entry) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _categoryColors[entry.key],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                entry.value,
                                style: interStyle(
                                  color: kDimText,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Recent expenses list ──
                Text(
                  'RECENT',
                  style: orbitronStyle(
                    fontSize: 10,
                    color: kDimText,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                ...List.generate(_monthExpenses.length, (i) {
                  final expense = _monthExpenses[i];
                  final catIndex = _categories.indexOf(expense.category);
                  final color = catIndex >= 0
                      ? _categoryColors[catIndex]
                      : _categoryColors.last;
                  return Dismissible(
                    key: Key('expense_${expense.id}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: kHardRed.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child:
                          Icon(Icons.delete_outline, color: kHardRed),
                    ),
                    onDismissed: (_) async {
                      await DatabaseHelper.instance
                          .deleteExpense(expense.id!);
                      _loadExpenses();
                    },
                    child: GlassCard(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      borderColor: color,
                      borderOpacity: 0.12,
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  expense.category.toUpperCase(),
                                  style: interStyle(
                                    color: color,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat('dd MMM, hh:mm a')
                                      .format(expense.date),
                                  style: interStyle(
                                    color: kDimText.withOpacity(0.6),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₹ ${expense.amount.toStringAsFixed(2)}',
                            style: interStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 80), // FAB clearance
              ],
            ),
      floatingActionButton: GlassFAB(
        heroTag: 'finance_fab',
        onPressed: _showAddExpenseSheet,
      ),
    );
  }
}
