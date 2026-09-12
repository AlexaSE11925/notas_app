import '../models/nota.dart';
import 'api_service.dart';
import 'database_service.dart';

class SyncService {
  static final DatabaseService _db = DatabaseService.instance;

  static Future<void> sincronizar() async {
    try {
      final pendientes = await _db.obtenerPendientes();

      for (final nota in pendientes) {
        if (nota.estadoSync == 'create') {
          final notaServidor = await ApiService.crearNota(nota);

          final actualizada = Nota(
            localId: nota.localId,
            serverId: notaServidor.serverId,
            titulo: notaServidor.titulo,
            contenido: notaServidor.contenido,
            fecha: notaServidor.fecha,
            estadoSync: 'synced',
          );

          await _db.actualizarNota(actualizada);
        }

        if (nota.estadoSync == 'update') {
          if (nota.serverId != null) {
            final notaServidor = await ApiService.actualizarNota(nota);

            final actualizada = Nota(
              localId: nota.localId,
              serverId: notaServidor.serverId,
              titulo: notaServidor.titulo,
              contenido: notaServidor.contenido,
              fecha: notaServidor.fecha,
              estadoSync: 'synced',
            );

            await _db.actualizarNota(actualizada);
          }
        }

        if (nota.estadoSync == 'delete') {
          if (nota.serverId != null) {
            await ApiService.eliminarNota(nota.serverId!);
          }

          if (nota.localId != null) {
            await _db.eliminarLocal(nota.localId!);
          }
        }
      }

      final notasServidor = await ApiService.obtenerNotas();

      for (final nota in notasServidor) {
        await _db.guardarNotaServidor(nota);
      }
    } catch (_) {
      // Si no hay Internet, las notas quedan almacenadas
      // localmente para sincronizar después.
    }
  }
}