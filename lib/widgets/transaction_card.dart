import 'package:flutter/material.dart';
import '../utils/typography.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class TransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  final Category? category;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onSettle;

  const TransactionCard({
    Key? key,
    required this.transaction,
    this.category,
    this.onTap,
    this.onDelete,
    this.onSettle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isExpense = transaction.type == 'expense';
    final isIncome = transaction.type == 'income';
    final amountColor = isIncome 
        ? AppTheme.incomeGreen 
        : isExpense 
            ? AppTheme.expenseRed 
            : AppTheme.warningYellow;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Category Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (category?.color ?? Colors.grey).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  category?.icon ?? Icons.help_outline,
                  color: category?.color ?? Colors.grey,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              
              // Transaction Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.title,
                      style: AppTypography.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          category?.name ?? 'Unknown',
                          style: AppTypography.poppins(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        if (transaction.notes != null && transaction.notes!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.note_outlined,
                            size: 14,
                            color: Colors.grey,
                          ),
                        ],
                        if (transaction.isRecurring) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.repeat_rounded,
                            size: 14,
                            color: Colors.grey,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('MMM dd, yyyy').format(transaction.date),
                      style: AppTypography.poppins(
                        fontSize: 11,
                        color: Colors.grey.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isExpense ? '-' : '+'}${themeProvider.currencySymbol}${NumberFormat.currency(symbol: '').format(transaction.amount)}',
                    style: AppTypography.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: amountColor,
                    ),
                  ),
                  if (transaction.amount > transaction.paidAmount) ...[
                    Text(
                      'Paid: ${themeProvider.currencySymbol}${NumberFormat.currency(symbol: '').format(transaction.paidAmount)}',
                      style: AppTypography.poppins(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                    if (onSettle != null)
                      InkWell(
                        onTap: onSettle,
                        child: Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryPurple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Settle Debt',
                            style: AppTypography.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryPurple,
                            ),
                          ),
                        ),
                      ),
                  ] else if (onDelete != null)
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.red.withOpacity(0.6),
                        size: 20,
                      ),
                      onPressed: onDelete,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
