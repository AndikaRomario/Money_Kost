import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:money_kos/pages/TransactionDatabaseHelper.dart';
import 'package:money_kos/pages/transaction_data.dart';
import 'package:money_kos/pages/transaction_edit.dart';
import 'package:calendar_appbar/calendar_appbar.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const List<String> periodOptions = ['Harian', 'Mingguan', 'Bulanan'];

  late String dropDownValue = periodOptions.first; // Set an initial value
  late List<TransactionData> transactions = [];
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    _loadTransactions();
  }

  void _editTransaction(TransactionData transaction) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTransactionPage(transaction: transaction),
      ),
    );

    if (result == true) {
      // Transaction was updated, reload transactions
      _loadTransactions();
    }
  }

  Future<void> _confirmDelete(TransactionData transaction) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete this transaction?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await _deleteTransaction(transaction);
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteTransaction(TransactionData transaction) async {
    try {
      final databaseHelper = TransactionDatabaseHelper();
      await databaseHelper.deleteTransaction(transaction.id);
      _loadTransactions(); // Reload transactions after delete
      _showSnackBar('Transaction deleted successfully.');
    } catch (e) {
      print('Error deleting transaction: $e');
      _showSnackBar('Error deleting transaction. Please try again.');
    }
  }

  // Method to load transactions based on the selected time range
  Future<void> _loadTransactions() async {
    try {
      // Create an instance of TransactionDatabaseHelper
      final databaseHelper = TransactionDatabaseHelper();

      // Declare variables for start and end dates of the transaction retrieval period
      DateTime startDate;
      DateTime endDate;

      // Determine the start and end dates based on the selected dropdown value
      if (dropDownValue == 'Harian') {
        startDate = selectedDate;
        endDate = selectedDate;
      } else if (dropDownValue == 'Mingguan') {
        startDate = selectedDate.subtract(const Duration(days: 7));
        endDate = selectedDate;
      } else if (dropDownValue == 'Bulanan') {
        startDate = DateTime(selectedDate.year, selectedDate.month, 1);
        endDate = DateTime(selectedDate.year, selectedDate.month + 1, 1)
            .subtract(const Duration(days: 1));
      } else {
        // Handle unexpected dropdown values or provide a default behavior
        startDate = selectedDate;
        endDate = selectedDate;
      }

      // Format start and end dates as strings in 'yyyy-MM-dd' format
      final formattedStartDate = DateFormat('yyyy-MM-dd').format(startDate);
      final formattedEndDate = DateFormat('yyyy-MM-dd').format(endDate);

      // Parse formatted start and end dates back into DateTime objects
      final startDateTime = DateFormat('yyyy-MM-dd').parse(formattedStartDate);
      final endDateTime = DateFormat('yyyy-MM-dd').parse(formattedEndDate);

      // Retrieve transactions from the database within the specified date range
      transactions = await databaseHelper.getTransactionsInRange(
          startDateTime, endDateTime);

      // Print the loaded transactions for debugging purposes
      print(
          'Transactions for $formattedStartDate to $formattedEndDate: $transactions');

      // Update the state to trigger a UI refresh
      setState(() {});
    } catch (e) {
      // Handle errors that may occur during the transaction loading process
      print('Error loading transactions: $e');
    }
  }

  Future<void> _refresh() async {
    await _loadTransactions();
  }

  double calculateTotalAmount(
      List<TransactionData> transactions, bool isExpense) {
    return transactions
        .where((transaction) => transaction.isExpense == (isExpense ? 1 : 0))
        .fold(0, (total, transaction) => total + transaction.amount);
  }

  Widget _buildTransactionInfo(
      IconData icon, String title, double amount, Color color) {
    final formatter = NumberFormat.currency(locale: 'id', symbol: 'Rp');

    return Row(
      children: [
        Container(
          child: Icon(icon, color: color),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.montserrat(color: Colors.white, fontSize: 12),
            ),
            const SizedBox(height: 10),
            Text(
              formatter.format(amount),
              style: GoogleFonts.montserrat(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalIncome = calculateTotalAmount(transactions, false);
    final totalExpense = calculateTotalAmount(transactions, true);

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        children: [
          CalendarAppBar(
            accent: Colors.blue,
            backButton: false,
            locale: 'id',
            onDateChanged: (value) {
              setState(() {
                selectedDate = value;
                _loadTransactions();
              });
            },
            firstDate: DateTime.now().subtract(const Duration(days: 140)),
            lastDate: DateTime.now(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Select Period",
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: dropDownValue,
                  isExpanded: false,
                  icon: const Icon(Icons.search),
                  items: periodOptions
                      .map<DropdownMenuItem<String>>(
                        (String value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        ),
                      )
                      .toList(),
                  onChanged: (String? value) {
                    setState(() {
                      dropDownValue = value ?? periodOptions.first;
                      _loadTransactions();
                    });
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTransactionInfo(
                      Icons.download, "Income", totalIncome, Colors.blue),
                  _buildTransactionInfo(
                      Icons.upload, "Expense", totalExpense, Colors.red),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              "Transactions",
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Builder(
            builder: (BuildContext context) {
              if (transactions.isEmpty) {
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        "No transactions for the selected date",
                        style: GoogleFonts.montserrat(fontSize: 14),
                      ),
                    ),
                    Container(),
                  ],
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  var transaction = transactions[index];

                  return Padding(
                    padding: EdgeInsets.only(
                      left: 16.0,
                      right: 16.0,
                      bottom: index == transactions.length - 1 ? 10.0 : 0.0,
                    ),
                    child: Card(
                      elevation: 10,
                      child: ListTile(
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                _editTransaction(transaction);
                              },
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                _confirmDelete(transaction);
                              },
                            ),
                          ],
                        ),
                        title: Text(
                            "Rp. ${transaction.amount.toStringAsFixed(2)}"),
                        subtitle: Text(transaction.category),
                        leading: Container(
                          child: Icon(
                            transaction.isExpense == 1
                                ? Icons.upload
                                : Icons.download,
                            color: transaction.isExpense == 1
                                ? Colors.red
                                : Colors.blue,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
