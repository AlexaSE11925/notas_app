import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<Position> obtenerUbicacion() async {
    final servicioActivo = await Geolocator.isLocationServiceEnabled();

    if (!servicioActivo) {
      throw Exception(
        'La ubicación del dispositivo está desactivada.',
      );
    }

    LocationPermission permiso = await Geolocator.checkPermission();

    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }

    if (permiso == LocationPermission.denied) {
      throw Exception(
        'No se concedió permiso para acceder a la ubicación.',
      );
    }

    if (permiso == LocationPermission.deniedForever) {
      throw Exception(
        'El permiso de ubicación está bloqueado permanentemente. '
        'Debes habilitarlo desde la configuración del dispositivo.',
      );
    }

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
    );

    return Geolocator.getCurrentPosition(
      locationSettings: locationSettings,
    );
  }
}