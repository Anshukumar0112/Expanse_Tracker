// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loan.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LoanAdapter extends TypeAdapter<Loan> {
  @override
  final int typeId = 1;

  @override
  Loan read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Loan(
      id: fields[0] as String,
      borrowerName: fields[1] as String,
      borrowerPhone: fields[7] as String?,
      amount: fields[2] as double,
      loanDate: fields[3] as DateTime,
      dueDate: fields[4] as DateTime,
      remarks: (fields[5] as String?) ?? '',
      isReturned: (fields[6] as bool?) ?? false,
      dailyInterestPercent: (fields[8] as double?) ?? 0.0,
      returnDate: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Loan obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.borrowerName)
      ..writeByte(7)
      ..write(obj.borrowerPhone)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.loanDate)
      ..writeByte(4)
      ..write(obj.dueDate)
      ..writeByte(5)
      ..write(obj.remarks)
      ..writeByte(6)
      ..write(obj.isReturned)
      ..writeByte(8)
      ..write(obj.dailyInterestPercent)
      ..writeByte(9)
      ..write(obj.returnDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoanAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
