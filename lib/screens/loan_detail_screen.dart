import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/loan.dart';
import '../models/repayment.dart';
import '../models/expense.dart';
import 'package:uuid/uuid.dart';

class LoanDetailScreen extends StatelessWidget {
  final Loan loan;
  const LoanDetailScreen({super.key, required this.loan});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '₹');
    final repayBox = Hive.box<Repayment>('repayments');

    return Scaffold(
      appBar: AppBar(title: const Text('Loan details')),
      body: ValueListenableBuilder(
        valueListenable: repayBox.listenable(),
        builder: (context, Box<Repayment> box, _) {
          final repayments =
              box.values.where((r) => r.loanId == loan.id).toList()
                ..sort((a, b) => b.date.compareTo(a.date));
          final totalRepayed = repayments.fold<double>(
            0.0,
            (p, r) => p + r.amount,
          );
          final totalDue = loan.totalDue();
          final outstanding = (totalDue - totalRepayed).clamp(
            0,
            double.infinity,
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StatCard(
                title: 'Total due',
                value: currency.format(totalDue),
                icon: Icons.receipt_long_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Repaid',
                      value: currency.format(totalRepayed),
                      icon: Icons.arrow_circle_down_rounded,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Outstanding',
                      value: currency.format(outstanding),
                      icon: Icons.schedule_rounded,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Repayments',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (repayments.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('No repayments yet.')),
                )
              else
                ...repayments.map(
                  (r) => Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.arrow_circle_down_rounded,
                        color: Colors.green,
                      ),
                      title: Text(currency.format(r.amount)),
                      subtitle: Text(DateFormat.yMMMd().format(r.date)),
                      trailing: Text(r.remarks),
                    ),
                  ),
                ),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _addRepayment(context, loan),
                  icon: const Icon(Icons.add_circle_rounded),
                  label: const Text('Add repayment'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: loan.isReturned
                      ? null
                      : () async {
                          // Compute outstanding repayment and add to wallet
                          final repayBox = Hive.box<Repayment>('repayments');
                          final paid = repayBox.values
                              .where((r) => r.loanId == loan.id)
                              .fold<double>(0.0, (p, r) => p + r.amount);
                          final outstanding = (loan.totalDue() - paid)
                              .clamp(0, double.infinity)
                              .toDouble();
                          if (outstanding > 0) {
                            final exp = Expense(
                              id: const Uuid().v4(),
                              title: 'Loan returned by ${loan.borrowerName}',
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
                  label: const Text('Mark returned'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addRepayment(BuildContext context, Loan loan) async {
    final formKey = GlobalKey<FormState>();
    final amountCtrl = TextEditingController();
    final remarksCtrl = TextEditingController();
    final currency = NumberFormat.currency(symbol: '₹');
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
            top: 8,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Add repayment for ${loan.borrowerName}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Amount (${currency.currencySymbol})',
                  ),
                  validator: (v) => (double.tryParse(v ?? '') == null)
                      ? 'Enter valid amount'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: remarksCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Remarks (optional)',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final id = const Uuid().v4();
                    final amount = double.parse(amountCtrl.text.trim());
                    final repayment = Repayment(
                      id: id,
                      loanId: loan.id,
                      amount: amount,
                      date: DateTime.now(),
                      remarks: remarksCtrl.text.trim(),
                    );
                    await Hive.box<Repayment>('repayments').put(id, repayment);
                    // Mirror as income in expenses
                    final exp = Expense(
                      id: 'repay-$id',
                      title: 'Repayment from ${loan.borrowerName}',
                      amount: amount,
                      category: 'Loan repayment',
                      date: DateTime.now(),
                      isLoan: false,
                      isIncome: true,
                    );
                    await Hive.box<Expense>('expenses').put(exp.id, exp);
                    if (context.mounted) Navigator.pop(context);
                  },
                  icon: const Icon(Icons.arrow_circle_down_rounded),
                  label: const Text('Save repayment'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withAlpha(40),
            foregroundColor: color,
            child: Icon(icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: cs.onSurface.withAlpha(180),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
