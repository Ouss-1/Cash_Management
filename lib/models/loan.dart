class Loan {
  final int? id;
  final String title;
  final double amount;
  final String type; // 'given' or 'taken'
  final String person;
  final DateTime? dueDate;
  final bool isPaid;
  final double paidAmount;
  final DateTime createdDate;
  final String? notes;

  Loan({
    this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.person,
    this.dueDate,
    this.isPaid = false,
    this.paidAmount = 0.0,
    required this.createdDate,
    this.notes,
  });

  double get remainingAmount => (amount - paidAmount).clamp(0.0, double.infinity);
  double get percentage => amount > 0 ? (paidAmount / amount).clamp(0.0, 1.0) : 0.0;
  bool get isOverdue => dueDate != null && !isPaid && DateTime.now().isAfter(dueDate!);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type,
      'person': person,
      'dueDate': dueDate?.toIso8601String(),
      'isPaid': isPaid ? 1 : 0,
      'paidAmount': paidAmount,
      'createdDate': createdDate.toIso8601String(),
      'notes': notes,
    };
  }

  factory Loan.fromMap(Map<String, dynamic> map) {
    return Loan(
      id: map['id'] as int?,
      title: map['title'] as String,
      amount: map['amount'] as double,
      type: map['type'] as String,
      person: map['person'] as String,
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate'] as String) : null,
      isPaid: map['isPaid'] == 1,
      paidAmount: map['paidAmount'] as double,
      createdDate: DateTime.parse(map['createdDate'] as String),
      notes: map['notes'] as String?,
    );
  }

  Loan copyWith({
    int? id,
    String? title,
    double? amount,
    String? type,
    String? person,
    DateTime? dueDate,
    bool? isPaid,
    double? paidAmount,
    DateTime? createdDate,
    String? notes,
  }) {
    return Loan(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      person: person ?? this.person,
      dueDate: dueDate ?? this.dueDate,
      isPaid: isPaid ?? this.isPaid,
      paidAmount: paidAmount ?? this.paidAmount,
      createdDate: createdDate ?? this.createdDate,
      notes: notes ?? this.notes,
    );
  }
}
