/// Represents a single inventory item / SKU.
class Item {
  final int? id;
  final String name;
  final String? barcode;
  final int? categoryId;
  final String? categoryName; // populated by joined queries, not persisted directly
  final double quantity;
  final double unitPrice;
  final double lowStockThreshold;
  final String? unit; // e.g. pcs, kg, box
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Item({
    this.id,
    required this.name,
    this.barcode,
    this.categoryId,
    this.categoryName,
    this.quantity = 0,
    this.unitPrice = 0,
    this.lowStockThreshold = 0,
    this.unit,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isLowStock => quantity <= lowStockThreshold;

  double get totalValue => quantity * unitPrice;

  Item copyWith({
    int? id,
    String? name,
    String? barcode,
    int? categoryId,
    String? categoryName,
    double? quantity,
    double? unitPrice,
    double? lowStockThreshold,
    String? unit,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      unit: unit ?? this.unit,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'category_id': categoryId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'low_stock_threshold': lowStockThreshold,
      'unit': unit,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Item.fromMap(Map<String, Object?> map) {
    return Item(
      id: map['id'] as int?,
      name: map['name'] as String,
      barcode: map['barcode'] as String?,
      categoryId: map['category_id'] as int?,
      categoryName: map['category_name'] as String?,
      quantity: (map['quantity'] as num).toDouble(),
      unitPrice: (map['unit_price'] as num).toDouble(),
      lowStockThreshold: (map['low_stock_threshold'] as num).toDouble(),
      unit: map['unit'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
