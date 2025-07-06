// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voucher_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VoucherTypeAdapter extends TypeAdapter<VoucherType> {
  @override
  final int typeId = 7;

  @override
  VoucherType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return VoucherType.expense;
      case 1:
        return VoucherType.income;
      default:
        return VoucherType.expense;
    }
  }

  @override
  void write(BinaryWriter writer, VoucherType obj) {
    switch (obj) {
      case VoucherType.expense:
        writer.writeByte(0);
        break;
      case VoucherType.income:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VoucherTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
