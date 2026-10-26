import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pharmacy_model.dart';

class PharmacyNotifier extends Notifier<List<PharmacyModel>> {
  final _firestore = FirebaseFirestore.instance;

  @override
  List<PharmacyModel> build() {
    Future.microtask(loadPharmacies);
    return [];
  }

  // Busca farmácias aprovadas e ativas do Firestore
  Future<void> loadPharmacies() async {
    try {
      final snapshot = await _firestore
          .collection('pharmacies')
          .where('isApproved', isEqualTo: true)
          .get();

      state = snapshot.docs
          .where((doc) => doc.data()['isActive'] == true)
          .map((doc) {
        final data = doc.data();
        return PharmacyModel(
          id:           doc.id,
          name:         data['name']         ?? '',
          address:      '${data['address'] ?? ''}, ${data['city'] ?? ''} - ${data['state'] ?? ''}',
          phone:        data['phone']         ?? '',
          latitude:     0,
          longitude:    0,
          distanceKm:   0,
          hasDelivery:  data['hasDelivery']   ?? false,
          hasPickup:    true,
          openingHours: data['openingHours']  ?? 'Consulte a farmácia',
          isOpen:       true,
          rating:       0,
        );
      }).toList();

      _log('Farmácias carregadas: ${state.length}');
    } catch (e) {
      _log('Erro ao carregar farmácias: $e');
    }
  }

  void _log(String msg) {
    if (kDebugMode) debugPrint('[Pharmacies] $msg');
  }
}

final pharmacyProvider = NotifierProvider<PharmacyNotifier, List<PharmacyModel>>(
  PharmacyNotifier.new,
);
