import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/medication_provider.dart';
import '../../models/medication_model.dart';
import '../../app/theme.dart';

class MedicationsScreen extends ConsumerWidget {
  const MedicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medications = ref.watch(medicationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Remédios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showAddMedicationDialog(context, ref),
          ),
        ],
      ),
      body: medications.isEmpty
          ? _EmptyMedications(
              onAdd: () => _showAddMedicationDialog(context, ref))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: medications.length,
              itemBuilder: (context, index) {
                final med = medications[index];
                return _MedicationCard(
                  medication: med,
                  onTakeDose: () =>
                      ref.read(medicationProvider.notifier).takeDose(med.id),
                  onDelete: () =>
                      ref.read(medicationProvider.notifier).removeMedication(med.id),
                );
              },
            ),
      floatingActionButton: medications.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showAddMedicationDialog(context, ref),
              backgroundColor: AppTheme.primaryGreen,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Adicionar',
                  style: TextStyle(color: Colors.white)),
            )
          : null,
    );
  }

  void _showAddMedicationDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AddMedicationSheet(ref: ref),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  final MedicationModel medication;
  final VoidCallback onTakeDose;
  final VoidCallback onDelete;

  const _MedicationCard({
    required this.medication,
    required this.onTakeDose,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final progress = medication.remainingPercentage / 100;
    final progressColor = medication.isRunningLow
        ? Colors.orange
        : AppTheme.primaryGreen;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: progressColor.withOpacity(0.15),
                  child: Icon(Icons.medication, color: progressColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medication.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${medication.dosage} • ${medication.timesPerDay}x por dia',
                        style: const TextStyle(
                          color: AppTheme.textGrey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Remover'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'delete') onDelete();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Horários
            Wrap(
              spacing: 8,
              children: medication.times
                  .map((time) => Chip(
                        label: Text(time,
                            style: const TextStyle(fontSize: 12)),
                        backgroundColor:
                            AppTheme.primaryGreen.withOpacity(0.1),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),

            // Barra de progresso de comprimidos
            Row(
              children: [
                const Icon(Icons.inventory_2_outlined,
                    size: 16, color: AppTheme.textGrey),
                const SizedBox(width: 8),
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade200,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(progressColor),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${medication.remainingPills} restantes',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        medication.isRunningLow ? Colors.orange : AppTheme.textGrey,
                    fontWeight: medication.isRunningLow
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),

            if (medication.isRunningLow) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber, size: 14, color: Colors.orange),
                    SizedBox(width: 4),
                    Text(
                      'Estoque baixo — hora de repor!',
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: medication.remainingPills > 0 ? onTakeDose : null,
                icon: const Icon(Icons.check),
                label: const Text('Registrar dose tomada'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryGreen,
                  side: const BorderSide(color: AppTheme.primaryGreen),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddMedicationSheet extends StatefulWidget {
  final WidgetRef ref;
  const _AddMedicationSheet({required this.ref});

  @override
  State<_AddMedicationSheet> createState() => _AddMedicationSheetState();
}

class _AddMedicationSheetState extends State<_AddMedicationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _totalPillsController = TextEditingController();
  int _timesPerDay = 1;
  List<TimeOfDay> _selectedTimes = [const TimeOfDay(hour: 8, minute: 0)];
  DateTime _startDate = DateTime.now();
  int _durationDays = 7;

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _instructionsController.dispose();
    _totalPillsController.dispose();
    super.dispose();
  }

  void _updateTimesCount(int count) {
    setState(() {
      _timesPerDay = count;
      _selectedTimes = List.generate(
        count,
        (i) => TimeOfDay(hour: 8 + (i * (24 ~/ count)), minute: 0),
      );
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final totalPills = int.tryParse(_totalPillsController.text) ?? (_timesPerDay * _durationDays);

    final medication = MedicationModel(
      id: 'med_${DateTime.now().millisecondsSinceEpoch}',
      userId: FirebaseAuth.instance.currentUser?.uid ?? '',
      name: _nameController.text.trim(),
      dosage: _dosageController.text.trim(),
      instructions: _instructionsController.text.trim(),
      timesPerDay: _timesPerDay,
      times: _selectedTimes
          .map((t) =>
              '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}')
          .toList(),
      startDate: _startDate,
      endDate: _startDate.add(Duration(days: _durationDays)),
      totalDays: _durationDays,
      totalPills: totalPills,
      remainingPills: totalPills,
      isActive: true,
      createdAt: DateTime.now(),
    );

    await widget.ref.read(medicationProvider.notifier).addMedication(medication);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Adicionar Remédio',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome do remédio',
                  prefixIcon: Icon(Icons.medication_outlined),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dosageController,
                      decoration: const InputDecoration(
                        labelText: 'Dosagem',
                        hintText: 'Ex: 500mg',
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Informe a dosagem' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _totalPillsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Qtd. comprimidos',
                        hintText: 'Ex: 30',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _instructionsController,
                decoration: const InputDecoration(
                  labelText: 'Instruções',
                  hintText: 'Ex: Tomar após as refeições',
                  prefixIcon: Icon(Icons.info_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Vezes por dia
              const Text('Quantas vezes por dia?',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [1, 2, 3, 4].map((n) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('$n×'),
                      selected: _timesPerDay == n,
                      onSelected: (_) => _updateTimesCount(n),
                      selectedColor: AppTheme.primaryGreen,
                      labelStyle: TextStyle(
                        color: _timesPerDay == n ? Colors.white : AppTheme.textDark,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Duração
              const Text('Duração do tratamento',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [7, 14, 21, 30, 60].map((days) {
                  return ChoiceChip(
                    label: Text('$days dias'),
                    selected: _durationDays == days,
                    onSelected: (_) => setState(() => _durationDays = days),
                    selectedColor: AppTheme.primaryGreen,
                    labelStyle: TextStyle(
                      color: _durationDays == days ? Colors.white : AppTheme.textDark,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('Salvar remédio'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyMedications extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyMedications({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medication_outlined,
                size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'Nenhum remédio cadastrado',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark),
            ),
            const SizedBox(height: 8),
            const Text(
              'Adicione seus remédios para receber lembretes nos horários certos.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textGrey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar remédio'),
            ),
          ],
        ),
      ),
    );
  }
}
