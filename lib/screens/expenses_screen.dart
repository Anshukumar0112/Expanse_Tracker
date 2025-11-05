import 'package:flutter/material.dart';
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          itemBuilder: (context, i) {
            if (i == 0) {
              return _WalletHeader(
                balance: balance,
                totalIn: totalIn,
                totalOut: totalOut,
              );
            }
            final e = items[i - 1];
            final icon = e.isIncome
                ? Icons.arrow_circle_down_rounded
                : (e.isLoan
                      ? Icons.arrow_circle_up_rounded
                      : Icons.shopping_cart_rounded);
            return Dismissible(
              key: ValueKey(e.id),
              direction: DismissDirection.endToStart,
              background: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                alignment: Alignment.centerRight,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.delete_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              onDismissed: (_) => b.delete(e.id),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: e.isIncome
                            ? [const Color(0xFF10B981), const Color(0xFF059669)]
                            : e.isLoan
                            ? [const Color(0xFFF59E0B), const Color(0xFFD97706)]
                            : [
                                const Color(0xFF6366F1),
                                const Color(0xFF8B5CF6),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  title: Text(
                    e.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${e.category} • ${dateFmt.format(e.date)}',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        (e.isIncome ? '+' : '-') + currency.format(e.amount),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: e.isIncome
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          tooltip: 'Delete',
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                          ),
                          color: const Color(0xFFEF4444),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          onPressed: () async {
                            await b.delete(e.id);
                          },
                        ),
                      ),
                    ],
                  ),
                  onLongPress: () => _showExpenseActions(context, e, b),
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

  void _showExpenseActions(BuildContext context, Expense e, Box<Expense> box) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                e.title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await box.delete(e.id);
                        if (context.mounted) Navigator.pop(context);
                      },
                      icon: const Icon(Icons.delete_rounded),
                      label: const Text('Delete entry'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Tip: you can also swipe left on an entry to delete quickly.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
              ),
            ],
          ),
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
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFEC4899)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Wallet Balance',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currency.format(balance),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.pie_chart_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _Pill(
                  icon: Icons.arrow_downward_rounded,
                  color: const Color(0xFF10B981),
                  text: currency.format(totalIn),
                  label: 'Income',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Pill(
                  icon: Icons.arrow_upward_rounded,
                  color: const Color(0xFFEF4444),
                  text: currency.format(totalOut),
                  label: 'Expense',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final String label;

  const _Pill({
    required this.icon,
    required this.color,
    required this.text,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
