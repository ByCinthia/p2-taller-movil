import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:auxiliomecanico_movil/features/vehiculos/servicios/vehiculo_service.dart';
import 'package:auxiliomecanico_movil/features/autenticacion/estado/autenticacion_proveedor.dart';
import 'package:auxiliomecanico_movil/compartidos/widgets/campo_texto_personalizado.dart';

class VehicleRegisterScreen extends StatefulWidget {
  const VehicleRegisterScreen({super.key});

  @override
  State<VehicleRegisterScreen> createState() => _VehicleRegisterScreenState();
}

class _VehicleRegisterScreenState extends State<VehicleRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _plateController = TextEditingController();
  final _yearController = TextEditingController();
  bool _principal = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _plateController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final auth = context.read<AuthProvider>();
      final svc = VehiculoService(token: auth.token);
      await svc.registrarVehiculo({
        'marca': _brandController.text.trim(),
        'modelo': _modelController.text.trim(),
        'placa': _plateController.text.trim(),
        'anio': _yearController.text.trim().isEmpty
            ? null
            : int.tryParse(_yearController.text.trim()),
        'principal': _principal,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vehículo registrado')));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar vehículo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                controller: _brandController,
                label: 'Marca',
                hint: 'Ej. Toyota',
                prefixIcon: Icons.directions_car,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'La marca es requerida'
                    : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _modelController,
                label: 'Modelo',
                hint: 'Ej. Hilux',
                prefixIcon: Icons.car_rental,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'El modelo es requerido'
                    : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _plateController,
                label: 'Placa',
                hint: 'Ej. 1234ABC',
                prefixIcon: Icons.confirmation_number,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'La placa es requerida'
                    : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _yearController,
                label: 'Año',
                hint: 'Opcional',
                prefixIcon: Icons.calendar_today,
                keyboardType: TextInputType.number,
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return null;
                  final parsed = int.tryParse(text);
                  if (parsed == null) return 'Ingresa un año válido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Marcar como principal'),
                value: _principal,
                onChanged: (value) => setState(() => _principal = value),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('Guardar vehículo'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
