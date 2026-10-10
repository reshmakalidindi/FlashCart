class Product {
  final String id;
  final String name;
  final String barcode;
  final double price;
  final String weight;
  final String unit;
  final String category;
  final String imageUrl;
  final String description;
  final int stock;
  final double taxPercentage;
  final String taxCode;
  final bool isAvailable;
  final String storeId;

  const Product({
    required this.id,
    required this.name,
    required this.barcode,
    required this.price,
    required this.weight,
    required this.unit,
    required this.category,
    required this.imageUrl,
    required this.description,
    required this.stock,
    required this.taxPercentage,
    this.taxCode = 'GST_STANDARD',
    required this.isAvailable,
    this.storeId = 'STORE_DMART_001',
  });

  factory Product.fromMap(Map<String, dynamic> map, String docId) {
    return Product(
      id: docId,
      name: map['name'] ?? '',
      barcode: map['barcode'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      weight: map['weight'] ?? '',
      unit: map['unit'] ?? '',
      category: map['category'] ?? 'General',
      imageUrl: map['imageUrl'] ?? map['image_url'] ?? '',
      description: map['description'] ?? '',
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      taxPercentage: (map['taxPercentage'] as num?)?.toDouble() ?? 
          (((map['tax_rate'] as num?)?.toDouble() ?? 0.0) * 100.0),
      taxCode: map['taxCode'] ?? 'GST_${map['taxPercentage'] ?? (((map['tax_rate'] as num?)?.toDouble() ?? 0.0) * 100.0).toInt()}',
      isAvailable: map['isAvailable'] ?? map['is_active'] ?? true,
      storeId: map['storeId'] ?? map['store_id'] ?? 'STORE_DMART_001',
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final taxRate = (json['tax_rate'] as num?)?.toDouble() ?? 
        (((json['taxPercentage'] as num?)?.toDouble() ?? 0.0) / 100.0);
    return Product(
      id: (json['product_id'] ?? json['id']?.toString() ?? ''),
      name: json['name'] ?? '',
      barcode: json['barcode'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      weight: json['weight'] ?? '',
      unit: json['unit'] ?? '',
      category: json['category'] ?? 'General',
      imageUrl: json['image_url'] ?? json['imageUrl'] ?? '',
      description: json['description'] ?? '${json['brand'] ?? ''} ${json['name'] ?? ''}'.trim(),
      stock: (json['stock'] as num?)?.toInt() ?? 100,
      taxPercentage: (taxRate * 100.0),
      taxCode: json['hsn_code'] != null ? 'HSN_${json['hsn_code']}' : 'GST_${(taxRate * 100).toInt()}',
      isAvailable: json['is_active'] ?? json['isAvailable'] ?? true,
      storeId: json['store_id'] ?? json['storeId'] ?? 'STORE_DMART_001',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'barcode': barcode,
      'price': price,
      'weight': weight,
      'unit': unit,
      'category': category,
      'imageUrl': imageUrl,
      'description': description,
      'stock': stock,
      'taxPercentage': taxPercentage,
      'taxCode': taxCode,
      'isAvailable': isAvailable,
      'storeId': storeId,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? barcode,
    double? price,
    String? weight,
    String? unit,
    String? category,
    String? imageUrl,
    String? description,
    int? stock,
    double? taxPercentage,
    String? taxCode,
    bool? isAvailable,
    String? storeId,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      price: price ?? this.price,
      weight: weight ?? this.weight,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      stock: stock ?? this.stock,
      taxPercentage: taxPercentage ?? this.taxPercentage,
      taxCode: taxCode ?? this.taxCode,
      isAvailable: isAvailable ?? this.isAvailable,
      storeId: storeId ?? this.storeId,
    );
  }
}
