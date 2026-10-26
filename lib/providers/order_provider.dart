import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order_model.dart';

class OrderNotifier extends Notifier<List<OrderModel>> {
  final _firestore = FirebaseFirestore.instance;
  final _auth      = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;
  String? get _userName => _auth.currentUser?.displayName
      ?? _auth.currentUser?.email?.split('@')[0];

  @override
  List<OrderModel> build() {
    Future.microtask(loadOrders);
    return [];
  }

  // Carrega pedidos do usuário
  Future<void> loadOrders() async {
    if (_userId == null) return;
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: _userId)
          .orderBy('createdAt', descending: true)
          .get();

      state = snapshot.docs.map((doc) =>
          OrderModel.fromMap({'id': doc.id, ...doc.data()})).toList();

      _log('Pedidos carregados: ${state.length}');
    } catch (e) {
      _log('Erro ao carregar pedidos: $e');
    }
  }

  // Cria novo pedido — envia para o Firestore
  Future<String?> createOrder({
    required String pharmacyId,
    required String pharmacyName,
    required List<OrderItem> items,
    required String deliveryAddress,
    required bool isDelivery,
  }) async {
    if (_userId == null) return null;

    try {
      final totalPrice = items.fold(0.0, (sum, i) => sum + i.subtotal);

      final orderData = {
        'userId':          _userId,
        'userName':        _userName ?? 'Usuário',
        'pharmacyId':      pharmacyId,
        'pharmacyName':    pharmacyName,
        'status':          OrderStatus.pending.name,
        'items':           items.map((i) => i.toMap()).toList(),
        'totalPrice':      totalPrice,
        'deliveryAddress': deliveryAddress,
        'isDelivery':      isDelivery,
        'createdAt':       DateTime.now().toIso8601String(),
        'updatedAt':       null,
      };

      // Salva no Firestore — o app do vendedor vai ler daqui
      final docRef = await _firestore.collection('orders').add(orderData);

      final newOrder = OrderModel.fromMap({'id': docRef.id, ...orderData});
      state = [newOrder, ...state];

      _log('Pedido criado: ${docRef.id} → farmácia $pharmacyId');
      return docRef.id;
    } catch (e) {
      _log('Erro ao criar pedido: $e');
      return null;
    }
  }

  // Pedidos ativos (não cancelados nem entregues)
  List<OrderModel> get activeOrders => state
      .where((o) =>
          o.status != OrderStatus.delivered &&
          o.status != OrderStatus.cancelled)
      .toList();

  void _log(String msg) {
    if (kDebugMode) debugPrint('[Order] $msg');
  }
}

final orderProvider = NotifierProvider<OrderNotifier, List<OrderModel>>(
  OrderNotifier.new,
);
