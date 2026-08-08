import 'package:flutter/material.dart';
import '../utils/typography.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../widgets/stat_card.dart';
import '../widgets/transaction_card.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import 'charts_screen.dart';
import 'transactions_screen.dart';
import 'contacts_screen.dart';
import '../providers/theme_provider.dart';
import 'settings_screen.dart';
import 'calendar_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _totalBalance = 0.0;
  Map<String, double> _monthlyStats = {};
  List<TransactionModel> _recentTransactions = [];
  Map<String, Category> _categories = {};
  bool _isLoading = true;
  List<FlSpot> _incomeSpots = [];
  List<FlSpot> _expenseSpots = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final db = Provider.of<DatabaseService>(context, listen: false);
    
    // Load balance
    final balance = await db.getTotalBalance();
    
    // Load monthly stats
    final now = DateTime.now();
    final stats = await db.getMonthlyStats(now);
    
    // Load transactions for the current month for the chart
    final startOfMonth = DateTime(now.year, now.month, 1);
    final transactions = await db.getTransactions(
      startDate: startOfMonth,
      endDate: now,
    );
    
    // Recent transactions (all)
    final allTransactions = await db.getTransactions();
    final recentTrans = allTransactions.take(10).toList();
    
    // Load categories
    final categories = await db.getCategories();
    final categoryMap = {for (var cat in categories) cat.id: cat};
    
    // Prepare chart data
    _prepareChartData(transactions);
    
    setState(() {
      _totalBalance = balance;
      _monthlyStats = stats;
      _recentTransactions = recentTrans;
      _categories = categoryMap;
      _isLoading = false;
    });
  }

  void _prepareChartData(List<TransactionModel> transactions) {
    final Map<int, double> dailyIncome = {};
    final Map<int, double> dailyExpense = {};
    
    for (var tx in transactions) {
      final day = tx.date.day;
      if (tx.type == 'income') {
        dailyIncome[day] = (dailyIncome[day] ?? 0) + tx.amount;
      } else if (tx.type == 'expense') {
        dailyExpense[day] = (dailyExpense[day] ?? 0) + tx.amount;
      }
    }
    
    _incomeSpots = dailyIncome.entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList()..sort((a, b) => a.x.compareTo(b.x));
        
    _expenseSpots = dailyExpense.entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList()..sort((a, b) => a.x.compareTo(b.x));
        
    if (_incomeSpots.isEmpty) _incomeSpots = [const FlSpot(0, 0)];
    if (_expenseSpots.isEmpty) _expenseSpots = [const FlSpot(0, 0)];
  }

  Widget build(BuildContext context) {
    final income = _monthlyStats['income'] ?? 0.0;
    final expenses = _monthlyStats['expenses'] ?? 0.0;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // 3D Hovering Balance Card
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.deepPurple.withOpacity(0.5),
                          blurRadius: 30,
                          spreadRadius: 2,
                          offset: const Offset(0, 12),
                        ),
                        BoxShadow(
                          color: AppTheme.primaryPurple.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Total Balance',
                                          style: AppTypography.poppins(
                                            fontSize: 14,
                                            color: Colors.white.withOpacity(0.7),
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '${themeProvider.currencySymbol}${NumberFormat.currency(symbol: '').format(_totalBalance)}',
                                          style: AppTypography.poppins(
                                            fontSize: 34,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        _CircleIconButton(
                                          icon: Icons.event_note_rounded,
                                          onTap: () {
                                            Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarScreen()));
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                        _CircleIconButton(
                                          icon: Icons.people_alt_rounded,
                                          onTap: () {
                                            Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactsScreen()));
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                        _CircleIconButton(
                                          icon: Icons.notifications_none_rounded,
                                          onTap: () {
                                            showDialog(
                                              context: context,
                                              builder: (_) => const _NotificationPrefsDialog(),
                                            );
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                        _CircleIconButton(
                                          icon: Icons.settings_rounded,
                                          onTap: () {
                                            Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 28),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: _HeaderStat(
                                          label: 'Income',
                                          value: '${themeProvider.currencySymbol}${NumberFormat.compact().format(income)}',
                                          color: AppTheme.incomeGreen,
                                          icon: Icons.arrow_downward_rounded,
                                        ),
                                      ),
                                      Container(
                                        width: 1,
                                        height: 40,
                                        color: Colors.white.withOpacity(0.2),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(left: 20),
                                          child: _HeaderStat(
                                            label: 'Spent',
                                            value: '${themeProvider.currencySymbol}${NumberFormat.compact().format(expenses)}',
                                            color: AppTheme.expenseRed,
                                            icon: Icons.arrow_upward_rounded,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Report Chart
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Report this month',
                              style: AppTypography.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const ChartsScreen()));
                              },
                              child: Text(
                                'See details',
                                style: AppTypography.poppins(
                                  fontSize: 13,
                                  color: AppTheme.primaryPurple,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (income == 0 && expenses == 0)
                          SizedBox(
                            height: 200,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.bar_chart_rounded,
                                    size: 48,
                                    color: Colors.grey.withOpacity(0.3),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No chart data yet',
                                    style: AppTypography.poppins(
                                      fontSize: 14,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          SizedBox(
                            height: 200,
                            child: LineChart(
                              LineChartData(
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: 1,
                                  getDrawingHorizontalLine: (value) => FlLine(
                                    color: Colors.grey.withOpacity(0.1),
                                    strokeWidth: 1,
                                  ),
                                ),
                                titlesData: const FlTitlesData(show: false),
                                borderData: FlBorderData(show: false),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: _incomeSpots,
                                    isCurved: true,
                                    color: AppTheme.incomeGreen,
                                    barWidth: 3,
                                    isStrokeCapRound: true,
                                    dotData: const FlDotData(show: false),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: AppTheme.incomeGreen.withOpacity(0.1),
                                    ),
                                  ),
                                  LineChartBarData(
                                    spots: _expenseSpots,
                                    isCurved: true,
                                    color: AppTheme.expenseRed,
                                    barWidth: 3,
                                    isStrokeCapRound: true,
                                    dotData: const FlDotData(show: false),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: AppTheme.expenseRed.withOpacity(0.1),
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
              ),
            ),

            // Recent Transactions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Transactions',
                      style: AppTypography.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionsScreen()));
                      },
                      child: Text(
                        'See all',
                        style: AppTypography.poppins(
                          fontSize: 14,
                          color: AppTheme.primaryPurple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_isLoading)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
              )
            else if (_recentTransactions.isEmpty)
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          size: 64,
                          color: Colors.grey.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No transactions yet',
                          style: AppTypography.poppins(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final transaction = _recentTransactions[index];
                    final category = _categories[transaction.categoryId];
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: TransactionCard(
                        transaction: transaction,
                        category: category,
                        onDelete: () async {
                          final db = Provider.of<DatabaseService>(context, listen: false);
                          await db.deleteTransaction(transaction.id!);
                          _loadData();
                        },
                        onSettle: () async {
                          final remaining = transaction.amount - transaction.paidAmount;
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) {
                              final currentTheme = Provider.of<ThemeProvider>(context, listen: false);
                              return AlertDialog(
                                title: Text('Settle Debt', style: AppTypography.poppins(fontWeight: FontWeight.w600)),
                                content: Text(
                                  'Settle the remaining ${currentTheme.currencySymbol}${NumberFormat.currency(symbol: '').format(remaining)}?'
                                ),
                                actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Settle'),
                                ),
                              ],
                              );
                            },
                          );
                          if (confirm == true) {
                            final db = Provider.of<DatabaseService>(context, listen: false);
                            await db.updateTransaction(transaction.copyWith(
                              paidAmount: transaction.amount,
                            ));
                            _loadData();
                          }
                        },
                      ),
                    );
                  },
                  childCount: _recentTransactions.length,
                ),
              ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _HeaderStat({
    Key? key,
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 14),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.poppins(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _NotificationPrefsDialog extends StatefulWidget {
  const _NotificationPrefsDialog();

  @override
  State<_NotificationPrefsDialog> createState() => _NotificationPrefsDialogState();
}

class _NotificationPrefsDialogState extends State<_NotificationPrefsDialog> {
  late bool _budgetAlerts;
  late bool _recurringReminders;
  late bool _billDueDates;
  late bool _spendingInsights;

  @override
  void initState() {
    super.initState();
    final db = Provider.of<DatabaseService>(context, listen: false);
    _budgetAlerts = db.getNotificationPref('budget_alerts');
    _recurringReminders = db.getNotificationPref('recurring_reminders');
    _billDueDates = db.getNotificationPref('bill_due_dates');
    _spendingInsights = db.getNotificationPref('spending_insights');
  }

  Future<void> _save(String key, bool value) async {
    final db = Provider.of<DatabaseService>(context, listen: false);
    await db.setNotificationPref(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.notifications_active_rounded, color: AppTheme.primaryPurple, size: 24),
                ),
                const SizedBox(width: 14),
                Text(
                  'Notifications',
                  style: AppTypography.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Choose which alerts you\'d like to receive',
              style: AppTypography.poppins(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            _NotifToggle(
              icon: Icons.account_balance_wallet_rounded,
              color: AppTheme.expenseRed,
              title: 'Budget Alerts',
              subtitle: 'When approaching or exceeding limits',
              value: _budgetAlerts,
              onChanged: (v) {
                setState(() => _budgetAlerts = v);
                _save('budget_alerts', v);
              },
            ),
            const SizedBox(height: 12),
            _NotifToggle(
              icon: Icons.repeat_rounded,
              color: AppTheme.primaryPurple,
              title: 'Recurring Reminders',
              subtitle: 'Upcoming recurring payments',
              value: _recurringReminders,
              onChanged: (v) {
                setState(() => _recurringReminders = v);
                _save('recurring_reminders', v);
              },
            ),
            const SizedBox(height: 12),
            _NotifToggle(
              icon: Icons.calendar_today_rounded,
              color: AppTheme.warningYellow,
              title: 'Bill Due Dates',
              subtitle: 'Alerts before bills are due',
              value: _billDueDates,
              onChanged: (v) {
                setState(() => _billDueDates = v);
                _save('bill_due_dates', v);
              },
            ),
            const SizedBox(height: 12),
            _NotifToggle(
              icon: Icons.insights_rounded,
              color: AppTheme.incomeGreen,
              title: 'Spending Insights',
              subtitle: 'Smart budget usage summaries',
              value: _spendingInsights,
              onChanged: (v) {
                setState(() => _spendingInsights = v);
                _save('spending_insights', v);
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Done', style: AppTypography.poppins(fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotifToggle extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotifToggle({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: value ? color.withOpacity(0.06) : AppTheme.ultraLightPurple.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value ? color.withOpacity(0.3) : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTypography.poppins(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: color,
            activeTrackColor: color.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}
