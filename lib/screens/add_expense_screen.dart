import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/expense.dart';
import '../models/loan.dart';
import 'package:url_launcher/url_launcher.dart';

class AddExpenseScreen extends StatefulWidget {
  final int tabIndex; // 0 = Expense, 1 = Loan
  const AddExpenseScreen({super.key, this.tabIndex = 0});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();

  // Loan specific
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _interestCtrl = TextEditingController(text: '0');
  DateTime _loanDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));

  int _index = 0;
  bool _isIncome = false; // for expense form: income vs expense

  @override
  void initState() {
    super.initState();
    _index = widget.tabIndex;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _categoryCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _interestCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Entry')),
      body: Column(
        children: [
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(
                value: 0,
                icon: Icon(Icons.shopping_cart_rounded),
                label: Text('Expense'),
              ),
              ButtonSegment(
                value: 1,
                icon: Icon(Icons.account_balance_wallet_rounded),
                label: Text('Loan'),
              ),
            ],
            selected: {_index},
            onSelectionChanged: (s) => setState(() => _index = s.first),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _index == 0
                    ? _buildExpenseForm(context)
                    : _buildLoanForm(context),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: () => _onSubmit(context),
            icon: const Icon(Icons.check_circle_rounded),
            label: Text(_index == 0 ? 'Save Expense' : 'Save Loan'),
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseForm(BuildContext context) {
    return Column(
      children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: true,
              icon: Icon(Icons.arrow_circle_down_rounded),
              label: Text('Income'),
            ),
            ButtonSegment(
              value: false,
              icon: Icon(Icons.arrow_circle_up_rounded),
              label: Text('Expense'),
            ),
          ],
          selected: {_isIncome},
          onSelectionChanged: (s) => setState(() => _isIncome = s.first),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _titleCtrl,
          decoration: const InputDecoration(labelText: 'Title'),
          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _amountCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Amount'),
          validator: (v) =>
              (double.tryParse(v ?? '') == null) ? 'Enter valid amount' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _categoryCtrl,
          decoration: const InputDecoration(labelText: 'Category'),
        ),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          onPressed: () async {
            final id = const Uuid().v4();
            final e = Expense(
              id: id,
              title: _titleCtrl.text.trim(),
              amount: double.parse(_amountCtrl.text.trim()),
              category: _categoryCtrl.text.trim().isEmpty
                  ? 'General'
                  : _categoryCtrl.text.trim(),
              date: DateTime.now(),
              isLoan: false,
              isIncome: _isIncome,
            );
            await Hive.box<Expense>('expenses').put(id, e);
            if (context.mounted) Navigator.pop(context);
          },
          icon: Icon(
            _isIncome
                ? Icons.arrow_circle_down_rounded
                : Icons.remove_shopping_cart_rounded,
          ),
          label: Text(_isIncome ? 'Quick add income' : 'Quick add expense'),
        ),
      ],
    );
  }

  Widget _buildLoanForm(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: _nameCtrl,
          decoration: const InputDecoration(labelText: "Borrower name"),
          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: "Borrower phone (optional)",
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _amountCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Principal amount'),
          validator: (v) =>
              (double.tryParse(v ?? '') == null) ? 'Enter valid amount' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _interestCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Monthly interest % (daily calc)',
          ),
          validator: (v) =>
              (double.tryParse(v ?? '') == null) ? 'Enter valid %' : null,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    initialDate: _loanDate,
                  );
                  if (picked != null) setState(() => _loanDate = picked);
                },
                icon: const Icon(Icons.event_rounded),
                label: Text(
                  'Loan: ${_loanDate.toLocal().toString().split(' ').first}',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: _loanDate,
                    lastDate: DateTime(2100),
                    initialDate: _dueDate,
                  );
                  if (picked != null) setState(() => _dueDate = picked);
                },
                icon: const Icon(Icons.event_available_rounded),
                label: Text(
                  'Due: ${_dueDate.toLocal().toString().split(' ').first}',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _onSubmit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    if (_index == 0) {
      final id = const Uuid().v4();
      final e = Expense(
        id: id,
        title: _titleCtrl.text.trim(),
        amount: double.parse(_amountCtrl.text.trim()),
        category: _categoryCtrl.text.trim().isEmpty
            ? 'General'
            : _categoryCtrl.text.trim(),
        date: DateTime.now(),
        isLoan: false,
      );
      await Hive.box<Expense>('expenses').put(id, e);
      if (context.mounted) Navigator.pop(context);
    } else {
      final id = const Uuid().v4();
      final principal = double.parse(_amountCtrl.text.trim());
      final monthlyRate = double.parse(_interestCtrl.text.trim());
      final rate = monthlyRate / 30.0; // convert monthly to daily
      final loan = Loan(
        id: id,
        borrowerName: _nameCtrl.text.trim(),
        borrowerPhone: _phoneCtrl.text.trim().isEmpty
            ? null
            : _phoneCtrl.text.trim(),
        amount: principal,
        loanDate: _loanDate,
        dueDate: _dueDate,
        dailyInterestPercent: rate,
      );
      await Hive.box<Loan>('loans').put(id, loan);
      // Also record as expense entry for consolidated list
      final exp = Expense(
        id: 'exp-$id',
        title: 'Loan to ${loan.borrowerName}',
        amount: principal,
        category: 'Loan',
        date: DateTime.now(),
        isLoan: true,
        isIncome: false,
      );
      await Hive.box<Expense>('expenses').put(exp.id, exp);

      // Optional: Launch SMS composer
      if (loan.borrowerPhone != null) {
        final uri = Uri(
          scheme: 'sms',
          path: loan.borrowerPhone,
          queryParameters: {
            'body':
                'Hi ${loan.borrowerName}, you received ₹${principal.toStringAsFixed(2)} from me on ${_loanDate.toLocal().toString().split(' ').first}. Monthly interest ${monthlyRate.toStringAsFixed(2)}% (calculated daily). Due by ${_dueDate.toLocal().toString().split(' ').first}.',
          },
        );
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      }

      if (context.mounted) Navigator.pop(context);
    }
  }
}
