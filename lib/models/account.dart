class Account {
  final String id;
  final String name;
  final String type; // 'cash', 'bank', 'credit'
  final double balance;
  final int colorValue;

  Account({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.colorValue,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'balance': balance,
      'colorValue': colorValue,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
      balance: map['balance'] as double,
      colorValue: map['colorValue'] as int,
    );
  }

  Account copyWith({
    String? id,
    String? name,
    String? type,
    double? balance,
    int? colorValue,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  static List<Account> getDefaultAccounts() {
    return [
      Account(
        id: 'cash',
        name: 'Cash',
        type: 'cash',
        balance: 0.0,
        colorValue: 0xFF10B981,
      ),
      Account(
        id: 'bank',
        name: 'Bank Account',
        type: 'bank',
        balance: 0.0,
        colorValue: 0xFF3B82F6,
      ),
    ];
  }
}
