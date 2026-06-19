import 'package:flutter/material.dart';
import 'package:auxiliomecanico_movil/compartidos/widgets/cajon_aplicacion.dart';
import 'package:provider/provider.dart';
import 'package:auxiliomecanico_movil/features/autenticacion/estado/autenticacion_proveedor.dart';
import 'package:auxiliomecanico_movil/features/vehiculos/servicios/vehiculo_service.dart';
import 'package:auxiliomecanico_movil/features/incidentes/servicios/incidente_service.dart';
import 'package:auxiliomecanico_movil/features/vehiculos/modelos/vehiculo.dart';
import 'package:geolocator/geolocator.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

class IncidentReportScreen extends StatelessWidget {
  const IncidentReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _IncidentReportForm();
  }
}

class _IncidentReportForm extends StatefulWidget {
  const _IncidentReportForm({super.key});

  @override
  State<_IncidentReportForm> createState() => _IncidentReportFormState();
}

class _IncidentReportFormState extends State<_IncidentReportForm> {
  List<Vehicle> _vehicles = [];
  Vehicle? _selectedVehicle;
  String? _selectedTipo; // 'averia', 'accidente', 'otro'
  final _descCtrl = TextEditingController();
  PlatformFile? _pickedFile;
  String? _pickedTipo; // 'foto' or 'audio'
  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  String _baseDescriptionBeforeDictation = '';
  final _evidenceTextCtrl = TextEditingController();

  bool _loading = true;
  double? _latitud;
  double? _longitud;
  final int _prioridad = 1;

  String get _locationSummary {
    if (_latitud == null || _longitud == null) {
      return 'Todavía no has marcado la ubicación de la solicitud.';
    }
    return '${_latitud!.toStringAsFixed(6)}, ${_longitud!.toStringAsFixed(6)}';
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    try {
      final list = await VehiculoService(token: token).getMisVehiculos();
      if (!mounted) return;
      setState(() {
        _vehicles = list;
        _loading = false;
        if (_vehicles.isNotEmpty) {
          _selectedVehicle = _vehicles.firstWhere((v) => v.principal, orElse: () => _vehicles.first);
        }
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (!mounted) return;
      _showSnack('Error cargando vehículos: $e');
    }
  }

  Future<void> _submit() async {
    if (_selectedTipo == null || _selectedTipo!.isEmpty) {
      _showSnack('Selecciona el tipo de incidente');
      return;
    }
    // Validar que se haya seleccionado ubicación
    if (_latitud == null || _longitud == null) {
      _showSnack('Selecciona una ubicación en el mapa');
      return;
    }
    final finalVehicle = _selectedVehicle ?? (_vehicles.isNotEmpty ? _vehicles.firstWhere((v) => v.principal, orElse: () => _vehicles.first) : null);
    final payload = {
      'vehiculo_id': finalVehicle?.id,
      'tipo': _selectedTipo,
      'descripcion': _descCtrl.text.trim(),
      'prioridad': _prioridad,
      'latitud': _latitud,
      'longitud': _longitud,
    };
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    try {
      final svc = IncidenteService(token: token);
      final res = await svc.crearIncidente(payload);
      final incidenteId = res['id']?.toString();

      // If there is a selected file or evidence text, upload it
      if (incidenteId != null) {
        if (_pickedFile != null) {
          // determine tipo (fallback to foto)
          final tipoToSend = _pickedTipo ?? 'foto';
          await svc.subirEvidenciaArchivo(
            incidenteId,
            _pickedFile!,
            tipo: tipoToSend,
            texto: _evidenceTextCtrl.text.trim(),
          );
        } else if (_evidenceTextCtrl.text.trim().isNotEmpty) {
          await svc.agregarEvidenciaTexto(
            incidenteId,
            tipo: 'texto',
            texto: _evidenceTextCtrl.text.trim(),
          );
        }
      }

      if (!mounted) return;
      _showSnack('Solicitud de auxilio enviada');
      if (!mounted) return;
      Navigator.pushNamed(context, '/historial-incidentes');
    } catch (e) {
      if (!mounted) return;
      _showSnack('Error enviando la solicitud: $e');
    }
  }

  Future<void> _pickImage() async {
    final res = await FilePicker.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
    );
    if (res != null && res.files.isNotEmpty) {
      setState(() {
        _pickedFile = res.files.first;
        _pickedTipo = 'foto';
      });
    }
  }

  // Note: recording-as-file removed; only dictation via speech_to_text is used.

  Future<void> _toggleDictation() async {
    if (_isListening) {
      _speechToText.stop();
      setState(() => _isListening = false);
      return;
    }

    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (!mounted) return;
      _showSnack('Permiso de micrófono denegado');
      return;
    }

    final available = await _speechToText.initialize(
      onStatus: (status) {
        if (status == 'notListening' || status == 'done') {
          if (mounted) setState(() => _isListening = false);
        }
      },
    );
    if (!available) {
      if (!mounted) return;
      _showSnack('Reconocimiento de voz no disponible');
      return;
    }

    // Save base text to avoid duplicates from partial results
    _baseDescriptionBeforeDictation = _descCtrl.text;

    setState(() => _isListening = true);
    _speechToText.listen(
      onResult: (result) {
        final recognized = result.recognizedWords ?? '';
        final base = _baseDescriptionBeforeDictation.trim();
        final combined = base.isEmpty
            ? recognized
            : '$base ${recognized.trim()}';
        setState(() {
          _descCtrl.text = combined;
          _descCtrl.selection = TextSelection.fromPosition(
            TextPosition(offset: _descCtrl.text.length),
          );
        });

        if (result.finalResult) {
          _speechToText.stop();
          if (mounted) setState(() => _isListening = false);
        }
      },
      listenMode: ListenMode.dictation,
      partialResults: true,
      localeId: 'es_BO',
    );
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _evidenceTextCtrl.dispose();
    try {
      _speechToText.stop();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solicitud de Auxilio')),
      drawer: const AppDrawer(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // HEADER CARD
                  Card(
                    elevation: 0,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reportar nueva solicitud de auxilio',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Selecciona tipo, ubicación y adjunta evidencias',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // FORM SECTION
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. TIPO DE INCIDENTE (requerido)
                          TextFormField(
                            initialValue: _selectedTipo ?? '',
                            onChanged: (v) => setState(() => _selectedTipo = v.isEmpty ? null : v),
                            decoration: const InputDecoration(
                              labelText: 'Tipo de incidente',
                              hintText: 'Ej: Avería, Accidente, Pinchazo...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 2. VEHÍCULO (opcional)
                          DropdownButtonFormField<Vehicle>(
                            value: _selectedVehicle,
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('Selecciona vehículo'),
                              ),
                              ..._vehicles.map(
                                (v) => DropdownMenuItem(
                                  value: v,
                                  child: Text('${v.marca ?? ''} ${v.modelo ?? ''} - ${v.placa ?? ''}'),
                                ),
                              ),
                            ],
                            onChanged: (v) => setState(() => _selectedVehicle = v),
                            decoration: const InputDecoration(labelText: 'Vehículo'),
                          ),
                          const SizedBox(height: 16),

                          // 3. DESCRIPCIÓN
                          TextFormField(
                            controller: _descCtrl,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: 'Descripción',
                              hintText: 'Descripción del problema',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              SizedBox(
                                child: ElevatedButton.icon(
                                  onPressed: _toggleDictation,
                                  icon: Icon(_isListening ? Icons.stop : Icons.mic),
                                  label: Text(_isListening ? 'Escuchando...' : 'Dictar'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // UBICACIÓN SECTION
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ubicación',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Ubicación seleccionada: $_locationSummary',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                final result = await Navigator.pushNamed(
                                  context,
                                  '/seleccionar-ubicacion',
                                );
                                if (result is Map) {
                                  setState(() {
                                    _latitud = (result['latitud'] as num?)?.toDouble();
                                    _longitud = (result['longitud'] as num?)?.toDouble();
                                  });
                                }
                              },
                              child: const Text('Elegir ubicación en mapa'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                bool serviceEnabled =
                                    await Geolocator.isLocationServiceEnabled();
                                if (!mounted) return;
                                if (!serviceEnabled) {
                                  _showSnack('Activa el servicio de ubicación');
                                  return;
                                }
                                LocationPermission permission =
                                    await Geolocator.checkPermission();
                                if (!mounted) return;
                                if (permission == LocationPermission.denied) {
                                  permission = await Geolocator.requestPermission();
                                  if (!mounted) return;
                                }
                                if (permission == LocationPermission.denied ||
                                    permission == LocationPermission.deniedForever) {
                                  _showSnack('Permiso de ubicación denegado');
                                  return;
                                }
                                try {
                                  final pos = await Geolocator.getCurrentPosition();
                                  if (!mounted) return;
                                  setState(() {
                                    _latitud = pos.latitude;
                                    _longitud = pos.longitude;
                                  });
                                } catch (e) {
                                  if (!mounted) return;
                                  _showSnack('Error obteniendo ubicación: $e');
                                }
                              },
                              icon: const Icon(Icons.my_location),
                              label: const Text('Usar mi ubicación'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // EVIDENCIAS SECTION
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Evidencias (fotos)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _pickImage,
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Adjuntar foto'),
                            ),
                          ),
                          if (_pickedFile != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${_pickedFile!.name} (${_pickedTipo ?? 'archivo'})',
                                      style: const TextStyle(fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _evidenceTextCtrl,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Texto de evidencia (opcional)',
                              hintText: 'Describe lo que sucedió...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ACTION BUTTONS
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _submit,
                          child: const Text('Enviar solicitud'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedTipo = null;
                              _selectedVehicle = null;
                              _descCtrl.clear();
                              _evidenceTextCtrl.clear();
                              _pickedFile = null;
                              _latitud = null;
                              _longitud = null;
                            });
                          },
                          child: const Text('Cancelar'),
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
