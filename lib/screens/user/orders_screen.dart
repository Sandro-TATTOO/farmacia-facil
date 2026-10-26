import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/order_provider.dart';
import '../../models/order_model.dart';
import '../../app/theme.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(orderProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Pedidos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => ref.read(orderProvider.notifier).loadOrders(),
          ),
        ],
      ),
      body: orders.isEmpty
          ? const _EmptyOrders()
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(orderProvider.notifier).loadOrders(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (context, index) =>
                    _OrderCard(order: orders[index]),
              ),
            ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

  Color get _color {
    switch (order.status) {
      case OrderStatus.pending:    return Colors.orange;
      case OrderStatus.confirmed:  return Colors.blue;
      case OrderStatus.preparing:  return Colors.purple;
      case OrderStatus.ready:      return Colors.teal;
      case OrderStatus.delivering: return Colors.indigo;
      case OrderStatus.delivered:  return AppTheme.primaryGreen;
      case OrderStatus.cancelled:  return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    order.pharmacyName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${order.status.emoji} ${order.status.label}',
                    style: TextStyle(
                        color: _color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${order.items.length} item(s) — R\$ ${order.totalPrice.toStringAsFixed(2).replaceAll('.', ',')}',
              style: const TextStyle(color: AppTheme.textGrey),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  order.isDelivery
                      ? Icons.delivery_dining
                      : Icons.store_outlined,
                  size: 14,
                  color: AppTheme.textGrey,
                ),
                const SizedBox(width: 4),
                Text(
                  order.isDelivery ? 'Entrega' : 'Retirada',
                  style: const TextStyle(
                      color: AppTheme.textGrey, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Itens
            ...order.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.medication_outlined,
                      size: 14, color: AppTheme.textGrey),
                  const SizedBox(width: 6),
                  Expanded(child: Text(item.productName,
                      style: const TextStyle(fontSize: 13))),
                  Text('${item.quantity}x  R\$ ${item.subtotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textGrey)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.receipt_long_outlined,
            size: 70, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        const Text('Nenhum pedido ainda',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
          'Seus pedidos feitos nas farmácias\naparecerão aqui.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textGrey),
        ),
      ],
    ),
  );
}
