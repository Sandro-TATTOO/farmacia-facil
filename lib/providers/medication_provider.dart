import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/medication_model.dart';

class MedicationNotifier extends Notifier<List<MedicationModel>> {
  final _firestore = FirebaseFirestore.instance;
  final _auth      = FirebaseAuth.instance;

  // ID do usuário logado
  String? get _userId => _auth.currentUser?.uid;

  // Referência da coleção de medicamentos do usuário no Firestore
  CollectionReference? get _collection {
    if (_userId == null) return null;
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('medications');
  }

  @override
  List<MedicationModel> build() {
    // Carrega ao iniciar
    Future.microtask(loadMedications);
    return [];
  }

  // Carrega medicamentos do Firestore
  Future<void> loadMedications() async {
    if (_collection == null) return;
    try {
      final snapshot = await _collection!
          .orderBy('createdAt', descending: true)
          .get();

      state = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return MedicationModel.fromMap({'id': doc.id, ...data});
      }).toList();

      _log('Medicamentos carregados: ${state.length}');
    } catch (e) {
      _log('Erro ao carregar medicamentos: $e');
    }
  }

  // Adiciona novo medicamento
  Future<void> addMedication(MedicationModel medication) async {
    if (_collection == null) return;
    try {
      final map = medication.toMap();
      map.remove('id'); // Firestore gera o ID automaticamente

      final docRef = await _collection!.add(map);

      // Adiciona ao estado local com o ID gerado pelo Firestore
      final newMed = MedicationModel.fromMap({
        'id': docRef.id,
        ...map,
      });
      state = [newMed, ...state];
      _log('Medicamento adicionado: ${medication.name}');
    } catch (e) {
      _log('Erro ao adicionar medicamento: $e');
    }
  }

  // Remove medicamento
  Future<void> removeMedication(String id) async {
    if (_collection == null) return;
    try {
      await _collection!.doc(id).delete();
      state = state.where((m) => m.id != id).toList();
      _log('Medicamento removido: $id');
    } catch (e) {
      _log('Erro ao remover medicamento: $e');
    }
  }

  // Registra dose tomada — decrementa comprimidos restantes
  Future<void> takeDose(String id) async {
    if (_collection == null) return;
    try {
      final med = state.firstWhere((m) => m.id == id);
      if (med.remainingPills <= 0) return;

      final newRemaining = med.remainingPills - 1;

      await _collection!.doc(id).update({
        'remainingPills': newRemaining,
      });

      state = state.map((m) {
        if (m.id == id) return m.copyWith(remainingPills: newRemaining);
        return m;
      }).toList();

      _log('Dose registrada: ${med.name} | Restantes: $newRemaining');
    } catch (e) {
      _log('Erro ao registrar dose: $e');
    }
  }

  // Medicamentos com alerta de reposição
  List<MedicationModel> get runningLow =>
      state.where((m) => m.isActive && m.isRunningLow).toList();

  void _log(String msg) {
    if (kDebugMode) debugPrint('[Medications] $msg');
  }
}

final medicationProvider =
    NotifierProvider<MedicationNotifier, List<MedicationModel>>(
  MedicationNotifier.new,
);
