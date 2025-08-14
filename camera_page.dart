import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ocr_service.dart';
import 'classifier_service.dart';
import '../nota/models.dart';
import '../comparacao/resultado_page.dart';

final capturaProvider = StateProvider<CapturaDetectada?>((ref)=>null);

class CameraPage extends ConsumerStatefulWidget {
  const CameraPage({super.key});
  @override
  ConsumerState<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends ConsumerState<CameraPage> {
  final _picker = ImagePicker();
  final _ocr = OcrService();
  final _classifier = ClassifierService();

  File? _image;
  String _ocrText = "";
  String _categoria = '-';

  @override
  void initState() {
    super.initState();
    _classifier.load();
  }

  @override
  void dispose() {
    _classifier.dispose();
    _ocr.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    final x = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (x == null) return;
    final file = File(x.path);
    setState(()=> _image = file);

    final text = await _ocr.extractText(file);
    setState(()=> _ocrText = text);

    final cat = await _classifier.classify(file, ocrText: text);
    setState(()=> _categoria = cat);

    final vol = _ocr.parseVolumeLitros(text);
    final dim = _ocr.parseDimensoesMm(text);
    final bit = _ocr.parseBitolaMm(text);
    final cor = _ocr.parseCor(text);

    final cap = CapturaDetectada(
      categoria: cat,
      volumeLitros: vol,
      dimensoesMm: dim,
      bitolaMm: bit,
      cor: cor,
      textoOcrBruto: text,
    );
    ref.read(capturaProvider.notifier).state = cap;
  }

  @override
  Widget build(BuildContext context) {
    final cap = ref.watch(capturaProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Capturar Foto')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              onPressed: _capture,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Tirar Foto'),
            ),
            const SizedBox(height: 12),
            if (_image != null) Image.file(_image!, height: 200),
            const SizedBox(height: 12),
            Text('Categoria: $_categoria'),
            const SizedBox(height: 8),
            const Text('OCR (rótulo/etiqueta):'),
            Expanded(child: SingleChildScrollView(child: Text(_ocrText.isEmpty ? '-' : _ocrText))),
          ],
        ),
      ),
      floatingActionButton: cap == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ResultadoPage()));
              },
              icon: const Icon(Icons.rule),
              label: const Text('Comparar com Nota'),
            ),
    );
  }
}
