// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voucher.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VoucherAdapter extends TypeAdapter<Voucher> {
  @override
  final int typeId = 8;

  @override
  Voucher read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Voucher(
      id: fields[0] as String,
      voucherNumber: fields[1] as String,
      type: fields[2] as VoucherType,
      date: fields[3] as DateTime,
      amount: fields[4] as double,
      description: fields[5] as String,
      relatedPartyId: fields[6] as String?,
      relatedPartyName: fields[7] as String?,
      paymentMethod: fields[8] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Voucher obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.voucherNumber)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.amount)
      ..writeByte(5)
      ..write(obj.description)
      ..writeByte(6)
      ..write(obj.relatedPartyId)
      ..writeByte(7)
      ..write(obj.relatedPartyName)
      ..writeByte(8)
      ..write(obj.paymentMethod);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VoucherAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
