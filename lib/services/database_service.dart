import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/budget.dart';
import '../models/account.dart';
import '../models/loan.dart';
import '../models/contact.dart';
import '../models/savings_goal.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // Hive box names
  static const String _transactionsBox = 'transactions';
  static const String _categoriesBox = 'categories';
  static const String _budgetsBox = 'budgets';
  static const String _accountsBox = 'accounts';
  static const String _loansBox = 'loans';
  static const String _contactsBox = 'contacts';
  static const String _counterBox = 'counters';
  static const String _settingsBox = 'settings';
  static const String _savingsBox = 'savings';

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    await Hive.initFlutter();
    await Hive.openBox<Map>(_transactionsBox);
    await Hive.openBox<Map>(_categoriesBox);
    await Hive.openBox<Map>(_budgetsBox);
    await Hive.openBox<Map>(_accountsBox);
    await Hive.openBox<Map>(_loansBox);
    await Hive.openBox<Map>(_contactsBox);
    await Hive.openBox<int>(_counterBox);
    await Hive.openBox(_settingsBox);
    await Hive.openBox<Map>(_savingsBox);

    final catBox = Hive.box<Map>(_categoriesBox);
    final accBox = Hive.box<Map>(_accountsBox);

    // Seed default data on first run
    if (catBox.isEmpty) {
      final defaults = [
        ...Category.getDefaultExpenseCategories(),
        ...Category.getDefaultIncomeCategories(),
      ];
      for (var c in defaults) {
        await catBox.put(c.id, c.toMap());
      }
    }
    if (accBox.isEmpty) {
      for (var a in Account.getDefaultAccounts()) {
        await accBox.put(a.id, a.toMap());
      }
    }
    _initialized = true;
  }

  // ─── Auto-increment helper ────────────────────────────────────────────────
  int _nextId(String key) {
    final box = Hive.box<int>(_counterBox);
    final next = (box.get(key) ?? 0) + 1;
    box.put(key, next);
    return next;
  }

  // ─── Helpers to cast nested maps safely from Hive ────────────────────────
  Map<String, dynamic> _safeCast(Map raw) =>
      raw.map((k, v) => MapEntry(k.toString(), v));

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Transactions
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<int> insertTransaction(TransactionModel transaction) async {
    final box = Hive.box<Map>(_transactionsBox);
    final id = _nextId('tx');
    final map = transaction.toMap();
    map['id'] = id;
    await box.put(id, map);
    await _applyCashImpact(
        transaction.accountId, _calculateTransactionCashImpact(transaction));
    return id;
  }

  Future<List<TransactionModel>> getTransactions({
    String? type,
    String? categoryId,
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final box = Hive.box<Map>(_transactionsBox);
    var results = box.values
        .map((m) => TransactionModel.fromMap(_safeCast(m)))
        .where((t) {
      if (type != null && t.type != type) return false;
      if (categoryId != null && t.categoryId != categoryId) return false;
      if (accountId != null && t.accountId != accountId) return false;
      if (startDate != null && t.date.isBefore(DateTime(startDate.year, startDate.month, startDate.day))) return false;
      if (endDate != null && t.date.isAfter(DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59))) return false;
      return true;
    }).toList();
    results.sort((a, b) => b.date.compareTo(a.date));
    return results;
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    final box = Hive.box<Map>(_transactionsBox);
    final existing = box.get(transaction.id);
    if (existing != null) {
      final oldTx = TransactionModel.fromMap(_safeCast(existing));
      if (oldTx.accountId == transaction.accountId) {
        await _applyCashImpact(transaction.accountId,
            _calculateTransactionCashImpact(transaction) -
                _calculateTransactionCashImpact(oldTx));
      } else {
        await _applyCashImpact(
            oldTx.accountId, -_calculateTransactionCashImpact(oldTx));
        await _applyCashImpact(
            transaction.accountId, _calculateTransactionCashImpact(transaction));
      }
    }
    await box.put(transaction.id, transaction.toMap());
  }

  Future<void> deleteTransaction(int id) async {
    final box = Hive.box<Map>(_transactionsBox);
    final existing = box.get(id);
    if (existing != null) {
      final t = TransactionModel.fromMap(_safeCast(existing));
      await _applyCashImpact(t.accountId, -_calculateTransactionCashImpact(t));
    }
    await box.delete(id);
  }

  double _calculateTransactionCashImpact(TransactionModel t) {
    if (t.type == 'expense') return -t.paidAmount;
    if (t.type == 'income') return t.paidAmount;
    if (t.type == 'loan_given') return -(t.amount - t.paidAmount);
    if (t.type == 'loan_taken') return (t.amount - t.paidAmount);
    return 0.0;
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Categories
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<List<Category>> getCategories({String? type}) async {
    final box = Hive.box<Map>(_categoriesBox);
    return box.values
        .map((m) => Category.fromMap(_safeCast(m)))
        .where((c) => type == null || c.type == type)
        .toList();
  }

  Future<Category?> getCategoryById(String id) async {
    final box = Hive.box<Map>(_categoriesBox);
    final raw = box.get(id);
    return raw != null ? Category.fromMap(_safeCast(raw)) : null;
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Budgets
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<int> insertBudget(Budget budget) async {
    final box = Hive.box<Map>(_budgetsBox);
    final id = _nextId('budget');
    final map = budget.toMap();
    map['id'] = id;
    await box.put(id, map);
    return id;
  }

  Future<List<Budget>> getBudgets() async {
    final box = Hive.box<Map>(_budgetsBox);
    final budgets =
        box.values.map((m) => Budget.fromMap(_safeCast(m))).toList();

    final now = DateTime.now();
    final result = <Budget>[];
    for (var budget in budgets) {
      DateTime periodStart;
      if (budget.period == 'weekly') {
        periodStart = now.subtract(Duration(days: now.weekday - 1));
        periodStart =
            DateTime(periodStart.year, periodStart.month, periodStart.day);
      } else {
        periodStart = DateTime(now.year, now.month, 1);
      }

      final txns = await getTransactions(
        categoryId: budget.categoryId,
        accountId: budget.accountId,
        startDate: periodStart,
      );
      final spent = txns
          .where((t) => t.type == 'expense')
          .fold(0.0, (s, t) => s + t.amount);
      result.add(budget.copyWith(spent: spent));
    }
    return result;
  }

  Future<void> updateBudget(Budget budget) async {
    final box = Hive.box<Map>(_budgetsBox);
    await box.put(budget.id, budget.toMap());
  }

  Future<void> deleteBudget(int id) async {
    await Hive.box<Map>(_budgetsBox).delete(id);
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Accounts
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<List<Account>> getAccounts() async {
    final box = Hive.box<Map>(_accountsBox);
    return box.values.map((m) => Account.fromMap(_safeCast(m))).toList();
  }

  Future<Account?> getAccountById(String id) async {
    final box = Hive.box<Map>(_accountsBox);
    final raw = box.get(id);
    return raw != null ? Account.fromMap(_safeCast(raw)) : null;
  }

  Future<void> insertAccount(Account account) async {
    await Hive.box<Map>(_accountsBox).put(account.id, account.toMap());
  }

  Future<void> updateAccount(Account account) async {
    await Hive.box<Map>(_accountsBox).put(account.id, account.toMap());
  }

  Future<void> _applyCashImpact(String accountId, double impact) async {
    if (impact == 0) return;
    final account = await getAccountById(accountId);
    if (account != null) {
      await updateAccount(account.copyWith(balance: account.balance + impact));
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Loans
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<int> insertLoan(Loan loan) async {
    final box = Hive.box<Map>(_loansBox);
    final id = _nextId('loan');
    final map = loan.toMap();
    map['id'] = id;
    await box.put(id, map);
    return id;
  }

  Future<List<Loan>> getLoans({String? type}) async {
    final box = Hive.box<Map>(_loansBox);
    var results = box.values
        .map((m) => Loan.fromMap(_safeCast(m)))
        .where((l) => type == null || l.type == type)
        .toList();
    results.sort((a, b) => b.createdDate.compareTo(a.createdDate));
    return results;
  }

  Future<void> updateLoan(Loan loan) async {
    await Hive.box<Map>(_loansBox).put(loan.id, loan.toMap());
  }

  Future<void> deleteLoan(int id) async {
    await Hive.box<Map>(_loansBox).delete(id);
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Contacts
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<void> insertContact(ContactModel contact) async {
    await Hive.box<Map>(_contactsBox).put(contact.id, contact.toMap());
  }

  Future<List<ContactModel>> getContacts() async {
    final box = Hive.box<Map>(_contactsBox);
    var results = box.values
        .map((m) => ContactModel.fromMap(_safeCast(m)))
        .toList();
    results.sort((a, b) => a.name.compareTo(b.name));
    return results;
  }

  Future<ContactModel?> getContactById(String id) async {
    final box = Hive.box<Map>(_contactsBox);
    final raw = box.get(id);
    return raw != null ? ContactModel.fromMap(_safeCast(raw)) : null;
  }

  Future<void> updateContact(ContactModel contact) async {
    await Hive.box<Map>(_contactsBox).put(contact.id, contact.toMap());
  }

  Future<void> deleteContact(String id) async {
    await Hive.box<Map>(_contactsBox).delete(id);
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Analytics
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<double> getTotalBalance() async {
    final accounts = await getAccounts();
    return accounts.fold<double>(0.0, (s, a) => s + a.balance);
  }

  Future<Map<String, double>> getMonthlyStats(DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0);
    final txns = await getTransactions(startDate: start, endDate: end);
    double income = 0, expenses = 0;
    for (var t in txns) {
      if (t.type == 'income') income += t.amount;
      if (t.type == 'expense') expenses += t.amount;
    }
    return {'income': income, 'expenses': expenses, 'savings': income - expenses};
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Notification Preferences
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  bool getNotificationPref(String key) {
    final box = Hive.box(_settingsBox);
    return box.get('notif_$key', defaultValue: false) as bool;
  }

  Future<void> setNotificationPref(String key, bool value) async {
    final box = Hive.box(_settingsBox);
    await box.put('notif_$key', value);
  }

  Map<String, bool> getAllNotificationPrefs() {
    return {
      'budget_alerts': getNotificationPref('budget_alerts'),
      'recurring_reminders': getNotificationPref('recurring_reminders'),
      'bill_due_dates': getNotificationPref('bill_due_dates'),
      'spending_insights': getNotificationPref('spending_insights'),
    };
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Savings Goals
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<void> insertSavingsGoal(SavingsGoal goal) async {
    await Hive.box<Map>(_savingsBox).put(goal.id, goal.toMap());
  }

  Future<List<SavingsGoal>> getSavingsGoals() async {
    final box = Hive.box<Map>(_savingsBox);
    return box.values.map((m) => SavingsGoal.fromMap(_safeCast(m))).toList();
  }

  Future<void> updateSavingsGoal(SavingsGoal goal) async {
    await Hive.box<Map>(_savingsBox).put(goal.id, goal.toMap());
  }

  Future<void> deleteSavingsGoal(String id) async {
    await Hive.box<Map>(_savingsBox).delete(id);
  }
}
