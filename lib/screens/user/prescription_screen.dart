import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../app/theme.dart';

// A chave é carregada via variável de ambiente ou string.fromEnvironment
// Para desenvolvimento local use: flutter run --dart-define=GEMINI_API_KEY=sua_chave
const _geminiApiKey = String.fromEnvironment(
  'GEMINI_API_KEY',
  defaultValue: '',
);

class PrescriptionScreen extends ConsumerStatefulWidget {
  const PrescriptionScreen({super.key});

  @override
  ConsumerState<PrescriptionScreen> createState() =>
      _PrescriptionScreenState();
}

class _PrescriptionScreenState extends ConsumerState<PrescriptionScreen> {
  Uint8List?           _imageBytes;
  bool                 _isAnalyzing = false;
  List<_Medicine>      _medicines   = [];
  String?              _errorMessage;

  final _picker = ImagePicker();

  // Seleciona imagem da câmera ou galeria
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source:  source,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      setState(() {
        _imageBytes    = bytes;
        _medicines     = [];
        _errorMessage  = null;
      });

      await _analyzeImage(bytes);
    } catch (e) {
      setState(() => _errorMessage = 'Erro ao acessar a câmera/galeria.');
    }
  }

  // Envia imagem para o Gemini e extrai medicamentos
  Future<void> _analyzeImage(Uint8List bytes) async {
    setState(() { _isAnalyzing = true; _errorMessage = null; });

    try {
      final model = GenerativeModel(
        model:  'gemini-1.5-flash',
        apiKey: _geminiApiKey,
      );

      final prompt = '''
Analise esta receita médica e extraia APENAS os nomes dos medicamentos prescritos.
Retorne uma lista simples, um medicamento por linha, apenas o nome comercial ou genérico.
Não inclua dosagens, quantidades ou instruções — apenas os nomes dos medicamentos.
Se não encontrar medicamentos, retorne apenas: NENHUM
Exemplo de resposta esperada:
Amoxicilina
Ibuprofeno
Paracetamol
''';

      final response = await model.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', bytes),
        ]),
      ]);

      final text = response.text ?? '';

      if (text.trim().toUpperCase().contains('NENHUM') || text.trim().isEmpty) {
        setState(() {
          _medicines    = [];
          _errorMessage = 'Nenhum medicamento identificado. Tente uma foto mais nítida.';
          _isAnalyzing  = false;
        });
        return;
      }

      // Converte a resposta em lista de medicamentos
      final lines = text
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty && !l.startsWith('*') && !l.startsWith('-'))
          .map((l) => l.replaceAll(RegExp(r'^[\d\.\-\*]+\s*'), '').trim())
          .where((l) => l.isNotEmpty)
          .toList();

      setState(() {
        _medicines   = lines.map((name) => _Medicine(name: name)).toList();
        _isAnalyzing = false;
      });

    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao analisar a imagem. Verifique sua conexão.';
        _isAnalyzing  = false;
      });
    }
  }

  // Busca os medicamentos confirmados nas farmácias
  void _searchInPharmacies() {
    final confirmed = _medicines.where((m) => m.confirmed).toList();
    if (confirmed.isEmpty) return;

    final names = confirmed.map((m) => m.name).join(', ');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Buscando: $names'),
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
                      'Fotografe ou envie uma imagem da sua receita. O app vai identificar os medicamentos automaticamente.',
                      style: TextStyle(color: AppTheme.primaryGreen),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Preview da imagem
            if (_imageBytes != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(
                  _imageBytes!,
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
            const SizedBox(height: 24),

            // Analisando
            if (_isAnalyzing)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Analisando a receita com IA...',
                      style: TextStyle(color: AppTheme.textGrey)),
                  SizedBox(height: 24),
                ],
              ),

            // Erro
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber,
                        color: Colors.orange.shade700),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_errorMessage!,
                          style:
                              TextStyle(color: Colors.orange.shade700)),
                    ),
                  ],
                ),
              ),

            // Medicamentos encontrados
            if (_medicines.isNotEmpty) ...[
              const Text(
                'Medicamentos identificados',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark),
              ),
              const SizedBox(height: 4),
              const Text(
                'Confirme os medicamentos que deseja buscar:',
                style: TextStyle(color: AppTheme.textGrey),
              ),
              const SizedBox(height: 12),

              ..._medicines.asMap().entries.map((entry) {
                final med = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: CheckboxListTile(
                    value: med.confirmed,
                    onChanged: (v) => setState(
                        () => _medicines[entry.key].confirmed = v ?? true),
                    title: Text(med.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w500)),
                    secondary: CircleAvatar(
                      backgroundColor:
                          AppTheme.primaryGreen.withValues(alpha: 0.1),
                      child: const Icon(Icons.medication,
                          color: AppTheme.primaryGreen, size: 20),
                    ),
                    activeColor: AppTheme.primaryGreen,
                    checkColor: Colors.white,
                  ),
                );
              }),

              const SizedBox(height: 16),

              // Aviso médico
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.blue, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sempre confirme os medicamentos com seu médico ou farmacêutico antes de comprar.',
                        style:
                            TextStyle(color: Colors.blue, fontSize: 12),
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
