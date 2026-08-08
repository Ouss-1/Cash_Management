import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../services/database_service.dart';
import '../models/savings_goal.dart';
import '../theme/app_theme.dart';
import '../utils/typography.dart';
import '../providers/theme_provider.dart';

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  List<SavingsGoal> _goals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = Provider.of<DatabaseService>(context, listen: false);
    final goals = await db.getSavingsGoals();
    setState(() {
      _goals = goals;
      _isLoading = false;
    });
  }

  void _showAddGoalDialog({SavingsGoal? existingGoal}) {
    showDialog(
      context: context,
      builder: (_) => _AddGoalDialog(
        goal: existingGoal,
        onSave: _loadData,
      ),
    );
  }

  void _showAddFundsDialog(SavingsGoal goal) {
    showDialog(
      context: context,
      builder: (_) => _AddFundsDialog(
        goal: goal,
        onSave: _loadData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Savings Goals',
          style: AppTypography.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddGoalDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _goals.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _goals.length,
                    itemBuilder: (context, index) {
                      final goal = _goals[index];
                      final color = Color(goal.colorValue);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      goal.title,
                                      style: AppTypography.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: Colors.grey, size: 20),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => _showAddGoalDialog(existingGoal: goal),
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    icon: Icon(Icons.delete_outline, color: Colors.red.withOpacity(0.7), size: 20),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () async {
                                      await Provider.of<DatabaseService>(context, listen: false).deleteSavingsGoal(goal.id);
                                      _loadData();
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Center(
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CircularPercentIndicator(
                                      radius: 70.0,
                                      lineWidth: 12.0,
                                      animation: true,
                                      percent: goal.percentage > 1.0 ? 1.0 : goal.percentage,
                                      circularStrokeCap: CircularStrokeCap.round,
                                      progressColor: goal.isCompleted ? AppTheme.incomeGreen : color,
                                      backgroundColor: color.withOpacity(0.1),
                                    ),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${(goal.percentage * 100).toStringAsFixed(0)}%',
                                          style: AppTypography.poppins(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w700,
                                            color: goal.isCompleted ? AppTheme.incomeGreen : color,
                                          ),
                                        ),
                                        if (goal.isCompleted)
                                          const Icon(Icons.check_circle_rounded, color: AppTheme.incomeGreen, size: 20),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Saved',
                                        style: AppTypography.poppins(fontSize: 12, color: Colors.grey),
                                      ),
                                      Text(
                                        '${themeProvider.currencySymbol}${NumberFormat.currency(symbol: '').format(goal.savedAmount)}',
                                        style: AppTypography.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: color,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Target',
                                        style: AppTypography.poppins(fontSize: 12, color: Colors.grey),
                                      ),
                                      Text(
                                        '${themeProvider.currencySymbol}${NumberFormat.currency(symbol: '').format(goal.targetAmount)}',
                                        style: AppTypography.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: goal.isCompleted ? null : () => _showAddFundsDialog(goal),
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text('Add Funds'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: color,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryPurple.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.flag_rounded,
              size: 64,
              color: AppTheme.primaryPurple,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Savings Goals',
            style: AppTypography.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set your first goal and start saving!',
            style: AppTypography.poppins(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddGoalDialog(),
            icon: const Icon(Icons.add_rounded),
            label: const Text('New Goal'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddGoalDialog extends StatefulWidget {
  final SavingsGoal? goal;
  final VoidCallback onSave;

  const _AddGoalDialog({this.goal, required this.onSave});

  @override
  State<_AddGoalDialog> createState() => _AddGoalDialogState();
}

class _AddGoalDialogState extends State<_AddGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  
  late Color _selectedColor;
  final List<Color> _colors = [
    AppTheme.primaryPurple,
    AppTheme.incomeGreen,
    AppTheme.warningYellow,
    AppTheme.expenseRed,
    Colors.blue,
    Colors.teal,
    Colors.deepOrange,
    Colors.pink,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.goal != null) {
      _titleController.text = widget.goal!.title;
      _amountController.text = widget.goal!.targetAmount.toString();
      _selectedColor = Color(widget.goal!.colorValue);
    } else {
      _selectedColor = _colors[0];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.goal == null ? 'New Savings Goal' : 'Edit Goal',
                style: AppTypography.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'What are you saving for?',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Target Amount',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Invalid amount' : null,
              ),
              const SizedBox(height: 20),
              Text(
                'Color Theme',
                style: AppTypography.poppins(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _colors.map((c) {
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = c),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedColor == c ? Colors.grey.shade400 : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: _selectedColor == c
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _save,
                    child: Text(widget.goal == null ? 'Create' : 'Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final db = Provider.of<DatabaseService>(context, listen: false);
      final goal = SavingsGoal(
        id: widget.goal?.id ?? const Uuid().v4(),
        title: _titleController.text,
        targetAmount: double.parse(_amountController.text),
        savedAmount: widget.goal?.savedAmount ?? 0.0,
        colorValue: _selectedColor.value,
      );
      
      if (widget.goal == null) {
        await db.insertSavingsGoal(goal);
      } else {
        await db.updateSavingsGoal(goal);
      }
      
      if (mounted) {
        Navigator.pop(context);
        widget.onSave();
      }
    }
  }
}

class _AddFundsDialog extends StatefulWidget {
  final SavingsGoal goal;
  final VoidCallback onSave;

  const _AddFundsDialog({required this.goal, required this.onSave});

  @override
  State<_AddFundsDialog> createState() => _AddFundsDialogState();
}

class _AddFundsDialogState extends State<_AddFundsDialog> {
  final _amountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Funds to ${widget.goal.title}',
              style: AppTypography.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Amount to Add',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    final amount = double.tryParse(_amountController.text) ?? 0;
                    if (amount > 0) {
                      final db = Provider.of<DatabaseService>(context, listen: false);
                      final updated = widget.goal.copyWith(
                        savedAmount: widget.goal.savedAmount + amount,
                      );
                      await db.updateSavingsGoal(updated);
                      if (mounted) {
                        Navigator.pop(context);
                        widget.onSave();
                      }
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
