import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:money_kos/pages/TransactionDatabaseHelper.dart';
import 'package:money_kos/pages/category.dart';
import 'package:money_kos/pages/database_helper.dart';
import 'package:money_kos/pages/transaction_data.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({Key? key}) : super(key: key);

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  bool isExpense = true;
  int type = 0; // 0 for "expense", 1 for "income"
  final TextEditingController amountController = TextEditingController();
  final TextEditingController dateController = TextEditingController();

  List<Category> categories = [];
  String? selectedCategoryId;

  @override
  void initState() {
    super.initState();
    loadCategories();
  }

  void loadCategories() async {
    DatabaseHelper dbHelper = DatabaseHelper();
    List<Category> loadedCategories = await dbHelper.getAllCategories();

    setState(() {
      categories =
          loadedCategories.where((category) => category.type == type).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Transaction"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Row(
              children: [
                Switch(
                  value: type == 1, // Inverted the value to display "Income" when active
                  onChanged: (bool value) {
                    setState(() {
                      type = value ? 1 : 0; // Inverted the type values
                      selectedCategoryId = null;
                      loadCategories();
                    });
                  },
                  inactiveTrackColor: Colors.red[200], // Changed inactive track color to blue
                  inactiveThumbColor: Colors.red, // Changed inactive thumb color to blue
                  activeColor: Colors.blue, // Changed active color to green
                ),
                Text(
                  type == 1 ? 'Income' : 'Expense', // Updated text based on the type
                  style: GoogleFonts.montserrat(fontSize: 14),
                ),

              ],
            ),
            SizedBox(height: 10),
            TextFormField(
              keyboardType: TextInputType.number,
              controller: amountController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Amount",
              ),
            ),
            SizedBox(height: 15),
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
            SizedBox(height: 15),
            TextField(
              readOnly: true,
              controller: dateController,
              decoration: InputDecoration(labelText: "Enter Date"),
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2099),
                );

                if (pickedDate != null) {
                  String formattedDate =
                  DateFormat('dd-MM-yyyy').format(pickedDate);

                  dateController.text = formattedDate;
                }
              },
            ),
            SizedBox(height: 15),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Save the transaction data
                  saveTransaction();
                },
                child: Text("Save"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void saveTransaction() async {
    if (amountController.text.isEmpty ||
        dateController.text.isEmpty ||
        selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all fields.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    Category selectedCategory = categories.firstWhere(
          (category) => category.id.toString() == selectedCategoryId!,
    );

    TransactionData transaction = TransactionData(
      amount: double.parse(amountController.text),
      category: selectedCategory.name,
      date: DateFormat('dd-MM-yyyy').parse(dateController.text),
      isExpense: type == 0 ? 1 : 0, // Corrected the isExpense assignment
    );

    TransactionDatabaseHelper dbHelper = TransactionDatabaseHelper();
    try {
      await dbHelper.insertTransaction(transaction);
      amountController.clear();
      dateController.clear();
      selectedCategoryId = null;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transaction saved successfully.'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error saving transaction: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving transaction. Please try again.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
