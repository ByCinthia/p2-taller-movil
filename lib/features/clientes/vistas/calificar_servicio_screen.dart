import 'package:flutter/material.dart';

class CalificarServicioScreen extends StatefulWidget {
  final String incidenteId;

  const CalificarServicioScreen({super.key, required this.incidenteId});

  @override
  State<CalificarServicioScreen> createState() => _CalificarServicioScreenState();
}

class _CalificarServicioScreenState extends State<CalificarServicioScreen> {
  int _puntaje = 5;
  final _comentarioController = TextEditingController();
  bool _enviando = false;

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  Future<void> _enviarCalificacion() async {
    setState(() => _enviando = true);
    // Simular el envío del servicio de calificaciones ya que no hay campos persistentes en la base de datos
    await Future.delayed(const Duration(milliseconds: 600));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '¡Gracias por tu calificación! (Simulación de prototipo: No se puede persistir calificación sin campo disponible en BD.)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Widget _buildStar(int index) {
    return IconButton(
      iconSize: 48,
      icon: Icon(
        index <= _puntaje ? Icons.star : Icons.star_border,
        color: Colors.amber,
      ),
      onPressed: _enviando
          ? null
          : () {
              setState(() {
                _puntaje = index;
              });
            },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Califica tu servicio'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Icon(
              Icons.stars_rounded,
              size: 80,
              color: Colors.amber,
            ),
            const SizedBox(height: 24),
            Text(
              '¿Cómo calificarías la atención recibida?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tu opinión ayuda a mejorar la calidad del servicio de nuestros talleres afiliados.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStar(1),
                _buildStar(2),
                _buildStar(3),
                _buildStar(4),
                _buildStar(5),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '$_puntaje de 5 estrellas',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _comentarioController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Deja un comentario (opcional)',
                hintText: '¿Qué te pareció el servicio? Tu reseña...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              enabled: !_enviando,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _enviando ? null : _enviarCalificacion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _enviando
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Enviar calificación',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
