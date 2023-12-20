import 'package:flutter/material.dart';
import 'package:money_kos/pages/transaction_data.dart';
import 'package:money_kos/pages/TransactionDatabaseHelper.dart';
import 'package:money_kos/pages/category.dart';
import 'package:money_kos/pages/database_helper.dart';

class EditTransactionPage extends StatefulWidget {
  final TransactionData transaction;

  EditTransactionPage({required this.transaction});

  @override
  _EditTransactionPageState createState() => _EditTransactionPageState();
}

class _EditTransactionPageState extends State<EditTransactionPage> {
  late TextEditingController amountController;
  late TextEditingController categoryController;
  bool isExpense = true; // Added for the switch
  String? selectedCategoryId; // Added for the category dropdown
  List<Category> categories = []; // Added for the category dropdown

  @override
  void initState() {
    super.initState();
    amountController = TextEditingController(
        text: widget.transaction.amount.toStringAsFixed(2));
    categoryController = TextEditingController(text: widget.transaction.category);
    isExpense = widget.transaction.isExpense == 1; // Initialize isExpense
    loadCategories(); // Load categories for the dropdown
  }

  void loadCategories() async {
    DatabaseHelper dbHelper = DatabaseHelper();
    List<Category> loadedCategories = await dbHelper.getAllCategories();

    setState(() {
      categories = loadedCategories.where((category) => category.type == (isExpense ? 1 : 0)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Transaction'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Switch(
                  value: isExpense,
                  onChanged: (bool value) {
                    setState(() {
                      isExpense = value;
                      selectedCategoryId = null;
                      loadCategories();
                    });
                  },
                  inactiveTrackColor: Colors.red[200],
                  inactiveThumbColor: Colors.red,
                  activeColor: Colors.blue,
                ),
                Text(
                  isExpense ? 'Income' : 'Expense',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),

            SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Amount'),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedCategoryId,
              onChanged: (value) {
                setState(() {
                  selectedCategoryId = value;
                });
              },
              items: categories.map<DropdownMenuItem<String>>(
                    (Category category) {
                  return DropdownMenuItem<String>(
                    value: category.id.toString(),
                    child: Text(category.name),
                  );
                },
              ).toList(),
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              isExpanded: true,
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                _updateTransaction();
              },
              child: Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _updateTransaction() async {
    try {
      double amount = double.tryParse(amountController.text) ?? 0.0;

      if (amount <= 0) {
        // Show an error message or handle invalid input
        return;
      }

      Category selectedCategory = categories.firstWhere(
            (category) => category.id.toString() == selectedCategoryId!,
      );

      TransactionData updatedTransaction = TransactionData(
        id: widget.transaction.id,
        amount: amount,
        category: selectedCategory.name,
        date: widget.transaction.date,
        isExpense: isExpense ? 0 : 1, // Store 1 if isExpense is true, and 0 if it's false
      );

      final databaseHelper = TransactionDatabaseHelper();
      await databaseHelper.updateTransaction(updatedTransaction);

      Navigator.pop(context, true); // Signal that the transaction was updated

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transaction updated successfully.'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error updating transaction: $e');
    }
  }
}
