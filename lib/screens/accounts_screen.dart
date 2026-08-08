import 'package:flutter/material.dart';
import '../utils/typography.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../services/database_service.dart';
import '../models/account.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({Key? key}) : super(key: key);

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  List<Account> _accounts = [];
  bool _isLoading = true;
  double _totalBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final db = Provider.of<DatabaseService>(context, listen: false);
    
    final accounts = await db.getAccounts();
    final total = accounts.fold(0.0, (sum, account) => sum + account.balance);
    
    setState(() {
      _accounts = accounts;
      _totalBalance = total;
      _isLoading = false;
    });
  }

  void _showAddAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddAccountDialog(
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
          'Accounts',
          style: AppTypography.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: _showAddAccountDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Total Balance Card
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryPurple.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Balance',
                        style: AppTypography.poppins(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${themeProvider.currencySymbol}${NumberFormat.currency(symbol: '').format(_totalBalance)}',
                        style: AppTypography.poppins(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Across ${_accounts.length} ${_accounts.length == 1 ? 'account' : 'accounts'}',
                        style: AppTypography.poppins(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),

                // Accounts List
                Expanded(
                  child: _accounts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.account_balance_rounded,
                                size: 80,
                                color: Colors.grey.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No accounts yet',
                                style: AppTypography.poppins(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: _showAddAccountDialog,
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Add Account'),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _accounts.length,
                            itemBuilder: (context, index) {
                              final account = _accounts[index];
                              final accountColor = Color(account.colorValue);
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: accountColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      _getAccountIcon(account.type),
                                      color: accountColor,
                                      size: 24,
                                    ),
                                  ),
                                  title: Text(
                                    account.name,
                                    style: AppTypography.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    account.type.toUpperCase(),
                                    style: AppTypography.poppins(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${themeProvider.currencySymbol}${NumberFormat.currency(symbol: '').format(account.balance)}',
                                        style: AppTypography.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: account.balance >= 0 
                                              ? AppTheme.incomeGreen 
                                              : AppTheme.expenseRed,
                                        ),
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => _EditAccountDialog(
                                        account: account,
                                        onSave: _loadData,
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  IconData _getAccountIcon(String type) {
    switch (type) {
      case 'cash':
        return Icons.money_rounded;
      case 'bank':
        return Icons.account_balance_rounded;
      case 'credit':
        return Icons.credit_card_rounded;
      default:
        return Icons.account_balance_wallet_rounded;
    }
  }
}

class _AddAccountDialog extends StatefulWidget {
  final VoidCallback onSave;

  const _AddAccountDialog({
    required this.onSave,
  });

  @override
  State<_AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends State<_AddAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  String _selectedType = 'bank';
  Color _selectedColor = const Color(0xFF3B82F6);

  final List<Color> _colorOptions = [
    const Color(0xFF3B82F6), // Blue
    const Color(0xFF10B981), // Green
    const Color(0xFFEF4444), // Red
    const Color(0xFFF59E0B), // Orange
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFFEC4899), // Pink
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Add Account',
        style: AppTypography.poppins(fontWeight: FontWeight.w600),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Account Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.label_rounded),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: 'Account Type',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'bank', child: Text('Bank Account')),
                  DropdownMenuItem(value: 'credit', child: Text('Credit Card')),
                ],
                onChanged: (value) {
                  setState(() => _selectedType = value!);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _balanceController,
                decoration: InputDecoration(
                  labelText: 'Initial Balance',
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
              Text(
                'Choose Color',
                style: AppTypography.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _colorOptions.map((color) {
                  final isSelected = _selectedColor.value == color.value;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedColor = color);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 20,
                            )
                          : null,
                    ),
                  );
                }).toList(),
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
            if (_formKey.currentState!.validate()) {
              final db = Provider.of<DatabaseService>(context, listen: false);
              
              final account = Account(
                id: const Uuid().v4(),
                name: _nameController.text,
                type: _selectedType,
                balance: double.parse(_balanceController.text),
                colorValue: _selectedColor.value,
              );
              
              await db.insertAccount(account);
              
              if (mounted) {
                Navigator.pop(context);
                widget.onSave();
              }
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Edit Account Dialog
// ──────────────────────────────────────────────────────────────────────────────
class _EditAccountDialog extends StatefulWidget {
  final Account account;
  final VoidCallback onSave;
  const _EditAccountDialog({required this.account, required this.onSave});

  @override
  State<_EditAccountDialog> createState() => _EditAccountDialogState();
}

class _EditAccountDialogState extends State<_EditAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;
  late String _selectedType;
  late Color _selectedColor;

  final List<Color> _colorOptions = const [
    Color(0xFF3B82F6), Color(0xFF10B981), Color(0xFFEF4444),
    Color(0xFFF59E0B), Color(0xFF8B5CF6), Color(0xFFEC4899),
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account.name);
    _balanceController = TextEditingController(text: widget.account.balance.toStringAsFixed(2));
    _selectedType = widget.account.type;
    _selectedColor = Color(widget.account.colorValue);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Account', style: AppTypography.poppins(fontWeight: FontWeight.w600)),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Account Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.label_rounded),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: 'Account Type',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'bank', child: Text('Bank Account')),
                  DropdownMenuItem(value: 'credit', child: Text('Credit Card')),
                ],
                onChanged: (v) => setState(() => _selectedType = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _balanceController,
                decoration: InputDecoration(
                  labelText: 'Balance',
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
              Text('Choose Color', style: AppTypography.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                children: _colorOptions.map((color) {
                  final selected = _selectedColor.value == color.value;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: selected ? Colors.white : Colors.transparent, width: 3),
                        boxShadow: selected ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8, spreadRadius: 2)] : null,
                      ),
                      child: selected ? const Icon(Icons.check_rounded, color: Colors.white, size: 20) : null,
                    ),
                  );
                }).toList(),
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
              await db.updateAccount(widget.account.copyWith(
                name: _nameController.text,
                type: _selectedType,
                balance: double.parse(_balanceController.text),
                colorValue: _selectedColor.value,
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
