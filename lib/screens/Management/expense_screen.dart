import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../model/expense.dart';
import '../../repositories/expense_repository.dart';

class ExpenseScreen extends ConsumerStatefulWidget {
  const ExpenseScreen({super.key});

  @override
  ConsumerState<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends ConsumerState<ExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String? _selectedCategory;
  List<String> _categories = ['Rent', 'Petrol', 'Raw Materials', 'Electricity', 'Maintenance', 'Other'];

  Expense? _editingExpense;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  // Show Add/Edit Expense bottom sheet
  void _showExpenseSheet({Expense? expense}) {
    _editingExpense = expense;

    if (expense != null) {
      _selectedCategory = expense.description;
      _amountController.text = expense.amount.toStringAsFixed(2);
    } else {
      _selectedCategory = null;
      _amountController.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;

        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Text(
                    expense == null ? 'Add New Expense' : 'Edit Expense',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Dropdown with "Add custom" option
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      prefixIcon: const Icon(Icons.category_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                    ),
                    items: [
                      ..._categories.map((cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(cat),
                      )),
                      const DropdownMenuItem(
                        value: 'ADD_NEW',
                        child: Row(
                          children: [
                            Icon(Icons.add, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Add new category'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) async {
                      if (value == 'ADD_NEW') {
                        final newCategory = await _showAddCategoryDialog(context);
                        if (newCategory != null && newCategory.isNotEmpty) {
                          setState(() {
                            _categories.add(newCategory);
                            _selectedCategory = newCategory;
                          });
                        }
                      } else {
                        setState(() => _selectedCategory = value);
                      }
                    },
                    validator: (value) => value == null || value.isEmpty
                        ? 'Please select a category'
                        : null,
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: 'Amount (₹)',
                      prefixIcon: const Icon(Icons.currency_rupee_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                    ),
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter amount';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Enter valid number';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  FilledButton.icon(
                    icon: Icon(expense == null ? Icons.add : Icons.save),
                    label: Text(expense == null ? 'Add Expense' : 'Save Changes'),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        if (expense == null) {
                          _addExpense();
                        } else {
                          _updateExpense(expense);
                        }
                        Navigator.pop(context);
                      }
                    },
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Dialog to add custom category
  Future<String?> _showAddCategoryDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            hintText: 'e.g., Snacks, Internet',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addExpense() {
    final newExpense = Expense(
      description: _selectedCategory!,
      amount: double.parse(_amountController.text),
      date: DateTime.now(),
    );
    ref.read(expenseRepositoryProvider).addExpense(newExpense);
  }

  void _updateExpense(Expense expense) {
    expense.description = _selectedCategory!;
    expense.amount = double.parse(_amountController.text);
    expense.date = DateTime.now(); // Update timestamp
    ref.read(expenseRepositoryProvider).updateExpense(expense);
  }

  void _deleteExpense(Expense expense) {
    ref.read(expenseRepositoryProvider).deleteExpense(expense);
  }

  @override
  Widget build(BuildContext context) {
    final expenseRepository = ref.watch(expenseRepositoryProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Expenses'),
        elevation: 0,
      ),
      body: ValueListenableBuilder(
        valueListenable: expenseRepository.getListenable(),
        builder: (context, Box<Expense> box, _) {
          if (box.values.isEmpty) {
            return const Center(
              child: Text('No expenses yet.\nTap "+" to add one!',
                  textAlign: TextAlign.center),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: box.length,
            itemBuilder: (context, index) {
              final expense = box.getAt(box.length - 1 - index)!;
              final formattedDate =
              DateFormat.yMMMd().add_jm().format(expense.date);

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                margin: const EdgeInsets.only(bottom: 14),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  onTap: () => _showExpenseSheet(expense: expense),
                  leading: CircleAvatar(
                    backgroundColor:
                    colorScheme.primaryContainer.withOpacity(0.4),
                    child: const Icon(Icons.edit_outlined,
                        color: Colors.blueAccent),
                  ),
                  title: Text(
                    expense.description,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    formattedDate,
                    style: TextStyle(color: colorScheme.outline),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '- ₹${expense.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.redAccent),
                        onPressed: () => _deleteExpense(expense),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showExpenseSheet(),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }
}
