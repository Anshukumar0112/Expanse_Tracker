import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense.dart';
import 'package:intl/intl.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<Expense>('expenses');
    final currency = NumberFormat.currency(symbol: '₹');
    final dateFmt = DateFormat.yMMMd();

    return ValueListenableBuilder(
      valueListenable: box.listenable(),
      builder: (context, Box<Expense> b, _) {
        final items = b.values.toList()
          ..sort((a, b) => b.date.compareTo(a.date));

        // Wallet summary
        final totalIn = items
            .where((e) => e.isIncome)
            .fold<double>(0.0, (p, e) => p + e.amount);
        final totalOut = items
            .where((e) => !e.isIncome)
            .fold<double>(0.0, (p, e) => p + e.amount);
        final balance = totalIn - totalOut;

        if (items.isEmpty) {
          return Column(
            children: [
              _WalletHeader(
                balance: balance,
                totalIn: totalIn,
                totalOut: totalOut,
              ),
              const Expanded(
                child: Center(child: Text('No expenses yet. Tap + to add.')),
              ),
            ],
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemBuilder: (context, i) {
            if (i == 0) {
              return _WalletHeader(
                balance: balance,
                totalIn: totalIn,
                totalOut: totalOut,
              );
            }
            final e = items[i - 1];
            final color = e.isIncome
                ? Colors.green
                : (e.isLoan
                      ? Colors.orange
                      : Theme.of(context).colorScheme.primary);
            final icon = e.isIncome
                ? CupertinoIcons.arrow_down_circle_fill
                : (e.isLoan
                      ? CupertinoIcons.arrow_up_right_circle_fill
                      : CupertinoIcons.cart_fill);
            return Dismissible(
              key: ValueKey(e.id),
              direction: DismissDirection.endToStart,
              background: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.centerRight,
                decoration: BoxDecoration(
                  color: Colors.red.shade400,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  CupertinoIcons.delete_solid,
                  color: Colors.white,
                ),
              ),
              onDismissed: (_) => b.delete(e.id),
              child: Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withAlpha((0.15 * 255).round()),
                    foregroundColor: color,
                    child: Icon(icon),
                  ),
                  title: Text(
                    e.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('${e.category} • ${dateFmt.format(e.date)}'),
                  trailing: Text(
                    (e.isIncome ? '+' : '-') + currency.format(e.amount),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: e.isIncome ? Colors.green : Colors.redAccent,
                    ),
                  ),
                ),
              ),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemCount: items.length + 1,
        );
      },
    );
  }
}

class _WalletHeader extends StatelessWidget {
  final double balance;
  final double totalIn;
  final double totalOut;
  const _WalletHeader({
    required this.balance,
    required this.totalIn,
    required this.totalOut,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '₹');
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wallet Balance',
                  style: TextStyle(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currency.format(balance),
                  style: TextStyle(
                    color: cs.onPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _Pill(
                      color: Colors.greenAccent.shade100.withAlpha((0.9 * 255).round()),
                      text: '+ ${currency.format(totalIn)}',
                    ),
                    const SizedBox(width: 8),
                    _Pill(
                      color: Colors.redAccent.shade100.withAlpha((0.9 * 255).round()),
                      text: '- ${currency.format(totalOut)}',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(
            CupertinoIcons.chart_pie_fill,
            color: Colors.white,
            size: 36,
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final Color color;
  final String text;
  const _Pill({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}
