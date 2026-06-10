import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:auxiliomecanico_movil/features/autenticacion/estado/autenticacion_proveedor.dart';
import 'package:auxiliomecanico_movil/features/incidentes/servicios/incidente_service.dart';
import 'package:auxiliomecanico_movil/core/constantes/constantes_aplicacion.dart';

class AgregarEvidenciaScreen extends StatefulWidget {
  const AgregarEvidenciaScreen({super.key});

  @override
  State<AgregarEvidenciaScreen> createState() => _AgregarEvidenciaScreenState();
}

class _AgregarEvidenciaScreenState extends State<AgregarEvidenciaScreen> {
  String? _incidenteId;
  String _tipo = 'foto';
  PlatformFile? _file;
  final _textoCtrl = TextEditingController();
  bool _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _incidenteId = args != null ? args['incidente_id']?.toString() : null;
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(allowMultiple: false);
    if (result != null && result.files.isNotEmpty) {
      setState(() => _file = result.files.first);
    }
  }

  Future<void> _submit() async {
    if (_incidenteId == null) return;
    setState(() => _loading = true);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final svc = IncidenteService(token: token);
    try {
      if (_file != null) {
        await svc.subirEvidenciaArchivo(
          _incidenteId!,
          _file!,
          tipo: _tipo,
          texto: _textoCtrl.text.trim(),
        );
      } else {
        await svc.agregarEvidenciaTexto(
          _incidenteId!,
          tipo: _tipo,
          texto: _textoCtrl.text.trim(),
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Evidencia subida')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar evidencia')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_incidenteId == null) const Text('Incidente inválido'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _tipo,
              items: const [
                DropdownMenuItem(value: 'foto', child: Text('Foto')),
                DropdownMenuItem(value: 'audio', child: Text('Audio')),
                DropdownMenuItem(value: 'texto', child: Text('Texto')),
              ],
              onChanged: (v) => setState(() => _tipo = v ?? 'foto'),
              decoration: const InputDecoration(labelText: 'Tipo'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.attach_file),
              label: Text(_file == null ? 'Seleccionar archivo' : _file!.name),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _textoCtrl,
              decoration: const InputDecoration(labelText: 'Texto (opcional)'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Subir evidencia'),
            ),
          ],
        ),
      ),
    );
  }
}
