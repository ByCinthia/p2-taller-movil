import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:auxiliomecanico_movil/core/modelos/usuario.dart';
import 'package:auxiliomecanico_movil/core/conexion/cliente_api.dart';
import 'package:auxiliomecanico_movil/features/autenticacion/estado/autenticacion_proveedor.dart';

class ListaEmpleadosScreen extends StatefulWidget {
  const ListaEmpleadosScreen({super.key});

  @override
  State<ListaEmpleadosScreen> createState() => _ListaEmpleadosScreenState();
}

class _ListaEmpleadosScreenState extends State<ListaEmpleadosScreen> {
  Future<List<User>>? _empleadosFuture;

  @override
  void initState() {
    super.initState();
    _loadEmpleados();
  }

  void _loadEmpleados() {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null) {
      _empleadosFuture = ApiClient(token: token).empleado().getEmployees();
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _loadEmpleados();
    });
    await _empleadosFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Empleados'),
      ),
      body: FutureBuilder<List<User>>(
        future: _empleadosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error al cargar empleados:\n${snapshot.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refresh,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final empleados = snapshot.data ?? [];
          if (empleados.isEmpty) {
            return const Center(child: Text('No hay empleados registrados.'));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: empleados.length,
              itemBuilder: (context, index) {
                final emp = empleados[index];
                final initial = emp.fullName.isNotEmpty ? emp.fullName[0].toUpperCase() : '?';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(initial),
                    ),
                    title: Text(emp.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(emp.email.isNotEmpty ? emp.email : 'Sin email'),
                        const SizedBox(height: 4),
                        Text('Rol: ${emp.role.toUpperCase()}'),
                      ],
                    ),
                    trailing: Icon(
                      emp.isActive ? Icons.check_circle : Icons.cancel,
                      color: emp.isActive ? Colors.green : Colors.red,
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
