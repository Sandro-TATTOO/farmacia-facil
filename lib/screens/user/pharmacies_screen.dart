import 'package:flutter/material.dart';
import '../../models/pharmacy_model.dart';
import '../../app/theme.dart';

class PharmaciesScreen extends StatelessWidget {
  const PharmaciesScreen({super.key});

  // Dados de exemplo enquanto não temos API real
  static final List<PharmacyModel> _mockPharmacies = [
    PharmacyModel(
      id: '1',
      name: 'Farmácia Popular',
      address: 'Rua das Flores, 123 - Centro',
      phone: '(11) 3333-1111',
      latitude: -23.55,
      longitude: -46.63,
      distanceKm: 0.3,
      hasDelivery: true,
      hasPickup: true,
      openingHours: 'Seg-Sáb: 7h-22h | Dom: 8h-18h',
      isOpen: true,
      rating: 4.5,
    ),
    PharmacyModel(
      id: '2',
      name: 'Drogaria Saúde',
      address: 'Av. Principal, 456 - Bairro Novo',
      phone: '(11) 3333-2222',
      latitude: -23.56,
      longitude: -46.64,
      distanceKm: 0.8,
      hasDelivery: true,
      hasPickup: true,
      openingHours: '24 horas',
      isOpen: true,
      rating: 4.2,
    ),
    PharmacyModel(
      id: '3',
      name: 'Farmácia Bem Estar',
      address: 'Rua Saudável, 789 - Vila Verde',
      phone: '(11) 3333-3333',
      latitude: -23.57,
      longitude: -46.65,
      distanceKm: 1.2,
      hasDelivery: false,
      hasPickup: true,
      openingHours: 'Seg-Sex: 8h-20h | Sáb: 8h-14h',
      isOpen: false,
      rating: 4.0,
    ),
    PharmacyModel(
      id: '4',
      name: 'Drogão Super',
      address: 'Shopping Central, Loja 42',
      phone: '(11) 3333-4444',
      latitude: -23.54,
      longitude: -46.62,
      distanceKm: 1.8,
      hasDelivery: true,
      hasPickup: true,
      openingHours: 'Todos os dias: 10h-22h',
      isOpen: true,
      rating: 4.7,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmácias Próximas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: () {},
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
                hintText: 'Buscar por nome ou remédio...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),

          // Filtros
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _FilterChip(label: 'Todas', selected: true, onTap: () {}),
                _FilterChip(label: 'Com entrega', selected: false, onTap: () {}),
                _FilterChip(label: 'Abertas agora', selected: false, onTap: () {}),
                _FilterChip(label: 'Mais próximas', selected: false, onTap: () {}),
              ],
            ),
          ),

          // Aviso de localização
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.location_on, color: Colors.blue, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mostrando farmácias próximas à sua localização',
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),

          // Lista de farmácias
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _mockPharmacies.length,
              itemBuilder: (context, index) {
                return _PharmacyCard(pharmacy: _mockPharmacies[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primaryGreen : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppTheme.primaryGreen : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppTheme.textDark,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
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
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        pharmacy.address,
                        style: const TextStyle(
                          color: AppTheme.textGrey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status aberta/fechada
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            const SizedBox(height: 12),

            // Detalhes
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 16, color: AppTheme.textGrey),
                const SizedBox(width: 4),
                Text(
                  pharmacy.formattedDistance,
                  style: const TextStyle(
                      color: AppTheme.textGrey, fontSize: 13),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.star, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  pharmacy.rating.toStringAsFixed(1),
                  style: const TextStyle(
                      color: AppTheme.textGrey, fontSize: 13),
                ),
                const SizedBox(width: 16),
                if (pharmacy.hasDelivery) ...[
                  const Icon(Icons.delivery_dining,
                      size: 16, color: AppTheme.primaryGreen),
                  const SizedBox(width: 4),
                  const Text(
                    'Entrega',
                    style: TextStyle(
                        color: AppTheme.primaryGreen, fontSize: 13),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),

            Row(
              children: [
                const Icon(Icons.access_time_outlined,
                    size: 14, color: AppTheme.textGrey),
                const SizedBox(width: 4),
                Text(
                  pharmacy.openingHours,
                  style: const TextStyle(
                      color: AppTheme.textGrey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Botões
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
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
                    onPressed: pharmacy.isOpen ? () {} : null,
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
