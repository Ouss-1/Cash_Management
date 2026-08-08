import 'package:flutter/material.dart';
import '../utils/typography.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../models/account.dart';
import '../widgets/dotted_progress_bar.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({Key? key}) : super(key: key);

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  List<Budget> _budgets = [];
  Map<String, Category> _categories = {};
  Map<String, Account> _accounts = {}; // New accounts map
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final db = Provider.of<DatabaseService>(context, listen: false);
    
    final budgets = await db.getBudgets();
    final categories = await db.getCategories();
    final accounts = await db.getAccounts(); // Load accounts
    final categoryMap = {for (var cat in categories) cat.id: cat};
    final accountMap = {for (var acc in accounts) acc.id: acc}; // Map accounts
    
    setState(() {
      _budgets = budgets;
      _categories = categoryMap;
      _accounts = accountMap; // Update state
      _isLoading = false;
    });
  }

  void _showAddBudgetDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddBudgetDialog(
        categories: _categories.values.where((c) => c.type == 'expense').toList(),
        accounts: _accounts.values.toList(), // Pass accounts
        onSave: () {
          _loadData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Budgets',
          style: AppTypography.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: _showAddBudgetDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _budgets.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 80,
                        color: Colors.grey.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No budgets set',
                        style: AppTypography.poppins(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _showAddBudgetDialog,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Create Budget'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _budgets.length,
                    itemBuilder: (context, index) {
                      final budget = _budgets[index];
                      final category = _categories[budget.categoryId];
                      final isDark = Theme.of(context).brightness == Brightness.dark;

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.lightPurple.withOpacity(0.4),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryPurple.withOpacity(0.04),
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: category?.color.withOpacity(0.2) ?? 
                                          Colors.grey.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
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
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              budget.period.toUpperCase(),
                                              style: AppTypography.poppins(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Icon(Icons.account_balance_rounded, size: 12, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(
                                              _accounts[budget.accountId]?.name ?? 'Unknown',
                                              style: AppTypography.poppins(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.edit_outlined,
                                      color: AppTheme.primaryPurple.withOpacity(0.7),
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => _EditBudgetDialog(
                                          budget: budget,
                                          categories: _categories.values.toList(),
                                          accounts: _accounts.values.toList(),
                                          onSave: _loadData,
                                        ),
                                      );
                                    },
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: Colors.red.withOpacity(0.6),
                                      size: 20,
                                    ),
                                    onPressed: () async {
                                      final db = Provider.of<DatabaseService>(
                                        context,
                                        listen: false,
                                      );
                                      await db.deleteBudget(budget.id!);
                                      _loadData();
                                    },
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Spent: ${themeProvider.currencySymbol}${NumberFormat.currency(symbol: '').format(budget.spent)}',
                                    style: AppTypography.poppins(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    'Budget: ${themeProvider.currencySymbol}${NumberFormat.currency(symbol: '').format(budget.amount)}',
                                    style: AppTypography.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Custom Dotted Progress Bar
                              DottedProgressBar(
                                percentage: budget.percentage,
                                filledColor: budget.isExceeded 
                                    ? AppTheme.expenseRed 
                                    : category?.color ?? AppTheme.primaryPurple,
                                showPercentage: false,
                                dotCount: 20, // Fewer dots for a more segmented look
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    budget.isExceeded 
                                        ? 'Over by ${themeProvider.currencySymbol}${NumberFormat.currency(symbol: '').format(budget.spent - budget.amount)}'
                                        : 'Remaining: ${themeProvider.currencySymbol}${NumberFormat.currency(symbol: '').format(budget.remaining)}',
                                    style: AppTypography.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: budget.isExceeded 
                                          ? AppTheme.expenseRed 
                                          : AppTheme.incomeGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _AddBudgetDialog extends StatefulWidget {
  final List<Category> categories;
  final List<Account> accounts; // Added accounts list
  final VoidCallback onSave;

  const _AddBudgetDialog({
    required this.categories,
    required this.accounts,
    required this.onSave,
  });

  @override
  State<_AddBudgetDialog> createState() => _AddBudgetDialogState();
}

class _AddBudgetDialogState extends State<_AddBudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  Category? _selectedCategory;
  Account? _selectedAccount; // Added selected account
  String _selectedPeriod = 'monthly';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Create Budget',
        style: AppTypography.poppins(fontWeight: FontWeight.w600),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView( // Added scroll view for space
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Account Selection
              DropdownButtonFormField<Account>(
                value: _selectedAccount,
                decoration: InputDecoration(
                  labelText: 'Account',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: widget.accounts.map((account) {
                  return DropdownMenuItem(
                    value: account,
                    child: Text(account.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedAccount = value);
                },
                validator: (value) {
                  if (value == null) return 'Please select an account';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Category Selection
              DropdownButtonFormField<Category>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: widget.categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Icon(category.icon, color: category.color, size: 20),
                        const SizedBox(width: 12),
                        Text(category.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCategory = value);
                },
                validator: (value) {
                  if (value == null) return 'Please select a category';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Budget Amount',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedPeriod,
                decoration: InputDecoration(
                  labelText: 'Period',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                  DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                ],
                onChanged: (value) {
                  setState(() => _selectedPeriod = value!);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate() && 
                _selectedCategory != null && 
                _selectedAccount != null) {
              final db = Provider.of<DatabaseService>(context, listen: false);
              
              final budget = Budget(
                accountId: _selectedAccount!.id,
                categoryId: _selectedCategory!.id,
                amount: double.parse(_amountController.text),
                period: _selectedPeriod,
                startDate: DateTime.now(),
              );
              
              await db.insertBudget(budget);
              
              if (mounted) {
                Navigator.pop(context);
                widget.onSave();
              }
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Edit Budget Dialog
// ──────────────────────────────────────────────────────────────────────────────
class _EditBudgetDialog extends StatefulWidget {
  final Budget budget;
  final List<Category> categories;
  final List<Account> accounts;
  final VoidCallback onSave;
  const _EditBudgetDialog({
    required this.budget,
    required this.categories,
    required this.accounts,
    required this.onSave,
  });

  @override
  State<_EditBudgetDialog> createState() => _EditBudgetDialogState();
}

class _EditBudgetDialogState extends State<_EditBudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late String _selectedPeriod;
  late String _selectedCategoryId;
  late String _selectedAccountId;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.budget.amount.toStringAsFixed(2));
    _selectedPeriod = widget.budget.period;
    _selectedCategoryId = widget.budget.categoryId;
    _selectedAccountId = widget.budget.accountId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Budget', style: AppTypography.poppins(fontWeight: FontWeight.w600)),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: widget.categories.any((c) => c.id == _selectedCategoryId)
                    ? _selectedCategoryId
                    : null,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: widget.categories.map((c) => DropdownMenuItem(
                  value: c.id,
                  child: Row(children: [
                    Icon(c.icon, color: c.color, size: 18),
                    const SizedBox(width: 8),
                    Text(c.name),
                  ]),
                )).toList(),
                onChanged: (v) => setState(() => _selectedCategoryId = v!),
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedPeriod,
                decoration: InputDecoration(
                  labelText: 'Period',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: const [
                  DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                ],
                onChanged: (v) => setState(() => _selectedPeriod = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Budget Amount',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.attach_money_rounded),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: widget.accounts.any((a) => a.id == _selectedAccountId)
                    ? _selectedAccountId
                    : null,
                decoration: InputDecoration(
                  labelText: 'Account',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: widget.accounts.map((a) => DropdownMenuItem(
                  value: a.id,
                  child: Text(a.name),
                )).toList(),
                onChanged: (v) => setState(() => _selectedAccountId = v!),
                validator: (v) => v == null ? 'Required' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final db = Provider.of<DatabaseService>(context, listen: false);
              await db.updateBudget(widget.budget.copyWith(
                categoryId: _selectedCategoryId,
                period: _selectedPeriod,
                amount: double.parse(_amountController.text),
                accountId: _selectedAccountId,
              ));
              if (mounted) {
                Navigator.pop(context);
                widget.onSave();
              }
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
