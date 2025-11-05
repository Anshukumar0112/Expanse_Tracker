import 'package:hive/hive.dart';

part 'expense.g.dart'; // will be auto-generated later

@HiveType(typeId: 0)
class Expense extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  double amount;

  @HiveField(3)
  String category;

  @HiveField(4)
  DateTime date;

  @HiveField(5)
  bool isLoan;

  // true = income (money into wallet), false = expense (money out)
  @HiveField(6)
  bool isIncome;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.isLoan = false,
    this.isIncome = false,
  });
}
