import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/loan.dart';
import '../models/repayment.dart';
import '../models/expense.dart';
import 'loan_detail_screen.dart';

class LoansScreen extends StatelessWidget {
  const LoansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<Loan>('loans');
    final currency = NumberFormat.currency(symbol: '₹');
    final dateFmt = DateFormat.yMMMd();

    return ValueListenableBuilder(
      valueListenable: box.listenable(),
      builder: (context, Box<Loan> b, _) {
        final items = b.values.toList()
          ..sort(
            (a, b) => (a.isReturned ? 1 : 0).compareTo(b.isReturned ? 1 : 0),
          );
        if (items.isEmpty) {
          return const Center(child: Text('No loans recorded. Tap + to add.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemBuilder: (context, i) {
            final l = items[i];
            final totalDue = l.totalDue();
            final monthlyPercent = l.dailyInterestPercent * 30.0;
            return Card(
              child: ListTile(
                leading: Icon(
                  l.isReturned
                      ? Icons.verified_rounded
                      : Icons.schedule_rounded,
                  color: l.isReturned ? Colors.green : Colors.orange,
                ),
                title: Text(
                  l.borrowerName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Start: ${dateFmt.format(l.loanDate)} • Due: ${dateFmt.format(l.dueDate)}\nPrincipal: ${currency.format(l.amount)} • Interest: ${currency.format(totalDue - l.amount)} (Monthly ${monthlyPercent.toStringAsFixed(2)}%)',
                ),
                isThreeLine: true,
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currency.format(totalDue),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      l.isReturned ? 'Returned' : 'Pending',
                      style: TextStyle(
                        color: l.isReturned ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
                onTap: () => _showLoanActions(context, l),
              ),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemCount: items.length,
        );
      },
    );
  }

  void _showLoanActions(BuildContext context, Loan loan) async {
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
                loan.borrowerName,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Daily interest: ${loan.dailyInterestPercent.toStringAsFixed(2)}%',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => LoanDetailScreen(loan: loan),
                          ),
                        );
                      },
                      icon: const Icon(Icons.info_outline_rounded),
                      label: const Text('View details'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: loan.isReturned
                          ? null
                          : () async {
                              // Compute outstanding (total due - repayments)
                              final repayBox = Hive.box<Repayment>(
                                'repayments',
                              );
                              final paid = repayBox.values
                                  .where((r) => r.loanId == loan.id)
                                  .fold<double>(0.0, (p, r) => p + r.amount);
                              final outstanding = (loan.totalDue() - paid)
                                  .clamp(0, double.infinity)
                                  .toDouble();
                              if (outstanding > 0) {
                                final exp = Expense(
                                  id: const Uuid().v4(),
                                  title:
                                      'Loan returned by ${loan.borrowerName}',
                                  amount: outstanding,
                                  category: 'Loan settlement',
                                  date: DateTime.now(),
                                  isLoan: false,
                                  isIncome: true,
                                );
                                await Hive.box<Expense>(
                                  'expenses',
                                ).put(exp.id, exp);
                              }
                              loan.isReturned = true;
                              loan.returnDate = DateTime.now();
                              await loan.save();
                              if (context.mounted) Navigator.pop(context);
                            },
                      icon: const Icon(Icons.task_alt_rounded),
                      label: const Text('Mark Returned'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await loan.delete();
                        if (context.mounted) Navigator.pop(context);
                      },
                      icon: const Icon(Icons.delete_rounded),
                      label: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
