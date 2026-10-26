import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/pharmacy_provider.dart';
import '../../models/pharmacy_model.dart';
import '../../app/theme.dart';
import 'pharmacy_products_screen.dart';

class PharmaciesScreen extends ConsumerWidget {
  const PharmaciesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pharmacies = ref.watch(pharmacyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmácias Próximas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () =>
                ref.read(pharmacyProvider.notifier).loadPharmacies(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de busca
          Container(
            color: AppTheme.primaryGreen,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar farmácia...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),

          // Lista de farmácias
          Expanded(
            child: pharmacies.isEmpty
                ? const _EmptyPharmacies()
                : RefreshIndicator(
                    onRefresh: () => ref
                        .read(pharmacyProvider.notifier)
                        .loadPharmacies(),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: pharmacies.length,
                      itemBuilder: (context, index) =>
                          _PharmacyCard(pharmacy: pharmacies[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PharmacyCard extends StatelessWidget {
  final PharmacyModel pharmacy;
  const _PharmacyCard({required this.pharmacy});

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
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pharmacy.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        pharmacy.address,
                        style: const TextStyle(
                            color: AppTheme.textGrey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: pharmacy.isOpen
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    pharmacy.isOpen ? 'Aberta' : 'Fechada',
                    style: TextStyle(
                      color: pharmacy.isOpen
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                if (pharmacy.hasDelivery) ...[
                  const Icon(Icons.delivery_dining,
                      size: 16, color: AppTheme.primaryGreen),
                  const SizedBox(width: 4),
                  const Text('Entrega',
                      style: TextStyle(
                          color: AppTheme.primaryGreen, fontSize: 13)),
                  const SizedBox(width: 16),
                ],
                const Icon(Icons.phone_outlined,
                    size: 16, color: AppTheme.textGrey),
                const SizedBox(width: 4),
                Text(pharmacy.phone,
                    style: const TextStyle(
                        color: AppTheme.textGrey, fontSize: 13)),
              ],
            ),

            if (pharmacy.openingHours.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.access_time_outlined,
                      size: 14, color: AppTheme.textGrey),
                  const SizedBox(width: 4),
                  Text(pharmacy.openingHours,
                      style: const TextStyle(
                          color: AppTheme.textGrey, fontSize: 12)),
                ],
              ),
            ],
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final uri = Uri(
                          scheme: 'tel',
                          path: pharmacy.phone.replaceAll(RegExp(r'\D'), ''));
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                    icon: const Icon(Icons.phone_outlined, size: 16),
                    label: const Text('Ligar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryGreen,
                      side: const BorderSide(color: AppTheme.primaryGreen),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PharmacyProductsScreen(pharmacy: pharmacy),
                      ),
                    ),
                    icon: const Icon(Icons.shopping_bag_outlined, size: 16),
                    label: const Text('Fazer pedido'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPharmacies extends StatelessWidget {
  const _EmptyPharmacies();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_pharmacy_outlined,
              size: 70, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('Nenhuma farmácia disponível',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'As farmácias cadastradas e aprovadas\naparecerão aqui.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textGrey),
          ),
        ],
      ),
    );
  }
}
