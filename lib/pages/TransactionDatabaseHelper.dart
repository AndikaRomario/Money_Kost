// Importing necessary packages
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:money_kos/pages/transaction_data.dart';
import 'package:sqflite/sqflite.dart';

// A class for managing transactions in a SQLite database
class TransactionDatabaseHelper {
  // Singleton instance for the database helper
  static final TransactionDatabaseHelper _instance =
      TransactionDatabaseHelper._privateConstructor();

  // Private constructor for the singleton pattern
  TransactionDatabaseHelper._privateConstructor();

  // Factory method to get the singleton instance
  factory TransactionDatabaseHelper() {
    return _instance;
  }

  // The SQLite database instance
  static Database? _database;

  // Getter for the database instance, creating it if it doesn't exist
  Future<Database> get database async {
    if (_database != null) return _database!;

    // If the database is null, initialize it
    _database = await _initDatabase();
    return _database!;
  }

  // Method to initialize the SQLite database
  Future<Database> _initDatabase() async {
    // Get the path for the database file
    final path = join(await getDatabasesPath(), 'transactions.db');

    // Open the database or create it if it doesn't exist
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        // Create the 'transactions' table with specified columns
        return db.execute(
          'CREATE TABLE transactions(id INTEGER PRIMARY KEY AUTOINCREMENT, amount REAL, category TEXT, date DATETIME, isExpense INTEGER)',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) {
        // Handle database schema updates if needed
      },
    );
  }

  // Method to update a transaction in the database
  Future<int> updateTransaction(TransactionData transaction) async {
    try {
      final db = await database;
      // Update the 'transactions' table with the new values for the given transaction ID
      return await db.update(
        'transactions',
        transaction.toMap(),
        where: 'id = ?',
        whereArgs: [transaction.id],
      );
    } catch (e) {
      print('Error updating transaction: $e');
      throw Exception('Failed to update transaction');
    }
  }

  // Method to insert a new transaction into the database
  Future<int> insertTransaction(TransactionData transaction) async {
    final db = await database;
    try {
      // Insert the transaction data into the 'transactions' table
      return await db.insert('transactions', transaction.toMap());
    } catch (e) {
      print('Error inserting transaction: $e');
      throw Exception('Failed to insert transaction');
    }
  }

  // Method to retrieve all transactions from the database
  Future<List<TransactionData>> getAllTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('transactions');

    // Convert the query results into a list of TransactionData objects
    return List.generate(maps.length, (i) {
      return TransactionData.fromMap(maps[i]);
    });
  }

  // Method to retrieve transactions for a specific date from the database
  Future<List<TransactionData>> getTransactionsForDate(DateTime date) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'date = ?',
      whereArgs: [DateFormat('yyyy-MM-dd').format(date)],
    );

    // Convert the query results into a list of TransactionData objects
    return List.generate(maps.length, (i) {
      return TransactionData.fromMap(maps[i]);
    });
  }

  // Method to delete a transaction from the database
  Future<void> deleteTransaction(int? transactionId) async {
    final db = await database;
    // Delete the transaction with the specified ID from the 'transactions' table
    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [transactionId],
    );
  }

  // Method to retrieve transactions within a date range from the database
  Future<List<TransactionData>> getTransactionsInRange(
      DateTime startDate, DateTime endDate) async {
    final db = await database;
    final startDateTime = DateFormat('yyyy-MM-dd').format(startDate);
    final endDateTime = DateFormat('yyyy-MM-dd').format(endDate);

    // Query transactions with dates within the specified range from the 'transactions' table
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDateTime, endDateTime],
    );

    // Convert the query results into a list of TransactionData objects
    return List.generate(maps.length, (i) {
      return TransactionData.fromMap(maps[i]);
    });
  }
}
