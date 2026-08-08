import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/database_service.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';
import '../utils/typography.dart';
import '../providers/theme_provider.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<TransactionModel> _allTransactions = [];
  Map<String, Category> _categories = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadData();
  }

  Future<void> _loadData() async {
    final db = Provider.of<DatabaseService>(context, listen: false);
    final transactions = await db.getTransactions();
    final categories = await db.getCategories();
    
    // Convert list to map for easier lookup
    final catMap = {for (var cat in categories) cat.id: cat};
    
    setState(() {
      _allTransactions = transactions;
      _categories = catMap;
      _isLoading = false;
    });
  }

  // Returns all bills/recurring payments for a specific day
  List<TransactionModel> _getEventsForDay(DateTime day) {
    return _allTransactions.where((t) {
      // Only care about expenses or recurring items
      if (t.type != 'expense' && !t.isRecurring) return false;
      
      // Match the date
      return isSameDay(t.date, day);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final themeProvider = Provider.of<ThemeProvider>(context);
    final selectedEvents = _getEventsForDay(_selectedDay ?? _focusedDay);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Bills & Subscriptions',
          style: AppTypography.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: TableCalendar<TransactionModel>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: CalendarFormat.month,
              eventLoader: _getEventsForDay,
              startingDayOfWeek: StartingDayOfWeek.monday,
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: AppTypography.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              calendarStyle: CalendarStyle(
                markerDecoration: const BoxDecoration(
                  color: AppTheme.expenseRed,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: AppTheme.primaryPurple,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: AppTheme.primaryPurple.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
              ),
              onDaySelected: (selectedDay, focusedDay) {
                if (!isSameDay(_selectedDay, selectedDay)) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                }
              },
            ),
          ),
          Expanded(
            child: selectedEvents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_available_rounded,
                          size: 64,
                          color: Colors.grey.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No bills due on this day',
                          style: AppTypography.poppins(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: selectedEvents.length,
                    itemBuilder: (context, index) {
                      final event = selectedEvents[index];
                      final category = _categories[event.categoryId];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: (category?.color ?? Colors.grey).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              category?.icon ?? Icons.help_outline,
                              color: category?.color ?? Colors.grey,
                            ),
                          ),
                          title: Text(
                            event.title,
                            style: AppTypography.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: event.isRecurring
                              ? Row(
                                  children: [
                                    const Icon(Icons.repeat_rounded, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text('Recurring', style: AppTypography.poppins(fontSize: 12, color: Colors.grey)),
                                  ],
                                )
                              : null,
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${themeProvider.currencySymbol}${NumberFormat.currency(symbol: '').format(event.amount)}',
                                style: AppTypography.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: AppTheme.expenseRed,
                                ),
                              ),
                              if (event.paidAmount < event.amount) ...[
                                Text(
                                  'Unpaid: ${themeProvider.currencySymbol}${NumberFormat.currency(symbol: '').format(event.amount - event.paidAmount)}',
                                  style: AppTypography.poppins(
                                    fontSize: 12,
                                    color: Colors.orange,
                                  ),
                                ),
                              ] else ...[
                                Text(
                                  'Paid',
                                  style: AppTypography.poppins(
                                    fontSize: 12,
                                    color: AppTheme.incomeGreen,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
