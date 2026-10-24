import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/medication_model.dart';

class MedicationNotifier extends Notifier<List<MedicationModel>> {
  @override
  List<MedicationModel> build() {
    loadMedications();
    return [];
  }

  // Carrega medicamentos salvos localmente
  Future<void> loadMedications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('medications');
      if (data != null) {
        final List decoded = jsonDecode(data);
        state = decoded.map((m) => MedicationModel.fromMap(m)).toList();
      }
    } catch (_) {}
  }

  // Salva no armazenamento local
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'medications',
      jsonEncode(state.map((m) => m.toMap()).toList()),
    );
  }

  // Adiciona novo medicamento
  Future<void> addMedication(MedicationModel medication) async {
    state = [...state, medication];
    await _save();
  }

  // Remove medicamento
  Future<void> removeMedication(String id) async {
    state = state.where((m) => m.id != id).toList();
    await _save();
  }

  // Registra dose tomada
  Future<void> takeDose(String id) async {
    state = state.map((m) {
      if (m.id == id && m.remainingPills > 0) {
        return m.copyWith(remainingPills: m.remainingPills - 1);
      }
      return m;
    }).toList();
    await _save();
  }

  // Medicamentos com alerta de reposição
  List<MedicationModel> get runningLow =>
      state.where((m) => m.isActive && m.isRunningLow).toList();
}

final medicationProvider =
    NotifierProvider<MedicationNotifier, List<MedicationModel>>(
  () => MedicationNotifier(),
);
