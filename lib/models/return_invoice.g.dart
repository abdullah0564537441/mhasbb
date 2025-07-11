// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'return_invoice.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReturnInvoiceAdapter extends TypeAdapter<ReturnInvoice> {
  @override
  final int typeId = 9;

  @override
  ReturnInvoice read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReturnInvoice(
      id: fields[0] as String,
      returnNumber: fields[1] as String,
      date: fields[2] as DateTime,
      originalInvoiceNumber: fields[3] as String?,
      originalInvoiceType: fields[4] as InvoiceType?,
      customerName: fields[5] as String?,
      supplierName: fields[6] as String?,
      items: (fields[7] as HiveList).castHiveList(),
      totalAmount: fields[8] as double,
      notes: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ReturnInvoice obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.returnNumber)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.originalInvoiceNumber)
      ..writeByte(4)
      ..write(obj.originalInvoiceType)
      ..writeByte(5)
      ..write(obj.customerName)
      ..writeByte(6)
      ..write(obj.supplierName)
      ..writeByte(7)
      ..write(obj.items)
      ..writeByte(8)
      ..write(obj.totalAmount)
      ..writeByte(9)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReturnInvoiceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
