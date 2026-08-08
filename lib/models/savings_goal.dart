import 'package:flutter/material.dart';

class SavingsGoal {
  final String id;
  final String title;
  final double targetAmount;
  final double savedAmount;
  final int colorValue;

  SavingsGoal({
    required this.id,
    required this.title,
    required this.targetAmount,
    this.savedAmount = 0.0,
    required this.colorValue,
  });

  SavingsGoal copyWith({
    String? id,
    String? title,
    double? targetAmount,
    double? savedAmount,
    int? colorValue,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'targetAmount': targetAmount,
      'savedAmount': savedAmount,
      'colorValue': colorValue,
    };
  }

  factory SavingsGoal.fromMap(Map<String, dynamic> map) {
    return SavingsGoal(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      targetAmount: map['targetAmount']?.toDouble() ?? 0.0,
      savedAmount: map['savedAmount']?.toDouble() ?? 0.0,
      colorValue: map['colorValue'] ?? Colors.blue.value,
    );
  }

  double get percentage => targetAmount > 0 ? (savedAmount / targetAmount) : 0.0;
  bool get isCompleted => savedAmount >= targetAmount;
}
