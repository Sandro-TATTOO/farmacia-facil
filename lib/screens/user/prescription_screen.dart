import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../app/theme.dart';

class PrescriptionScreen extends ConsumerStatefulWidget {
  const PrescriptionScreen({super.key});

  @override
  ConsumerState<PrescriptionScreen> createState() =>
      _PrescriptionScreenState();
}

class _PrescriptionScreenState extends ConsumerState<PrescriptionScreen> {
  XFile?            _imageFile;
  bool              _isAnalyzing = false;
  List<_Medicine>   _medicines   = [];
  String?           _errorMessage;
  String            _rawText     = '';

  final _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source:       source,
        maxWidth:     1200,
        imageQuality: 90,
      );
      if (picked == null) return;

      setState(() {
        _imageFile    = picked;
        _medicines    = [];
        _errorMessage = null;
        _rawText      = '';
      });

      await _analyzeImage(picked);
    } catch (e) {
      setState(() => _errorMessage = 'Erro ao acessar a câmera/galeria.');
    }
  }

  Future<void> _analyzeImage(XFile file) async {
    setState(() { _isAnalyzing = true; _errorMessage = null; });

    try {
      // ML Kit não funciona no Web — mostra mensagem
      if (kIsWeb) {
        setState(() {
          _errorMessage = 'Para ler receitas, use o app no seu celular Android.';
          _isAnalyzing  = false;
        });
        return;
      }

      final inputImage  = InputImage.fromFilePath(file.path);
      final recognizer  = TextRecognizer(script: TextRecognitionScript.latin);
      final recognized  = await recognizer.processImage(inputImage);
      await recognizer.close();

      final text = recognized.text;
      setState(() => _rawText = text);

      if (text.trim().isEmpty) {
        setState(() {
          _errorMessage = 'Nenhum texto encontrado. Tente uma foto mais nítida.';
          _isAnalyzing  = false;
        });
        return;
      }

      // Extrai possíveis medicamentos do texto
      final medicines = _extractMedicines(text);

      if (medicines.isEmpty) {
        setState(() {
          _errorMessage = 'Nenhum medicamento identificado. Verifique o texto abaixo e adicione manualmente.';
          _isAnalyzing  = false;
        });
        return;
      }

      setState(() {
        _medicines   = medicines;
        _isAnalyzing = false;
      });

    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao analisar a imagem. Tente novamente.';
        _isAnalyzing  = false;
      });
    }
  }

  // Extrai nomes de medicamentos do texto lido
  List<_Medicine> _extractMedicines(String text) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.length > 3)
        .toList();

    final medicines = <_Medicine>[];
    final seen      = <String>{};

    // Palavras que indicam que a linha é um medicamento
    final medPatterns = RegExp(
      r'(mg|ml|mcg|comprimido|cápsula|capsula|xarope|gotas|pomada|creme|solução|solucao|injetável|injetavel|'
      r'ampola|frasco|bisnaga|supositório|supositorio|spray|aerossol|adesivo|parche)',
      caseSensitive: false,
    );

    // Palavras a ignorar (não são medicamentos)
    final ignoreWords = {
      'receita', 'médico', 'medico', 'paciente', 'data', 'assinatura',
      'carimbo', 'crm', 'endereço', 'endereco', 'telefone', 'nome',
      'idade', 'cpf', 'rg', 'uso', 'interno', 'externo', 'dose',
      'tomar', 'aplicar', 'via', 'oral', 'topica', 'tópica',
      'vezes', 'dias', 'semanas', 'meses', 'horas',
    };

    for (final line in lines) {
      final lower = line.toLowerCase();

      // Ignora linhas muito curtas ou com palavras de cabeçalho
      if (ignoreWords.any((w) => lower.contains(w))) continue;

      // Linhas com padrão de medicamento (tem unidade como mg, ml, etc.)
      if (medPatterns.hasMatch(lower)) {
        // Pega só o nome (antes da dosagem)
        final name = line
            .split(RegExp(r'\s+\d'))
            .first
            .replaceAll(RegExp(r'[^a-zA-ZÀ-ÿ\s\-]'), '')
            .trim();

        if (name.length > 3 && !seen.contains(name.toLowerCase())) {
          seen.add(name.toLowerCase());
          medicines.add(_Medicine(name: name));
        }
      }
    }

    // Se não encontrou nada com padrão, sugere linhas que parecem nomes próprios
    if (medicines.isEmpty) {
      for (final line in lines) {
        if (line.length < 4 || line.length > 50) continue;
        final lower = line.toLowerCase();
        if (ignoreWords.any((w) => lower.contains(w))) continue;

        // Linha começa com maiúscula = possível nome de medicamento
        if (line[0].toUpperCase() == line[0] &&
            !line[0].contains(RegExp(r'\d')) &&
            !seen.contains(lower)) {
          seen.add(lower);
          medicines.add(_Medicine(name: line.replaceAll(RegExp(r'[^a-zA-ZÀ-ÿ\s\-]'), '').trim()));
          if (medicines.length >= 10) break;
        }
      }
    }

    return medicines.where((m) => m.name.length > 3).toList();
  }

  void _addManual() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Adicionar medicamento'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Nome do medicamento',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                setState(() =>
                    _medicines.add(_Medicine(name: ctrl.text.trim())));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  void _searchInPharmacies() {
    final confirmed = _medicines.where((m) => m.confirmed).toList();
    if (confirmed.isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Buscando ${confirmed.length} medicamento(s) nas farmácias...'),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
    context.go('/pharmacies');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ler Receita')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // Instrução
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.tips_and_updates_outlined,
                      color: AppTheme.primaryGreen),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Fotografe sua receita. O app lê o texto e identifica os medicamentos automaticamente.',
                      style: TextStyle(color: AppTheme.primaryGreen),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Preview da imagem
            if (_imageFile != null && !kIsWeb) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(_imageFile!.path),
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Botões de captura
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isAnalyzing
                        ? null
                        : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Câmera'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryGreen,
                      side: const BorderSide(color: AppTheme.primaryGreen),
                      minimumSize: const Size(0, 50),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isAnalyzing
                        ? null
                        : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Galeria'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 50),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Analisando
            if (_isAnalyzing)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Lendo a receita...',
                      style: TextStyle(color: AppTheme.textGrey)),
                  SizedBox(height: 24),
                ],
              ),

            // Erro
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange.shade700),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_errorMessage!,
                          style: TextStyle(color: Colors.orange.shade700)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Medicamentos encontrados
            if (_medicines.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Medicamentos identificados',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark),
                  ),
                  TextButton.icon(
                    onPressed: _addManual,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Adicionar'),
                  ),
                ],
              ),
              const Text(
                'Confirme os que deseja buscar:',
                style: TextStyle(color: AppTheme.textGrey),
              ),
              const SizedBox(height: 10),

              ..._medicines.asMap().entries.map((entry) {
                final med = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: CheckboxListTile(
                    value: med.confirmed,
                    onChanged: (v) => setState(
                        () => _medicines[entry.key].confirmed = v ?? true),
                    title: Text(med.name,
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                    secondary: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          backgroundColor:
                              AppTheme.primaryGreen.withValues(alpha: 0.1),
                          child: const Icon(Icons.medication,
                              color: AppTheme.primaryGreen, size: 20),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red, size: 18),
                          onPressed: () => setState(
                              () => _medicines.removeAt(entry.key)),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 12),

              // Aviso médico
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Confirme os medicamentos com seu médico antes de comprar.',
                        style: TextStyle(color: Colors.blue, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: _medicines.any((m) => m.confirmed)
                    ? _searchInPharmacies
                    : null,
                icon: const Icon(Icons.local_pharmacy_outlined),
                label: const Text('Buscar nas farmácias'),
              ),
            ],

            // Adicionar manualmente quando não encontrou nada
            if (_medicines.isEmpty && !_isAnalyzing && _imageFile != null) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _addManual,
                icon: const Icon(Icons.add),
                label: const Text('Adicionar medicamento manualmente'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryGreen,
                  side: const BorderSide(color: AppTheme.primaryGreen),
                  minimumSize: const Size(0, 50),
                ),
              ),
            ],

            // Texto bruto lido (debug/fallback)
            if (_rawText.isNotEmpty && _medicines.isEmpty) ...[
              const SizedBox(height: 16),
              ExpansionTile(
                title: const Text('Texto lido da receita',
                    style: TextStyle(color: AppTheme.textGrey, fontSize: 13)),
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_rawText,
                        style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Medicine {
  String name;
  bool   confirmed;
  _Medicine({required this.name, this.confirmed = true});
}
