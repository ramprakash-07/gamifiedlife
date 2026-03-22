// ─────────────────────────────────────────────────────────────────────────────
//  Finance Screen — Expense Tracker with Line & Pie Charts
//  BottomSheet input · fl_chart visualizations · Swipe-to-delete
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../database_helper.dart';

const Color _kBg = Color(0xFF0A0A0A);
const Color _kAccent = Color(0xFF00E5FF);
const Color _kCardBg = Color(0xFF141414);
const Color _kTextDim = Color(0xFF888888);
const String _kFont = 'Courier';

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
  Color(0xFF888888), // Other
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
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                        color: _kTextDim.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'LOG EXPENSE',
                    style: TextStyle(
                      color: _kAccent,
                      fontFamily: _kFont,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    autofocus: true,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: _kFont,
                      fontSize: 24,
                    ),
                    cursorColor: _kAccent,
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      prefixStyle: TextStyle(
                        color: _kAccent.withOpacity(0.7),
                        fontFamily: _kFont,
                        fontSize: 24,
                      ),
                      hintText: '0.00',
                      hintStyle: TextStyle(color: _kTextDim.withOpacity(0.5)),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: _kAccent),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: _kAccent, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
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
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _categoryColors[entry.key].withOpacity(0.2)
                                : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? _categoryColors[entry.key]
                                  : Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: Text(
                            entry.value,
                            style: TextStyle(
                              color: isSelected
                                  ? _categoryColors[entry.key]
                                  : _kTextDim,
                              fontFamily: _kFont,
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
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
                        backgroundColor: _kAccent,
                        foregroundColor: _kBg,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
                      child: const Text(
                        'ADD EXPENSE',
                        style: TextStyle(
                          fontFamily: _kFont,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
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

  // ── Build daily spending data for line chart ───────────────────────────

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

  // ── Build category data for pie chart ──────────────────────────────────

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
        titleStyle: const TextStyle(
          color: Colors.white,
          fontFamily: _kFont,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        radius: 50,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: _kAccent));
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
                      color: _kAccent.withOpacity(0.3), size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'No expenses logged.\nTap + to track spending.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _kTextDim, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Month header ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _kCardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kAccent.withOpacity(0.15)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        monthLabel.toUpperCase(),
                        style: const TextStyle(
                          color: _kAccent,
                          fontFamily: _kFont,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        '₹ ${_totalMonth.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: _kFont,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Daily spending line chart ──
                Container(
                  padding: const EdgeInsets.all(16),
                  height: 220,
                  decoration: BoxDecoration(
                    color: _kCardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kAccent.withOpacity(0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DAILY SPENDING',
                        style: TextStyle(
                          color: _kTextDim,
                          fontFamily: _kFont,
                          fontSize: 11,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: Colors.white.withOpacity(0.05),
                                strokeWidth: 1,
                              ),
                            ),
                            titlesData: FlTitlesData(
                              rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 22,
                                  interval: 5,
                                  getTitlesWidget: (value, meta) {
                                    final day = value.toInt() + 1;
                                    return Text(
                                      '$day',
                                      style: TextStyle(
                                        color: _kTextDim.withOpacity(0.6),
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
                                color: _kAccent,
                                barWidth: 2,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: _kAccent.withOpacity(0.08),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Category pie chart ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _kCardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kAccent.withOpacity(0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'BY CATEGORY',
                        style: TextStyle(
                          color: _kTextDim,
                          fontFamily: _kFont,
                          fontSize: 11,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 12),
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
                      const SizedBox(height: 12),
                      // Legend
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: _categories.asMap().entries.map((entry) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: _categoryColors[entry.key],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                entry.value,
                                style: const TextStyle(
                                  color: _kTextDim,
                                  fontFamily: _kFont,
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
                const SizedBox(height: 16),

                // ── Recent expenses list ──
                const Text(
                  'RECENT',
                  style: TextStyle(
                    color: _kTextDim,
                    fontFamily: _kFont,
                    fontSize: 11,
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
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.delete_outline,
                          color: Colors.red),
                    ),
                    onDismissed: (_) async {
                      await DatabaseHelper.instance
                          .deleteExpense(expense.id!);
                      _loadExpenses();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: _kCardBg,
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: color.withOpacity(0.15)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  expense.category.toUpperCase(),
                                  style: TextStyle(
                                    color: color,
                                    fontFamily: _kFont,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                                Text(
                                  DateFormat('dd MMM, hh:mm a')
                                      .format(expense.date),
                                  style: TextStyle(
                                    color: _kTextDim.withOpacity(0.6),
                                    fontFamily: _kFont,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₹ ${expense.amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: _kFont,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
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
      floatingActionButton: FloatingActionButton(
        heroTag: 'finance_fab',
        backgroundColor: _kAccent,
        onPressed: _showAddExpenseSheet,
        child: const Icon(Icons.add, color: _kBg, size: 28),
      ),
    );
  }
}
