import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String type; // 'expense' or 'income'

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconCode': icon.codePoint,
      'colorValue': color.value,
      'type': type,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: IconData(map['iconCode'] as int, fontFamily: 'MaterialIcons'),
      color: Color(map['colorValue'] as int),
      type: map['type'] as String,
    );
  }

  // Default categories
  static List<Category> getDefaultExpenseCategories() {
    return [
      Category(
        id: 'food',
        name: 'Food & Dining',
        icon: Icons.restaurant_rounded,
        color: const Color(0xFFFF6B6B),
        type: 'expense',
      ),
      Category(
        id: 'transport',
        name: 'Transportation',
        icon: Icons.directions_car_rounded,
        color: const Color(0xFF4ECDC4),
        type: 'expense',
      ),
      Category(
        id: 'shopping',
        name: 'Shopping',
        icon: Icons.shopping_bag_rounded,
        color: const Color(0xFFFFBE0B),
        type: 'expense',
      ),
      Category(
        id: 'entertainment',
        name: 'Entertainment',
        icon: Icons.movie_rounded,
        color: const Color(0xFFB565D8),
        type: 'expense',
      ),
      Category(
        id: 'bills',
        name: 'Bills & Utilities',
        icon: Icons.receipt_long_rounded,
        color: const Color(0xFFE74C3C),
        type: 'expense',
      ),
      Category(
        id: 'health',
        name: 'Healthcare',
        icon: Icons.local_hospital_rounded,
        color: const Color(0xFF2ECC71),
        type: 'expense',
      ),
      Category(
        id: 'education',
        name: 'Education',
        icon: Icons.school_rounded,
        color: const Color(0xFF3498DB),
        type: 'expense',
      ),
      Category(
        id: 'other',
        name: 'Other',
        icon: Icons.more_horiz_rounded,
        color: const Color(0xFF95A5A6),
        type: 'expense',
      ),
    ];
  }

  static List<Category> getDefaultIncomeCategories() {
    return [
      Category(
        id: 'salary',
        name: 'Salary',
        icon: Icons.payments_rounded,
        color: const Color(0xFF10B981),
        type: 'income',
      ),
      Category(
        id: 'freelance',
        name: 'Freelance',
        icon: Icons.work_rounded,
        color: const Color(0xFF34D399),
        type: 'income',
      ),
      Category(
        id: 'investment',
        name: 'Investment',
        icon: Icons.trending_up_rounded,
        color: const Color(0xFF059669),
        type: 'income',
      ),
      Category(
        id: 'gift',
        name: 'Gift',
        icon: Icons.card_giftcard_rounded,
        color: const Color(0xFF6EE7B7),
        type: 'income',
      ),
    ];
  }
}
