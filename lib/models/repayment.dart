import 'package:hive/hive.dart';

part 'repayment.g.dart';

@HiveType(typeId: 2)
class Repayment extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String loanId;

  @HiveField(2)
  double amount;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  String remarks;

  Repayment({
    required this.id,
    required this.loanId,
    required this.amount,
    required this.date,
    this.remarks = '',
  });
}
