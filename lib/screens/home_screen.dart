import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'expenses_screen.dart';
import 'loans_screen.dart';
import 'add_expense_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [const ExpensesScreen(), const LoansScreen()];
    final titles = ['Dashboard', 'Passbook'];

    return Scaffold(
      appBar: AppBar(title: Text(titles[_index])),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        destinations: const [
          NavigationDestination(
            icon: Icon(CupertinoIcons.chart_pie_fill),
            label: 'Expenses',
          ),
          NavigationDestination(
            icon: Icon(CupertinoIcons.creditcard),
            label: 'Loans',
          ),
        ],
        onDestinationSelected: (i) => setState(() => _index = i),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddExpenseScreen(tabIndex: _index),
            ),
          );
          setState(() {});
        },
        icon: const Icon(CupertinoIcons.add),
        label: const Text('Add'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
