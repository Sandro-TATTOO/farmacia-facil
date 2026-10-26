// Modelo de pedido compartilhado entre app usuário e vendedor
class OrderItem {
  final String productId;
  final String productName;
  final int    quantity;
  final double unitPrice;

  const OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  double get subtotal => unitPrice * quantity;

  Map<String, dynamic> toMap() => {
    'productId':   productId,
    'productName': productName,
    'quantity':    quantity,
    'unitPrice':   unitPrice,
  };

  factory OrderItem.fromMap(Map<String, dynamic> map) => OrderItem(
    productId:   map['productId']   ?? '',
    productName: map['productName'] ?? '',
    quantity:    map['quantity']    ?? 1,
    unitPrice:   (map['unitPrice']  ?? 0).toDouble(),
  );
}

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  delivering,
  delivered,
  cancelled,
}

extension OrderStatusLabel on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:    return 'Aguardando confirmação';
      case OrderStatus.confirmed:  return 'Confirmado';
      case OrderStatus.preparing:  return 'Em preparação';
      case OrderStatus.ready:      return 'Pronto';
      case OrderStatus.delivering: return 'Saiu para entrega';
      case OrderStatus.delivered:  return 'Entregue';
      case OrderStatus.cancelled:  return 'Cancelado';
    }
  }

  String get emoji {
    switch (this) {
      case OrderStatus.pending:    return '⏳';
      case OrderStatus.confirmed:  return '✅';
      case OrderStatus.preparing:  return '👨‍🍳';
      case OrderStatus.ready:      return '📦';
      case OrderStatus.delivering: return '🛵';
      case OrderStatus.delivered:  return '🎉';
      case OrderStatus.cancelled:  return '❌';
    }
  }
}

class OrderModel {
  final String      id;
  final String      userId;
  final String      userName;
  final String      pharmacyId;
  final String      pharmacyName;
  final OrderStatus status;
  final List<OrderItem> items;
  final double      totalPrice;
  final String      deliveryAddress;
  final bool        isDelivery;
  final DateTime    createdAt;
  final DateTime?   updatedAt;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.pharmacyId,
    required this.pharmacyName,
    required this.status,
    required this.items,
    required this.totalPrice,
    required this.deliveryAddress,
    required this.isDelivery,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'id':              id,
    'userId':          userId,
    'userName':        userName,
    'pharmacyId':      pharmacyId,
    'pharmacyName':    pharmacyName,
    'status':          status.name,
    'items':           items.map((i) => i.toMap()).toList(),
    'totalPrice':      totalPrice,
    'deliveryAddress': deliveryAddress,
    'isDelivery':      isDelivery,
    'createdAt':       createdAt.toIso8601String(),
    'updatedAt':       updatedAt?.toIso8601String(),
  };

  factory OrderModel.fromMap(Map<String, dynamic> map) => OrderModel(
    id:              map['id']             ?? '',
    userId:          map['userId']         ?? '',
    userName:        map['userName']       ?? '',
    pharmacyId:      map['pharmacyId']     ?? '',
    pharmacyName:    map['pharmacyName']   ?? '',
    status: OrderStatus.values.firstWhere(
      (s) => s.name == map['status'],
      orElse: () => OrderStatus.pending,
    ),
    items: (map['items'] as List? ?? [])
        .map((i) => OrderItem.fromMap(Map<String, dynamic>.from(i)))
        .toList(),
    totalPrice:      (map['totalPrice']     ?? 0).toDouble(),
    deliveryAddress:  map['deliveryAddress'] ?? '',
    isDelivery:       map['isDelivery']      ?? false,
    createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String()),
    updatedAt: map['updatedAt'] != null
        ? DateTime.parse(map['updatedAt'])
        : null,
  );
}
