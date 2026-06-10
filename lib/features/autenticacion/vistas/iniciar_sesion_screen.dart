import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auxiliomecanico_movil/features/autenticacion/estado/autenticacion_proveedor.dart';
import 'package:auxiliomecanico_movil/compartidos/widgets/campo_texto_personalizado.dart';
import 'package:auxiliomecanico_movil/features/autenticacion/vistas/registro_cliente_screen.dart';

/// Pantalla de Login
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (success) {
        // Navegar explícitamente al perfil para evitar depender solo del rebuild
        debugPrint('✅ Login exitoso, navegando a /perfil...');
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/perfil');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Error en login'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        constraints: const BoxConstraints.expand(),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade400,
              Colors.blue.shade900,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  // Logo/Título
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.build,
                      size: 60,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Título
                  Text(
                    'Auxilio Mecánico',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  // Subtítulo
                  Text(
                    'Sistema de Gestión',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  const SizedBox(height: 50),
                  // Campo Usuario
                  CustomTextField(
                    controller: _usernameController,
                    label: 'Usuario',
                    hint: 'Ingresa tu usuario',
                    prefixIcon: Icons.person,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'El usuario es requerido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Campo Contraseña
                  CustomTextField(
                    controller: _passwordController,
                    label: 'Contraseña',
                    hint: 'Ingresa tu contraseña',
                    prefixIcon: Icons.lock,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'La contraseña es requerida';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  // Botón Login
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Iniciar Sesión',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterClientScreen()),
                      );
                    },
                    child: const Text(
                      'Registrarse como cliente',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Mensaje de error ampliado
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, _) {
                      if (authProvider.error != null) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red),
                          ),
                          child: Text(
                            authProvider.error!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 30),
                  // Demo container removed
                  const SizedBox.shrink(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
