import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/pharmacy_model.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../app/theme.dart';

class PharmacyProductsScreen extends ConsumerStatefulWidget {
  final PharmacyModel pharmacy;
  const PharmacyProductsScreen({super.key, required this.pharmacy});

  @override
  ConsumerState<PharmacyProductsScreen> createState() =>
      _PharmacyProductsScreenState();
}

class _PharmacyProductsScreenState
    extends ConsumerState<PharmacyProductsScreen> {
  List<Map<String, dynamic>> _products  = [];
  final Map<String, int>     _cart      = {}; // productId → quantidade
  bool _isLoading  = true;
  bool _isDelivery = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('pharmacies')
          .doc(widget.pharmacy.id)
          .collection('products')
          .where('isActive', isEqualTo: true)
          .get();

      setState(() {
        _products = snapshot.docs.map((doc) => {
          'id':    doc.id,
          ...doc.data(),
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  int get _totalItems =>
      _cart.values.fold(0, (sum, qty) => sum + qty);

  double get _totalPrice {
    double total = 0;
    for (final entry in _cart.entries) {
      final product = _products.firstWhere(
          (p) => p['id'] == entry.key,
          orElse: () => {});
      if (product.isNotEmpty) {
        total += (product['price'] ?? 0) * entry.value;
      }
    }
    return total;
  }

  Future<void> _makeOrder() async {
    if (_cart.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final items = _cart.entries.map((entry) {
      final product = _products.firstWhere((p) => p['id'] == entry.key);
      return OrderItem(
        productId:   entry.key,
        productName: product['name'] ?? '',
        quantity:    entry.value,
        unitPrice:   (product['price'] ?? 0).toDouble(),
      );
    }).toList();

    final orderId = await ref.read(orderProvider.notifier).createOrder(
      pharmacyId:      widget.pharmacy.id,
      pharmacyName:    widget.pharmacy.name,
      items:           items,
      deliveryAddress: _isDelivery ? 'Endereço do usuário' : '',
      isDelivery:      _isDelivery,
    );

    if (orderId != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pedido realizado com sucesso!'),
          backgroundColor: AppTheme.primaryGreen,
          action: SnackBarAction(
            label: 'Ver pedidos',
            textColor: Colors.white,
            onPressed: () => Navigator.pop(context),
          ),
        ),
      );
      setState(() => _cart.clear());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pharmacy.name),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined,
                          size: 60, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('Nenhum produto disponível',
                          style: TextStyle(color: AppTheme.textGrey)),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Tipo de entrega
                    Container(
                      color: AppTheme.primaryGreen,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Row(
                        children: [
                          const Text('Tipo:',
                              style: TextStyle(color: Colors.white)),
                          const SizedBox(width: 12),
                          _TypeButton(
                            label: 'Entrega',
                            icon: Icons.delivery_dining,
                            selected: _isDelivery,
                            onTap: () =>
                                setState(() => _isDelivery = true),
                          ),
                          const SizedBox(width: 8),
                          _TypeButton(
                            label: 'Retirada',
                            icon: Icons.store_outlined,
                            selected: !_isDelivery,
                            onTap: () =>
                                setState(() => _isDelivery = false),
                          ),
                        ],
                      ),
                    ),

                    // Lista de produtos
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          final qty =
                              _cart[product['id'] as String] ?? 0;
                          return _ProductCard(
                            product: product,
                            quantity: qty,
                            onAdd: () => setState(() =>
                                _cart[product['id'] as String] =
                                    qty + 1),
                            onRemove: qty > 0
                                ? () => setState(() {
                                      if (qty == 1) {
                                        _cart.remove(
                                            product['id'] as String);
                                      } else {
                                        _cart[product['id']
                                            as String] = qty - 1;
                                      }
                                    })
                                : null,
                          );
                        },
                      ),
                    ),

                    // Botão de pedido
                    if (_cart.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, -4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _makeOrder,
                          child: Text(
                            'Fazer pedido • $_totalItems item(s) • R\$ ${_totalPrice.toStringAsFixed(2).replaceAll('.', ',')}',
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 16,
                  color: selected
                      ? AppTheme.primaryGreen
                      : Colors.white),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                      color: selected
                          ? AppTheme.primaryGreen
                          : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ],
          ),
        ),
      );
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback? onRemove;

  const _ProductCard({
    required this.product,
    required this.quantity,
    required this.onAdd,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final price = (product['price'] ?? 0).toDouble();
    final requiresPrescription =
        product['requiresPrescription'] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.medication,
                  color: AppTheme.primaryGreen),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product['name'] ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold)),
                  if (product['category'] != null)
                    Text(product['category'],
                        style: const TextStyle(
                            color: AppTheme.textGrey, fontSize: 12)),
                  Row(
                    children: [
                      Text(
                        'R\$ ${price.toStringAsFixed(2).replaceAll('.', ',')}',
                        style: const TextStyle(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.bold),
                      ),
                      if (requiresPrescription) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Receita',
                              style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 10)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Controle de quantidade
            Row(
              children: [
                if (quantity > 0) ...[
                  IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.remove_circle_outline,
                        color: AppTheme.primaryGreen),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8),
                    child: Text('$quantity',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ),
                ],
                IconButton(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_circle_outline,
                      color: AppTheme.primaryGreen),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
