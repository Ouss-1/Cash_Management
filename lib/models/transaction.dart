class TransactionModel {
  final int? id;
  final String title;
  final double amount; // Total amount/price
  final double paidAmount; // How much was actually paid
  final String categoryId;
  final String type; // 'expense', 'income', 'loan_given', 'loan_taken'
  final DateTime date;
  final String accountId;
  final String? contactId; // Associated contact (who you owe or owes you)
  final String? notes;
  final bool isRecurring;
  final String? recurringPeriod; // 'daily', 'weekly', 'monthly', 'yearly'

  TransactionModel({
    this.id,
    required this.title,
    required this.amount,
    required this.paidAmount,
    required this.categoryId,
    required this.type,
    required this.date,
    required this.accountId,
    this.contactId,
    this.notes,
    this.isRecurring = false,
    this.recurringPeriod,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'paidAmount': paidAmount,
      'categoryId': categoryId,
      'type': type,
      'date': date.toIso8601String(),
      'accountId': accountId,
      'contactId': contactId,
      'notes': notes,
      'isRecurring': isRecurring ? 1 : 0,
      'recurringPeriod': recurringPeriod,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      amount: map['amount'] as double,
      paidAmount: map['paidAmount'] != null ? map['paidAmount'] as double : map['amount'] as double,
      categoryId: map['categoryId'] as String,
      type: map['type'] as String,
      date: DateTime.parse(map['date'] as String),
      accountId: map['accountId'] as String,
      contactId: map['contactId'] as String?,
      notes: map['notes'] as String?,
      isRecurring: map['isRecurring'] == 1,
      recurringPeriod: map['recurringPeriod'] as String?,
    );
  }

  TransactionModel copyWith({
    int? id,
    String? title,
    double? amount,
    double? paidAmount,
    String? categoryId,
    String? type,
    DateTime? date,
    String? accountId,
    String? contactId,
    String? notes,
    bool? isRecurring,
    String? recurringPeriod,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      paidAmount: paidAmount ?? this.paidAmount,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      date: date ?? this.date,
      accountId: accountId ?? this.accountId,
      contactId: contactId ?? this.contactId,
      notes: notes ?? this.notes,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringPeriod: recurringPeriod ?? this.recurringPeriod,
    );
  }
}

