// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OrderAdapter extends TypeAdapter<Order> {
  @override
  final int typeId = 1;

  @override
  Order read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Order(
      id: fields[0] as String,
      customerName: fields[1] as String,
      items: (fields[2] as List).cast<OrderItem>(),
      totalAmount: fields[3] as double,
      orderDate: fields[4] as DateTime,
      paymentMethod: fields[6] as String,
      comments: fields[5] as String,
      subtotal: fields[7] as double,
      discountAmount: fields[8] as double,
      taxRate: fields[9] as double,
      taxAmount: fields[10] as double,
      invoiceNumber: fields[11] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Order obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.customerName)
      ..writeByte(2)
      ..write(obj.items)
      ..writeByte(3)
      ..write(obj.totalAmount)
      ..writeByte(4)
      ..write(obj.orderDate)
      ..writeByte(5)
      ..write(obj.comments)
      ..writeByte(6)
      ..write(obj.paymentMethod)
      ..writeByte(7)
      ..write(obj.subtotal)
      ..writeByte(8)
      ..write(obj.discountAmount)
      ..writeByte(9)
      ..write(obj.taxRate)
      ..writeByte(10)
      ..write(obj.taxAmount)
      ..writeByte(11)
      ..write(obj.invoiceNumber);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
