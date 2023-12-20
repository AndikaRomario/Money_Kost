import 'package:intl/intl.dart';

class TransactionData {
  int? id; // Make id nullable

  double amount;
  String category;
  DateTime date;
  int isExpense;

  TransactionData({
    this.id, // Make id optional
    required this.amount,
    required this.category,
    required this.date,
    required this.isExpense,
  });

  TransactionData.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        amount = map['amount'],
        category = map['category'],
        date = DateTime.parse(map['date']),
        isExpense = map['isExpense'];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'date': DateFormat('yyyy-MM-dd').format(date),
      'isExpense': isExpense,
    };
  }
}
