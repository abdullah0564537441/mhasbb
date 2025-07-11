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
        return VoucherType.receipt;
      case 1:
        return VoucherType.payment;
      default:
        return VoucherType.receipt;
    }
  }

  @override
  void write(BinaryWriter writer, VoucherType obj) {
    switch (obj) {
      case VoucherType.receipt:
        writer.writeByte(0);
        break;
      case VoucherType.payment:
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
