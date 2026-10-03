import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _autenticado = false;
  bool _cargando = true;
  String? _correo;

  bool get autenticado => _autenticado;
  bool get cargando => _cargando;
  String? get correo => _correo;

  Future<void> verificarSesion() async {
    _cargando = true;
    notifyListeners();

    try {
      final token = await ApiService.obtenerToken();

      if (token == null || token.isEmpty) {
        _autenticado = false;
        _correo = null;
      } else {
        final datos = _decodificarToken(token);

        if (datos == null || _tokenVencido(datos)) {
          await ApiService.cerrarSesion();
          _autenticado = false;
          _correo = null;
        } else {
          _correo = datos['correo'];
          _autenticado = true;
        }
      }
    } catch (_) {
      _autenticado = false;
      _correo = null;
    }

    _cargando = false;
    notifyListeners();
  }

  Future<void> iniciarSesion(String correo, String password) async {
    await ApiService.login(correo, password);

    final token = await ApiService.obtenerToken();

    if (token != null) {
      final datos = _decodificarToken(token);

      _correo = datos?['correo'] ?? correo;
      _autenticado = true;
      notifyListeners();
    }
  }

  Future<void> cerrarSesion() async {
    await ApiService.cerrarSesion();

    _autenticado = false;
    _correo = null;

    notifyListeners();
  }

  Map<String, dynamic>? _decodificarToken(String token) {
    try {
      final partes = token.split('.');

      if (partes.length != 3) {
        return null;
      }

      final payloadNormalizado = base64Url.normalize(partes[1]);
      final payloadDecodificado =
          utf8.decode(base64Url.decode(payloadNormalizado));

      return jsonDecode(payloadDecodificado) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  bool _tokenVencido(Map<String, dynamic> datos) {
    final exp = datos['exp'];

    if (exp == null) {
      return false;
    }

    final fechaExpiracion =
        DateTime.fromMillisecondsSinceEpoch(exp * 1000);

    return DateTime.now().isAfter(fechaExpiracion);
  }
}