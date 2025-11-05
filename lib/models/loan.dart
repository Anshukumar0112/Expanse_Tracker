import 'package:hive/hive.dart';

part 'loan.g.dart'; // will be auto-generated later

@HiveType(typeId: 1)
class Loan extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String borrowerName;

  // Optional phone number to notify via SMS
  @HiveField(7)
  String? borrowerPhone;

  @HiveField(2)
  double amount;

  @HiveField(3)
  DateTime loanDate;

  @HiveField(4)
  DateTime dueDate;

  @HiveField(5)
  String remarks;

  @HiveField(6)
  bool isReturned;

  // Daily simple interest percent (e.g. 0.2 means 0.2% per day)
  @HiveField(8)
  double dailyInterestPercent;

  // When the loan was marked returned (optional)
  @HiveField(9)
  DateTime? returnDate;

  Loan({
    required this.id,
    required this.borrowerName,
    this.borrowerPhone,
    required this.amount,
    required this.loanDate,
    required this.dueDate,
    this.remarks = '',
    this.isReturned = false,
    this.dailyInterestPercent = 0.0,
    this.returnDate,
  });

  // Number of days between start and end (inclusive of start, exclusive of end)
  int _daysBetween(DateTime start, DateTime end) {
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    return e.difference(s).inDays.clamp(0, 1000000);
  }

  // Accrued simple interest based on daily rate and elapsed days
  double accruedInterest({DateTime? asOf}) {
    final end = (isReturned
        ? (returnDate ?? DateTime.now())
        : (asOf ?? DateTime.now()));
    final days = _daysBetween(loanDate, end);
    final ratePerDay = dailyInterestPercent / 100.0;
    return double.parse((amount * ratePerDay * days).toStringAsFixed(2));
  }

  double totalDue({DateTime? asOf}) {
    return double.parse(
      (amount + accruedInterest(asOf: asOf)).toStringAsFixed(2),
    );
  }
}
