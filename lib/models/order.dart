import 'cart_item.dart';

class OrderModel {
  final String orderId;
  final String userId;
  final String userName;
  final String userEmail;
  final List<CartItem> items;
  final double subtotal;
  final double tax;
  final double discount;
  final double total;
  final String paymentStatus; // pending, paid, failed
  final String paymentId;
  final String paymentMethod;
  final String orderStatus; // created, paid, completed, cancelled
  final DateTime createdAt;
  final bool exitVerified;
  final DateTime? verifiedAt;
  final String? verifiedBy;
  final String? exitToken;

  const OrderModel({
    required this.orderId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.discount,
    required this.total,
    required this.paymentStatus,
    required this.paymentId,
    this.paymentMethod = 'UPI / Online Payment',
    required this.orderStatus,
    required this.createdAt,
    required this.exitVerified,
    this.verifiedAt,
    this.verifiedBy,
    this.exitToken,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, String docId) {
    final rawItems = map['items'] as List<dynamic>? ?? [];
    final items = rawItems
        .map((e) => CartItem.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    return OrderModel(
      orderId: docId.isNotEmpty ? docId : (map['order_id'] ?? map['orderId'] ?? ''),
      userId: map['userId'] ?? map['user_id'] ?? '',
      userName: map['userName'] ?? map['user_name'] ?? 'Customer',
      userEmail: map['userEmail'] ?? map['user_email'] ?? '',
      items: items,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      tax: (map['tax'] ?? map['tax_amount'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] ?? map['discount_amount'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] ?? map['grand_total'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: (map['paymentStatus'] ?? map['payment_status'] ?? 'pending').toString().toLowerCase(),
      paymentId: map['paymentId'] ?? map['payment_id'] ?? '',
      paymentMethod: map['paymentMethod'] ?? map['payment_method'] ?? 'UPI / Online Payment',
      orderStatus: (map['orderStatus'] ?? map['status'] ?? 'created').toString().toLowerCase(),
      createdAt: map['createdAt'] != null || map['created_at'] != null
          ? DateTime.tryParse((map['createdAt'] ?? map['created_at']).toString()) ?? DateTime.now()
          : DateTime.now(),
      exitVerified: map['exitVerified'] ?? map['exit_verified'] ?? false,
      verifiedAt: map['verifiedAt'] != null || map['verified_at'] != null
          ? DateTime.tryParse((map['verifiedAt'] ?? map['verified_at']).toString())
          : null,
      verifiedBy: map['verifiedBy'] ?? map['verified_by'],
      exitToken: map['exitToken'] ?? map['exit_token'],
    );
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel.fromMap(json, json['order_id'] ?? '');
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'items': items.map((i) => i.toMap()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'discount': discount,
      'total': total,
      'paymentStatus': paymentStatus,
      'paymentId': paymentId,
      'paymentMethod': paymentMethod,
      'orderStatus': orderStatus,
      'createdAt': createdAt.toIso8601String(),
      'exitVerified': exitVerified,
      'verifiedAt': verifiedAt?.toIso8601String(),
      'verifiedBy': verifiedBy,
      'exitToken': exitToken,
    };
  }

  OrderModel copyWith({
    String? orderId,
    String? userId,
    String? userName,
    String? userEmail,
    List<CartItem>? items,
    double? subtotal,
    double? tax,
    double? discount,
    double? total,
    String? paymentStatus,
    String? paymentId,
    String? paymentMethod,
    String? orderStatus,
    DateTime? createdAt,
    bool? exitVerified,
    DateTime? verifiedAt,
    String? verifiedBy,
    String? exitToken,
  }) {
    return OrderModel(
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentId: paymentId ?? this.paymentId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      orderStatus: orderStatus ?? this.orderStatus,
      createdAt: createdAt ?? this.createdAt,
      exitVerified: exitVerified ?? this.exitVerified,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      exitToken: exitToken ?? this.exitToken,
    );
  }
}
