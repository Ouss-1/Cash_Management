class Budget {
  final int? id;
  final String accountId; // New field
  final String categoryId;
  final double amount;
  final String period; // 'weekly', 'monthly'
  final double spent;
  final DateTime startDate;

  Budget({
    this.id,
    required this.accountId,
    required this.categoryId,
    required this.amount,
    required this.period,
    this.spent = 0.0,
    required this.startDate,
  });

  double get percentage => amount > 0 ? (spent / amount).clamp(0.0, 1.0) : 0.0;
  double get remaining => (amount - spent).clamp(0.0, double.infinity);
  bool get isExceeded => spent > amount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'accountId': accountId,
      'categoryId': categoryId,
      'amount': amount,
      'period': period,
      'spent': spent,
      'startDate': startDate.toIso8601String(),
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as int?,
      accountId: map['accountId'] as String? ?? 'default', // Fallback for old data
      categoryId: map['categoryId'] as String,
      amount: map['amount'] as double,
      period: map['period'] as String,
      spent: map['spent'] as double,
      startDate: DateTime.parse(map['startDate'] as String),
    );
  }

  Budget copyWith({
    int? id,
    String? accountId,
    String? categoryId,
    double? amount,
    String? period,
    double? spent,
    DateTime? startDate,
  }) {
    return Budget(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      period: period ?? this.period,
      spent: spent ?? this.spent,
      startDate: startDate ?? this.startDate,
    );
  }
}
