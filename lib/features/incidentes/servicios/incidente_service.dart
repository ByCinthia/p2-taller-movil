import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:auxiliomecanico_movil/core/constantes/constantes_aplicacion.dart';
import 'package:auxiliomecanico_movil/core/conexion/servicio_api.dart';

class IncidenteService {
  final ApiService _api;
  final String? _token;

  IncidenteService({String? token})
    : _api = ApiService(token: token),
      _token = token;

  Map<String, String> _buildHeaders({bool jsonContent = true}) {
    final headers = <String, String>{};
    if (jsonContent) headers['Content-Type'] = 'application/json';
    if (_token != null) headers['Authorization'] = 'Bearer $_token';
    return headers;
  }

  /// Servicio de alto nivel para manejar incidentes y evidencias usando ApiService
  Future<List<Map<String, dynamic>>> listarIncidentes() async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/api/incidentes/'),
      headers: _buildHeaders(),
    );
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List<dynamic>)
          .cast<Map<String, dynamic>>();
    }
    throw Exception('Error al listar incidentes: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> crearIncidente(
    Map<String, dynamic> payload,
  ) async {
    return _api.createIncidente(payload);
  }

  Future<Map<String, dynamic>> obtenerIncidente(String id) async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/api/incidentes/$id/'),
      headers: _buildHeaders(),
    );
    if (response.statusCode == 200)
      return jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 404) throw Exception('Incidente no encontrado');
    throw Exception('Error al obtener incidente: ${response.statusCode}');
  }

  Future<List<Map<String, dynamic>>> obtenerEvidencias(String id) async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/api/incidentes/$id/evidencias'),
      headers: _buildHeaders(),
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body is List) {
        return body.cast<Map<String, dynamic>>();
      } else if (body is Map && body['evidencias'] is List) {
        return (body['evidencias'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    }
    if (response.statusCode == 404) return [];
    throw Exception('Error al obtener evidencias: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> obtenerTracking(String id) async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/api/incidentes/$id/tracking'),
      headers: _buildHeaders(),
    );
    if (response.statusCode == 200)
      return jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception('Error al obtener tracking: ${response.statusCode}');
  }

  Future<void> actualizarEstado(String id, String estado) async {
    final response = await http.patch(
      Uri.parse('${AppConstants.baseUrl}/api/incidentes/$id/estado'),
      headers: _buildHeaders(),
      body: jsonEncode({'estado': estado}),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw Exception('Error al actualizar estado: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> agregarEvidenciaTexto(
    String id, {
    required String tipo,
    String? texto,
    String? url,
  }) async {
    final body = {'tipo': tipo};
    if (texto != null) body['texto'] = texto;
    if (url != null) body['url_archivo'] = url;
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/api/incidentes/$id/evidencias'),
      headers: _buildHeaders(),
      body: jsonEncode(body),
    );
    if (response.statusCode >= 200 && response.statusCode < 300)
      return jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception('Error al agregar evidencia: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> subirEvidenciaArchivo(
    String id,
    PlatformFile file, {
    String? tipo,
    String? texto,
  }) async {
    final uri = Uri.parse(
      '${AppConstants.baseUrl}/api/incidentes/$id/evidencias/upload',
    );
    final request = http.MultipartRequest('POST', uri);
    // headers
    request.headers.addAll(_buildHeaders(jsonContent: false));
    if (tipo != null) request.fields['tipo'] = tipo;
    if (texto != null) request.fields['texto'] = texto;

    final f = File(file.path!);
    request.files.add(
      await http.MultipartFile.fromPath('archivo', f.path, filename: file.name),
    );

    final streamed = await request.send();
    final resp = await http.Response.fromStream(streamed);
    if (resp.statusCode >= 200 && resp.statusCode < 300)
      return jsonDecode(resp.body) as Map<String, dynamic>;
    throw Exception('Error al subir evidencia archivo: ${resp.statusCode}');
  }

  Future<Map<String, dynamic>> subirEvidenciaArchivoPath(
    String id,
    String filePath, {
    String? tipo,
    String? texto,
  }) async {
    final uri = Uri.parse(
      '${AppConstants.baseUrl}/api/incidentes/$id/evidencias/upload',
    );
    final request = http.MultipartRequest('POST', uri);
    // headers
    request.headers.addAll(_buildHeaders(jsonContent: false));
    if (tipo != null) request.fields['tipo'] = tipo;
    if (texto != null) request.fields['texto'] = texto;

    final f = File(filePath);
    final filename = f.path.split(Platform.pathSeparator).last;
    request.files.add(
      await http.MultipartFile.fromPath('archivo', f.path, filename: filename),
    );

    final streamed = await request.send();
    final resp = await http.Response.fromStream(streamed);
    if (resp.statusCode >= 200 && resp.statusCode < 300)
      return jsonDecode(resp.body) as Map<String, dynamic>;
    throw Exception('Error al subir evidencia archivo: ${resp.statusCode}');
  }

  Future<List<Map<String, dynamic>>> listarTecnicosCercanos(
    double lat,
    double lon, {
    double radioKm = 5,
  }) async {
    final uri = Uri.parse(
      '${AppConstants.baseUrl}/api/incidentes/tecnicos/cercanos?latitud=$lat&longitud=$lon&radio_km=$radioKm',
    );
    final response = await http.get(uri, headers: _buildHeaders());
    if (response.statusCode == 200)
      return (jsonDecode(response.body) as List<dynamic>)
          .cast<Map<String, dynamic>>();
    throw Exception(
      'Error al listar técnicos cercanos: ${response.statusCode}',
    );
  }
}
