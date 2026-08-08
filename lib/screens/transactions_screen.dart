import 'package:flutter/material.dart';
import '../utils/typography.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../widgets/transaction_card.dart';
import 'add_transaction_screen.dart';
import '../services/export_service.dart';
import '../providers/theme_provider.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({Key? key}) : super(key: key);

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<TransactionModel> _transactions = [];
  String? _selectedType;
  String? _selectedCategory;
  String? _paymentStatus; // 'all', 'fully_paid', 'partially_paid'
  Map<String, Category> _categories = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final db = Provider.of<DatabaseService>(context, listen: false);
    
    var transactions = await db.getTransactions(
      type: _selectedType,
      categoryId: _selectedCategory,
    );
    
    // Apply payment status filter locally
    if (_paymentStatus == 'fully_paid') {
      transactions = transactions.where((t) => t.amount == t.paidAmount).toList();
    } else if (_paymentStatus == 'partially_paid') {
      transactions = transactions.where((t) => t.amount > t.paidAmount).toList();
    }
    
    final categories = await db.getCategories();
    final categoryMap = {for (var cat in categories) cat.id: cat};
    
    setState(() {
      _transactions = transactions;
      _categories = categoryMap;
      _isLoading = false;
    });
  }

  Map<String, List<TransactionModel>> _groupByDate() {
    final grouped = <String, List<TransactionModel>>{};
    
    for (var transaction in _transactions) {
      final dateKey = DateFormat('yyyy-MM-dd').format(transaction.date);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(transaction);
    }
    
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final groupedTransactions = _groupByDate();
    final sortedDates = groupedTransactions.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Transactions',
          style: AppTypography.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Export',
            onSelected: (value) async {
              if (value == 'csv') {
                await ExportService.exportTransactionsToCSV(
                  transactions: _transactions,
                  categories: _categories,
                );
              } else if (value == 'pdf') {
                await ExportService.exportTransactionsToPDF(
                  transactions: _transactions,
                  categories: _categories,
                  currencySymbol: themeProvider.currencySymbol,
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'csv',
                child: Row(
                  children: [
                    Icon(Icons.table_chart_rounded, size: 20),
                    SizedBox(width: 12),
                    Text('Export as CSV'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf_rounded, size: 20),
                    SizedBox(width: 12),
                    Text('Export as PDF'),
                  ],
                ),
              ),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list_rounded),
            onSelected: (value) {
              setState(() {
                if (value.startsWith('type_')) {
                  final type = value.replaceAll('type_', '');
                  _selectedType = type == 'all' ? null : type;
                } else if (value.startsWith('status_')) {
                  final status = value.replaceAll('status_', '');
                  _paymentStatus = status == 'all' ? null : status;
                } else if (value.startsWith('cat_')) {
                  final cat = value.replaceAll('cat_', '');
                  _selectedCategory = cat == 'all' ? null : cat;
                }
              });
              _loadData();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                 enabled: false,
                 child: Text('By Type', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              const PopupMenuItem(value: 'type_all', child: Text('All Types')),
              const PopupMenuItem(value: 'type_income', child: Text('Income')),
              const PopupMenuItem(value: 'type_expense', child: Text('Expenses')),
              const PopupMenuItem(value: 'type_loan_given', child: Text('Lend')),
              const PopupMenuItem(value: 'type_loan_taken', child: Text('Borrow')),
              
              const PopupMenuDivider(),
              const PopupMenuItem(
                 enabled: false,
                 child: Text('By Status', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              const PopupMenuItem(value: 'status_all', child: Text('All Statuses')),
              const PopupMenuItem(value: 'status_fully_paid', child: Text('Fully Paid')),
              const PopupMenuItem(value: 'status_partially_paid', child: Text('Partially Paid (Debt)')),

              const PopupMenuDivider(),
              const PopupMenuItem(
                 enabled: false,
                 child: Text('By Category', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              const PopupMenuItem(value: 'cat_all', child: Text('All Categories')),
              ..._categories.values.map((c) => PopupMenuItem(
                value: 'cat_${c.id}',
                child: Row(
                  children: [
                    Icon(c.icon, color: c.color, size: 16),
                    const SizedBox(width: 8),
                    Text(c.name),
                  ],
                ),
              )).toList(),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_rounded,
                        size: 80,
                        color: Colors.grey.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No transactions found',
                        style: AppTypography.poppins(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: sortedDates.length,
                    itemBuilder: (context, index) {
                      final dateKey = sortedDates[index];
                      final transactions = groupedTransactions[dateKey]!;
                      final date = DateTime.parse(dateKey);

                      // Calculate daily total
                      double dailyIncome = 0;
                      double dailyExpense = 0;
                      for (var trans in transactions) {
                        if (trans.type == 'income') {
                          dailyIncome += trans.amount;
                        } else if (trans.type == 'expense') {
                          dailyExpense += trans.amount;
                        }
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDateHeader(date),
                                  style: AppTypography.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Net: ${themeProvider.currencySymbol}${NumberFormat.currency(symbol: '').format(dailyIncome - dailyExpense)}',
                                  style: AppTypography.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: dailyIncome - dailyExpense >= 0
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...transactions.map((transaction) {
                            final category = _categories[transaction.categoryId];
                            return TransactionCard(
                              transaction: transaction,
                              category: category,
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddTransactionScreen(
                                      transaction: transaction,
                                    ),
                                  ),
                                );
                                if (result == true) _loadData();
                              },
                              onDelete: () async {
                                final db = Provider.of<DatabaseService>(
                                  context,
                                  listen: false,
                                );
                                await db.deleteTransaction(transaction.id!);
                                _loadData();
                              },
                              onSettle: () async {
                                final remaining = transaction.amount - transaction.paidAmount;
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('Settle Debt', style: AppTypography.poppins(fontWeight: FontWeight.w600)),
                                    content: Text(
                                      'Settle the remaining ${themeProvider.currencySymbol}${NumberFormat.currency(symbol: '').format(remaining)}?'
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
                                  ),
                                );
                                if (confirm == true) {
                                  final db = Provider.of<DatabaseService>(context, listen: false);
                                  await db.updateTransaction(transaction.copyWith(
                                    paidAmount: transaction.amount,
                                  ));
                                  _loadData();
                                }
                              },
                            );
                          }).toList(),
                        ],
                      );
                    },
                  ),
                ),
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) {
      return 'Today';
    } else if (checkDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('EEEE, MMM dd').format(date);
    }
  }
}
