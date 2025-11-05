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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Add Entry'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
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
              child: SegmentedButton<int>(
                style: SegmentedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  selectedBackgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                segments: [
                  ButtonSegment(
                    value: 0,
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: _index == 0
                            ? const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                              )
                            : null,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.shopping_cart_rounded,
                        color: _index == 0
                            ? Colors.white
                            : const Color(0xFF64748B),
                        size: 20,
                      ),
                    ),
                    label: Text(
                      'Expense',
                      style: TextStyle(
                        fontWeight: _index == 0
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: _index == 0
                            ? const Color(0xFF1E293B)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  ButtonSegment(
                    value: 1,
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: _index == 1
                            ? const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                              )
                            : null,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_rounded,
                        color: _index == 1
                            ? Colors.white
                            : const Color(0xFF64748B),
                        size: 20,
                      ),
                    ),
                    label: Text(
                      'Loan',
                      style: TextStyle(
                        fontWeight: _index == 1
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: _index == 1
                            ? const Color(0xFF1E293B)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
                selected: {_index},
                onSelectionChanged: (s) => setState(() => _index = s.first),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _index == 0
                    ? _buildExpenseForm(context)
                    : _buildLoanForm(context),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.transparent,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () => _onSubmit(context),
              icon: const Icon(Icons.check_circle_rounded, size: 24),
              label: Text(
                _index == 0 ? 'Save Expense' : 'Save Loan',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseForm(BuildContext context) {
    return Column(
      children: [
        Container(
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
          child: SegmentedButton<bool>(
            style: SegmentedButton.styleFrom(
              backgroundColor: Colors.transparent,
              selectedBackgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            segments: [
              ButtonSegment(
                value: true,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: _isIncome
                        ? const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                          )
                        : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_circle_down_rounded,
                    color: _isIncome ? Colors.white : const Color(0xFF64748B),
                    size: 20,
                  ),
                ),
                label: Text(
                  'Income',
                  style: TextStyle(
                    fontWeight: _isIncome ? FontWeight.w600 : FontWeight.w500,
                    color: _isIncome
                        ? const Color(0xFF1E293B)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
              ButtonSegment(
                value: false,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: !_isIncome
                        ? const LinearGradient(
                            colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                          )
                        : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_circle_up_rounded,
                    color: !_isIncome ? Colors.white : const Color(0xFF64748B),
                    size: 20,
                  ),
                ),
                label: Text(
                  'Expense',
                  style: TextStyle(
                    fontWeight: !_isIncome ? FontWeight.w600 : FontWeight.w500,
                    color: !_isIncome
                        ? const Color(0xFF1E293B)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
            selected: {_isIncome},
            onSelectionChanged: (s) => setState(() => _isIncome = s.first),
          ),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _titleCtrl,
          decoration: InputDecoration(
            labelText: 'Title',
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.description_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
          ),
          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _amountCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Amount',
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.currency_rupee_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFEC4899), width: 2),
            ),
          ),
          validator: (v) =>
              (double.tryParse(v ?? '') == null) ? 'Enter valid amount' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _categoryCtrl,
          decoration: InputDecoration(
            labelText: 'Category',
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.category_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isIncome
                  ? [const Color(0xFF10B981), const Color(0xFF059669)]
                  : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color:
                    (_isIncome
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444))
                        .withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: FilledButton.tonalIcon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
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
        ),
      ],
    );
  }

  Widget _buildLoanForm(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: _nameCtrl,
          decoration: InputDecoration(
            labelText: 'Borrower Name',
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
          ),
          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Borrower Phone (optional)',
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.phone_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFEC4899), width: 2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _amountCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Principal Amount',
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.currency_rupee_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
            ),
          ),
          validator: (v) =>
              (double.tryParse(v ?? '') == null) ? 'Enter valid amount' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _interestCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Monthly Interest %',
            helperText: 'Will be calculated daily',
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.percent_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFF59E0B), width: 2),
            ),
          ),
          validator: (v) =>
              (double.tryParse(v ?? '') == null) ? 'Enter valid %' : null,
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              initialDate: _loanDate,
            );
            if (picked != null) setState(() => _loanDate = picked);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.event_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Loan Date',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_loanDate.day}/${_loanDate.month}/${_loanDate.year}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              firstDate: _loanDate,
              lastDate: DateTime(2100),
              initialDate: _dueDate,
            );
            if (picked != null) setState(() => _dueDate = picked);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.event_available_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Due Date',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_dueDate.day}/${_dueDate.month}/${_dueDate.year}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
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
