import 'package:flutter/material.dart';
import '../utils/typography.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';
import 'dart:math' as math;
import '../providers/theme_provider.dart';

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({Key? key}) : super(key: key);

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  String _selectedPeriod = 'month';
  bool _isLoading = true;
  List<TransactionModel> _transactions = [];
  Map<String, Category> _categories = {};
  Map<String, double> _categoryTotals = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final db = Provider.of<DatabaseService>(context, listen: false);
    
    DateTime startDate;
    final now = DateTime.now();
    
    if (_selectedPeriod == 'week') {
      startDate = now.subtract(const Duration(days: 7));
    } else if (_selectedPeriod == 'month') {
      startDate = DateTime(now.year, now.month, 1);
    } else {
      startDate = DateTime(now.year, 1, 1);
    }
    
    final transactions = await db.getTransactions(
      type: 'expense',
      startDate: startDate,
      endDate: now,
    );
    
    final categories = await db.getCategories();
    final categoryMap = {for (var cat in categories) cat.id: cat};
    
    // Calculate category totals
    final totals = <String, double>{};
    for (var transaction in transactions) {
      totals[transaction.categoryId] = 
          (totals[transaction.categoryId] ?? 0) + transaction.amount;
    }
    
    setState(() {
      _transactions = transactions;
      _categories = categoryMap;
      _categoryTotals = totals;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Analytics',
          style: AppTypography.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period Selector
                  Row(
                    children: [
                      Expanded(
                        child: _PeriodChip(
                          label: 'Week',
                          isSelected: _selectedPeriod == 'week',
                          onTap: () {
                            setState(() => _selectedPeriod = 'week');
                            _loadData();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _PeriodChip(
                          label: 'Month',
                          isSelected: _selectedPeriod == 'month',
                          onTap: () {
                            setState(() => _selectedPeriod = 'month');
                            _loadData();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _PeriodChip(
                          label: 'Year',
                          isSelected: _selectedPeriod == 'year',
                          onTap: () {
                            setState(() => _selectedPeriod = 'year');
                            _loadData();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  if (_categoryTotals.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.bar_chart_rounded,
                              size: 80,
                              color: Colors.grey.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No data for this period',
                              style: AppTypography.poppins(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    // Pie Chart
                    Text(
                      'Expenses by Category',
                      style: AppTypography.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 250,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 60,
                          sections: _buildPieChartSections(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Category Breakdown
                    Text(
                      'Breakdown',
                      style: AppTypography.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._buildCategoryList(),

                    const SizedBox(height: 32),

                    // Spending Trend
                    Text(
                      'Spending Trend',
                      style: AppTypography.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 200,
                      child: LineChart(
                        _buildLineChart(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    final total = _categoryTotals.values.fold(0.0, (sum, val) => sum + val);
    
    return _categoryTotals.entries.map((entry) {
      final category = _categories[entry.key];
      final percentage = (entry.value / total) * 100;
      
      return PieChartSectionData(
        color: category?.color ?? Colors.grey,
        value: entry.value,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: AppTypography.poppins(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  List<Widget> _buildCategoryList() {
    final total = _categoryTotals.values.fold(0.0, (sum, val) => sum + val);
    final sortedEntries = _categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.map((entry) {
      final category = _categories[entry.key];
      final percentage = (entry.value / total) * 100;

      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: category?.color.withOpacity(0.2) ?? Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  category?.icon ?? Icons.help_outline,
                  color: category?.color ?? Colors.grey,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category?.name ?? 'Unknown',
                      style: AppTypography.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: AppTypography.poppins(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${Provider.of<ThemeProvider>(context).currencySymbol}${NumberFormat.currency(symbol: '').format(entry.value)}',
                style: AppTypography.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: category?.color ?? Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  LineChartData _buildLineChart() {
    final now = DateTime.now();
    final days = _selectedPeriod == 'week' ? 7 : _selectedPeriod == 'month' ? 30 : 365;
    final dailyTotals = <int, double>{};

    for (var transaction in _transactions) {
      final daysDiff = now.difference(transaction.date).inDays;
      if (daysDiff < days) {
        dailyTotals[days - daysDiff] = 
            (dailyTotals[days - daysDiff] ?? 0) + transaction.amount;
      }
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < days; i++) {
      spots.add(FlSpot(i.toDouble(), dailyTotals[i] ?? 0));
    }

    return LineChartData(
      gridData: FlGridData(show: false),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              if (value.toInt() % (days ~/ 5) == 0) {
                return Text(
                  '${value.toInt()}',
                  style: AppTypography.poppins(fontSize: 10),
                );
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: AppTheme.primaryPurple,
          barWidth: 3,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: AppTheme.primaryPurple.withOpacity(0.2),
          ),
        ),
      ],
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primaryPurple.withOpacity(0.2) 
              : Colors.transparent,
          border: Border.all(
            color: isSelected 
                ? AppTheme.primaryPurple 
                : Colors.grey.withOpacity(0.3),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.poppins(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
