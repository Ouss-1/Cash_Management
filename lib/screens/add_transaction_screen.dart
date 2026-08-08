import 'package:flutter/material.dart';
import '../utils/typography.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../services/database_service.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/account.dart';
import '../models/contact.dart';
import '../theme/app_theme.dart';
import '../widgets/category_icon.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionModel? transaction; // null = add mode, non-null = edit mode
  const AddTransactionScreen({Key? key, this.transaction}) : super(key: key);

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _paidAmountController = TextEditingController(); // New field for partial payments
  final _notesController = TextEditingController();
  
  String _selectedType = 'expense';
  Category? _selectedCategory;
  Account? _selectedAccount;
  ContactModel? _selectedContact; // New field for contact association
  DateTime _selectedDate = DateTime.now();
  bool _isRecurring = false;
  String? _recurringPeriod;

  List<Category> _categories = [];
  List<Account> _accounts = [];
  List<ContactModel> _contacts = []; // Contact list state
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
    // Pre-fill from existing transaction if in edit mode
    final t = widget.transaction;
    if (t != null) {
      _titleController.text = t.title;
      _amountController.text = t.amount.toString();
      _paidAmountController.text = t.paidAmount.toString();
      _notesController.text = t.notes ?? '';
      _selectedType = t.type;
      _selectedDate = t.date;
      _isRecurring = t.isRecurring;
      _recurringPeriod = t.recurringPeriod;
    }
    _loadData();
  }

  void _onAmountChanged() {
    // Attempt to automatically fill the paid amount if it's currently empty or matching
    // For simplicity, we just initialize it when users write something in amount.
    // Real logic might need to check if user manually edited the paidAmount.
  }

  Future<void> _loadData() async {
    final db = Provider.of<DatabaseService>(context, listen: false);
    final t = widget.transaction;

    final type = t?.type ?? _selectedType;
    final categories = await db.getCategories(
      type: (type == 'loan_given' || type == 'loan_taken') ? null : type,
    );
    final accounts = await db.getAccounts();
    final contacts = await db.getContacts();

    setState(() {
      _categories = categories;
      _accounts = accounts;
      _contacts = contacts;
      if (t != null) {
        _selectedCategory = categories.firstWhere(
          (c) => c.id == t.categoryId,
          orElse: () => categories.isNotEmpty ? categories.first : _selectedCategory!,
        );
        _selectedAccount = accounts.firstWhere(
          (a) => a.id == t.accountId,
          orElse: () => accounts.isNotEmpty ? accounts.first : _selectedAccount!,
        );
        if (t.contactId != null) {
          final idx = contacts.indexWhere((c) => c.id == t.contactId);
          _selectedContact = idx >= 0 ? contacts[idx] : null;
        }
      } else {
        _selectedCategory = categories.isNotEmpty ? categories.first : null;
        _selectedAccount = accounts.isNotEmpty ? accounts.first : null;
      }
      _isLoading = false;
    });
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null || _selectedAccount == null) return;

    final amount = double.parse(_amountController.text);
    double paidAmount = (_selectedType == 'loan_given' || _selectedType == 'loan_taken') ? 0.0 : amount;
    
    if (_paidAmountController.text.isNotEmpty) {
       paidAmount = double.tryParse(_paidAmountController.text) ?? paidAmount;
    }

    final db = Provider.of<DatabaseService>(context, listen: false);

    final updated = TransactionModel(
      id: widget.transaction?.id, // preserve existing ID when editing
      title: _titleController.text,
      amount: amount,
      paidAmount: paidAmount,
      categoryId: _selectedCategory!.id,
      type: _selectedType,
      date: _selectedDate,
      accountId: _selectedAccount!.id,
      contactId: _selectedContact?.id,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      isRecurring: _isRecurring,
      recurringPeriod: _isRecurring ? _recurringPeriod : null,
    );

    if (widget.transaction != null) {
      await db.updateTransaction(updated);
    } else {
      await db.insertTransaction(updated);
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.transaction != null ? 'Edit Transaction' : 'Add Transaction',
          style: AppTypography.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: _saveTransaction,
            child: Text(
              'Save',
              style: AppTypography.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type Selector
                    Text(
                      'Type',
                      style: AppTypography.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _TypeChip(
                            label: 'Expense',
                            icon: Icons.arrow_upward_rounded,
                            color: AppTheme.expenseRed,
                            isSelected: _selectedType == 'expense',
                            onTap: () {
                              setState(() => _selectedType = 'expense');
                              _loadData();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _TypeChip(
                            label: 'Income',
                            icon: Icons.arrow_downward_rounded,
                            color: AppTheme.incomeGreen,
                            isSelected: _selectedType == 'income',
                            onTap: () {
                              setState(() => _selectedType = 'income');
                              _loadData();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _TypeChip(
                            label: 'Lend',
                            icon: Icons.upload_rounded,
                            color: Colors.orange,
                            isSelected: _selectedType == 'loan_given',
                            onTap: () {
                              setState(() => _selectedType = 'loan_given');
                              _loadData(); // Will fetch expense categories by default
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _TypeChip(
                            label: 'Borrow',
                            icon: Icons.download_rounded,
                            color: Colors.blue,
                            isSelected: _selectedType == 'loan_taken',
                            onTap: () {
                              setState(() => _selectedType = 'loan_taken');
                              _loadData(); // Will fetch income categories by default
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.title_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Amount
                    TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: 'Amount',
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

                    // Category
                    Text(
                      'Category',
                      style: AppTypography.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _categories.map((category) {
                        final isSelected = _selectedCategory?.id == category.id;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedCategory = category);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? category.color.withOpacity(0.2)
                                  : Theme.of(context).cardColor,
                              border: Border.all(
                                color: isSelected
                                    ? category.color
                                    : Colors.grey.withOpacity(0.3),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  category.icon,
                                  color: category.color,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  category.name,
                                  style: AppTypography.poppins(
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Paid Amount (Optional)
                    TextFormField(
                      controller: _paidAmountController,
                      decoration: InputDecoration(
                        labelText: (_selectedType == 'loan_given' || _selectedType == 'loan_taken')
                            ? 'Amount Paid Immediately'
                            : 'Paid Amount',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.money_off_csred_rounded),
                        helperText: (_selectedType == 'loan_given' || _selectedType == 'loan_taken')
                            ? 'Defaults to 0 if empty (Full loan owed)'
                            : 'Defaults to Total Amount if empty',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Account
                    DropdownButtonFormField<Account>(
                      value: _selectedAccount,
                      decoration: InputDecoration(
                        labelText: 'Account',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.account_balance_rounded),
                      ),
                      items: _accounts.map((account) {
                        return DropdownMenuItem(
                          value: account,
                          child: Text(account.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedAccount = value);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Contact (Optional)
                    DropdownButtonFormField<ContactModel>(
                      value: _selectedContact,
                      decoration: InputDecoration(
                        labelText: 'Contact (Optional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                        helperText: 'Link this transaction to a person',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() => _selectedContact = null);
                          },
                        ),
                      ),
                      items: _contacts.map((contact) {
                        return DropdownMenuItem<ContactModel>(
                          value: contact,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: Color(contact.colorValue),
                                child: Text(contact.name[0].toUpperCase(), style: const TextStyle(fontSize: 12, color: Colors.white)),
                              ),
                              const SizedBox(width: 8),
                              Text(contact.name),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedContact = value);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Date
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today_rounded),
                      title: Text(
                        'Date',
                        style: AppTypography.poppins(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      ),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          setState(() => _selectedDate = date);
                        }
                      },
                    ),

                    // Notes
                    TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: 'Notes (Optional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.note_rounded),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    // Recurring
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Recurring Transaction',
                        style: AppTypography.poppins(fontWeight: FontWeight.w500),
                      ),
                      value: _isRecurring,
                      onChanged: (value) {
                        setState(() {
                          _isRecurring = value;
                          if (value) {
                            _recurringPeriod = 'monthly';
                          } else {
                            _recurringPeriod = null;
                          }
                        });
                      },
                    ),

                    if (_isRecurring)
                      DropdownButtonFormField<String>(
                        value: _recurringPeriod,
                        decoration: InputDecoration(
                          labelText: 'Recurring Period',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'daily', child: Text('Daily')),
                          DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                          DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                          DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                        ],
                        onChanged: (value) {
                          setState(() => _recurringPeriod = value);
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.3),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTypography.poppins(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
