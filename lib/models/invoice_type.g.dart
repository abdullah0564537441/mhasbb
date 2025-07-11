// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InvoiceTypeAdapter extends TypeAdapter<InvoiceType> {
  @override
  final int typeId = 5;

  @override
  InvoiceType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return InvoiceType.sale;
      case 1:
        return InvoiceType.purchase;
      case 2:
        return InvoiceType.salesReturn;
      case 3:
        return InvoiceType.purchaseReturn;
      default:
        return InvoiceType.sale;
    }
  }

  @override
  void write(BinaryWriter writer, InvoiceType obj) {
    switch (obj) {
      case InvoiceType.sale:
        writer.writeByte(0);
        break;
      case InvoiceType.purchase:
        writer.writeByte(1);
        break;
      case InvoiceType.salesReturn:
        writer.writeByte(2);
        break;
      case InvoiceType.purchaseReturn:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvoiceTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
