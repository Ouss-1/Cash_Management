import 'package:flutter/material.dart';
import '../utils/typography.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/contact.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';
import 'package:uuid/uuid.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({Key? key}) : super(key: key);

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<ContactModel> _contacts = [];
  Map<String, double> _contactBalances = {}; // Positive means user owes contact, Negative means contact owes user
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final db = Provider.of<DatabaseService>(context, listen: false);
    final contacts = await db.getContacts();
    
    // Calculate balances based on transactions for each contact
    Map<String, double> balances = {};
    for (var contact in contacts) {
      double balance = await _calculateContactBalance(contact.id);
      balances[contact.id] = balance;
    }

    setState(() {
      _contacts = contacts;
      _contactBalances = balances;
      _isLoading = false;
    });
  }

  Future<double> _calculateContactBalance(String contactId) async {
      final db = Provider.of<DatabaseService>(context, listen: false);
      final transactions = await db.getTransactions();
      
      double totalOwedToContact = 0.0;
      double totalOwedByUser = 0.0;

      for (var t in transactions.where((t) => t.contactId == contactId)) {
          double difference = t.amount - t.paidAmount;
          
          if (difference > 0) {
              if (t.type == 'expense' || t.type == 'loan_taken') {
                  totalOwedToContact += difference;
              } else if (t.type == 'income' || t.type == 'loan_given') {
                  totalOwedByUser += difference;
              }
          }
      }

      return totalOwedToContact - totalOwedByUser;
  }

  void _showAddContactDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddContactDialog(
        onSave: () {
          _loadData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Contacts',
          style: AppTypography.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            onPressed: _showAddContactDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _contacts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.group_off_rounded,
                        size: 80,
                        color: Colors.grey.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No contacts yet',
                        style: AppTypography.poppins(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _showAddContactDialog,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add Contact'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _contacts.length,
                    itemBuilder: (context, index) {
                      final contact = _contacts[index];
                      final balance = _contactBalances[contact.id] ?? 0.0;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: Color(contact.colorValue),
                            child: Text(
                              contact.name[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          title: Text(
                            contact.name,
                            style: AppTypography.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            contact.phone,
                            style: AppTypography.poppins(
                              color: Colors.grey,
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                                Text(
                                  'Balance',
                                  style: AppTypography.poppins(
                                      fontSize: 12,
                                      color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  NumberFormat.currency(symbol: '\$').format(balance.abs()),
                                  style: AppTypography.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: balance == 0 ? Colors.grey : (balance > 0 ? AppTheme.expenseRed : AppTheme.incomeGreen),
                                  ),
                                ),
                                if (balance != 0)
                                  Text(
                                    balance > 0 ? 'You Owe' : 'Owes You',
                                    style: AppTypography.poppins(
                                      fontSize: 10,
                                      color: balance > 0 ? AppTheme.expenseRed : AppTheme.incomeGreen,
                                    ),
                                  ),
                            ],
                          ),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => _EditContactDialog(
                                contact: contact,
                                onSave: _loadData,
                              ),
                            );
                          },
                          onLongPress: () async {
                              final db = Provider.of<DatabaseService>(context, listen: false);
                              await db.deleteContact(contact.id);
                              _loadData();
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _AddContactDialog extends StatefulWidget {
  final VoidCallback onSave;

  const _AddContactDialog({
    required this.onSave,
  });

  @override
  State<_AddContactDialog> createState() => _AddContactDialogState();
}

class _AddContactDialogState extends State<_AddContactDialog> {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController();
    final _phoneController = TextEditingController();

    @override
    Widget build(BuildContext context) {
        return AlertDialog(
            title: Text(
                'Add Contact',
                style: AppTypography.poppins(fontWeight: FontWeight.w600),
            ),
            content: Form(
                key: _formKey,
               child: Column(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                       TextFormField(
                           controller: _nameController,
                           decoration: InputDecoration(
                               labelText: 'Name',
                               border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                               prefixIcon: const Icon(Icons.person),
                           ),
                           validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                       ),
                       const SizedBox(height: 16),
                        TextFormField(
                           controller: _phoneController,
                           decoration: InputDecoration(
                               labelText: 'Phone (Optional)',
                               border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                               prefixIcon: const Icon(Icons.phone),
                           ),
                       ),
                   ],
               )
            ),
            actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                    onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                            final db = Provider.of<DatabaseService>(context, listen: false);
                            await db.insertContact(ContactModel(
                                id: const Uuid().v4(),
                                name: _nameController.text,
                                phone: _phoneController.text,
                                colorValue: Colors.primaries[_nameController.text.length % Colors.primaries.length].value,
                                createdAt: DateTime.now(),
                            ));
                            if (mounted) {
                                Navigator.pop(context);
                                widget.onSave();
                            }
                        }
                    },
                    child: const Text('Save')
                )
            ],
        );
    }
}

class _EditContactDialog extends StatefulWidget {
  final ContactModel contact;
  final VoidCallback onSave;
  const _EditContactDialog({required this.contact, required this.onSave});

  @override
  State<_EditContactDialog> createState() => _EditContactDialogState();
}

class _EditContactDialogState extends State<_EditContactDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contact.name);
    _phoneController = TextEditingController(text: widget.contact.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Contact', style: AppTypography.poppins(fontWeight: FontWeight.w600)),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.person),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone (Optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.phone),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final db = Provider.of<DatabaseService>(context, listen: false);
              await db.updateContact(widget.contact.copyWith(
                name: _nameController.text,
                phone: _phoneController.text,
              ));
              if (mounted) {
                Navigator.pop(context);
                widget.onSave();
              }
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
