import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../models/nota.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:3000';

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<String?> obtenerToken() async {
    return _storage.read(key: 'token');
  }

  static Future<void> guardarToken(String token) async {
    await _storage.write(key: 'token', value: token);
  }

  static Future<void> cerrarSesion() async {
    await _storage.delete(key: 'token');
  }

  static Future<void> registrar(
    String correo,
    String password,
  ) async {
    final respuesta = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'correo': correo,
        'password': password,
      }),
    );

    final datos = jsonDecode(respuesta.body);

    if (respuesta.statusCode != 201) {
      throw Exception(datos['mensaje'] ?? 'Error al registrar usuario');
    }
  }

  static Future<void> login(
    String correo,
    String password,
  ) async {
    final respuesta = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'correo': correo,
        'password': password,
      }),
    );

    final datos = jsonDecode(respuesta.body);

    if (respuesta.statusCode != 200) {
      throw Exception(datos['mensaje'] ?? 'Error al iniciar sesión');
    }

    await guardarToken(datos['token']);
  }

  static Future<Map<String, String>> _headers() async {
    final token = await obtenerToken();

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<List<Nota>> obtenerNotas() async {
    final respuesta = await http.get(
      Uri.parse('$baseUrl/notas'),
      headers: await _headers(),
    );

    if (respuesta.statusCode != 200) {
      throw Exception('No fue posible consultar las notas');
    }

    final List<dynamic> datos = jsonDecode(respuesta.body);

    return datos
        .map((json) => Nota.fromApi(json))
        .toList();
  }

  static Future<Nota> crearNota(Nota nota) async {
    final respuesta = await http.post(
      Uri.parse('$baseUrl/notas'),
      headers: await _headers(),
      body: jsonEncode({
        'titulo': nota.titulo,
        'contenido': nota.contenido,
      }),
    );

    if (respuesta.statusCode != 201) {
      throw Exception('No fue posible crear la nota');
    }

    return Nota.fromApi(jsonDecode(respuesta.body));
  }

  static Future<Nota> actualizarNota(Nota nota) async {
    final respuesta = await http.put(
      Uri.parse('$baseUrl/notas/${nota.serverId}'),
      headers: await _headers(),
      body: jsonEncode({
        'titulo': nota.titulo,
        'contenido': nota.contenido,
      }),
    );

    if (respuesta.statusCode != 200) {
      throw Exception('No fue posible actualizar la nota');
    }

    return Nota.fromApi(jsonDecode(respuesta.body));
  }

  static Future<void> eliminarNota(int serverId) async {
    final respuesta = await http.delete(
      Uri.parse('$baseUrl/notas/$serverId'),
      headers: await _headers(),
    );

    if (respuesta.statusCode != 200) {
      throw Exception('No fue posible eliminar la nota');
    }
  }
}