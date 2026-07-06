/// The kind of movement recorded against an item's stock.
enum TransactionType { stockIn, stockOut, adjustment }

extension TransactionTypeX on TransactionType {
  String get dbValue {
    switch (this) {
      case TransactionType.stockIn:
        return 'IN';
      case TransactionType.stockOut:
        return 'OUT';
      case TransactionType.adjustment:
        return 'ADJUST';
    }
  }

  String get label {
    switch (this) {
      case TransactionType.stockIn:
        return 'Stock In';
      case TransactionType.stockOut:
        return 'Stock Out';
      case TransactionType.adjustment:
        return 'Adjustment';
    }
  }

  static TransactionType fromDbValue(String value) {
    switch (value) {
      case 'IN':
        return TransactionType.stockIn;
      case 'OUT':
        return TransactionType.stockOut;
      case 'ADJUST':
        return TransactionType.adjustment;
      default:
        throw ArgumentError('Unknown transaction type: $value');
    }
  }
}

/// Represents a single stock movement (in / out / adjustment) for an item.
/// The full history of these rows is the audit trail for how an item's
/// quantity changed over time.
class StockTransaction {
  final int? id;
  final int itemId;
  final String? itemName; // populated by joined queries
  final TransactionType type;
  final double quantity;
  final String? note;
  final DateTime createdAt;

  const StockTransaction({
    this.id,
    required this.itemId,
    this.itemName,
    required this.type,
    required this.quantity,
    this.note,
    required this.createdAt,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'item_id': itemId,
      'type': type.dbValue,
      'quantity': quantity,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory StockTransaction.fromMap(Map<String, Object?> map) {
    return StockTransaction(
      id: map['id'] as int?,
      itemId: map['item_id'] as int,
      itemName: map['item_name'] as String?,
      type: TransactionTypeX.fromDbValue(map['type'] as String),
      quantity: (map['quantity'] as num).toDouble(),
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
