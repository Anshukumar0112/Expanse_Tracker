import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/expense.dart';
import 'models/loan.dart';
import 'models/repayment.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register adapters
  Hive.registerAdapter(ExpenseAdapter());
  Hive.registerAdapter(LoanAdapter());
  Hive.registerAdapter(RepaymentAdapter());

  // Open boxes (Hive’s version of tables)
  await Hive.openBox<Expense>('expenses');
  await Hive.openBox<Loan>('loans');
  await Hive.openBox<Repayment>('repayments');

  runApp(const App());
}
