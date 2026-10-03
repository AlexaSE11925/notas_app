import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/nota.dart';
import '../providers/auth_provider.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';
import '../services/sync_service.dart';
import 'nota_form_screen.dart';

class NotasScreen extends StatefulWidget {
  const NotasScreen({super.key});

  @override
  State<NotasScreen> createState() => _NotasScreenState();
}

class _NotasScreenState extends State<NotasScreen> {
  final DatabaseService db = DatabaseService.instance;

  List<Nota> notas = [];
  bool cargando = true;

  bool obteniendoUbicacion = false;
  double? latitud;
  double? longitud;

  StreamSubscription<List<ConnectivityResult>>? subscription;

  @override
  void initState() {
    super.initState();

    cargarNotas();

    subscription = Connectivity().onConnectivityChanged.listen(
      (resultados) async {
        final tieneConexion =
            !resultados.contains(ConnectivityResult.none);

        if (tieneConexion) {
          await SyncService.sincronizar();
          await cargarNotas();
        }
      },
    );
  }

  Future<void> cargarNotas() async {
    if (!mounted) return;

    setState(() {
      cargando = true;
    });

    await SyncService.sincronizar();

    final resultado = await db.obtenerNotas();

    if (!mounted) return;

    setState(() {
      notas = resultado;
      cargando = false;
    });
  }

  Future<void> abrirFormulario([Nota? nota]) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NotaFormScreen(
          nota: nota,
        ),
      ),
    );

    if (resultado == true) {
      await cargarNotas();
    }
  }

  Future<void> eliminar(Nota nota) async {
    await db.marcarEliminada(nota);

    await SyncService.sincronizar();

    await cargarNotas();
  }

  Future<void> obtenerUbicacion() async {
    setState(() {
      obteniendoUbicacion = true;
    });

    try {
      final posicion = await LocationService.obtenerUbicacion();

      if (!mounted) return;

      setState(() {
        latitud = posicion.latitude;
        longitud = posicion.longitude;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          obteniendoUbicacion = false;
        });
      }
    }
  }

  Future<void> cerrarSesion() async {
    await DatabaseService.instance.borrarTodasLasNotas();

    if (!mounted) return;

    setState(() {
      latitud = null;
      longitud = null;
    });

    await context.read<AuthProvider>().cerrarSesion();
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis notas'),
        actions: [
          IconButton(
            tooltip: 'Sincronizar',
            onPressed: cargarNotas,
            icon: const Icon(Icons.sync),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: cerrarSesion,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sesión activa',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  auth.correo ?? 'Usuario autenticado',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Estas son tus notas guardadas.',
                ),
              ],
            ),
          ),

          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey.shade300,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.location_on),
                    SizedBox(width: 8),
                    Text(
                      'Ubicación del dispositivo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (latitud != null && longitud != null) ...[
                  Text(
                    'Latitud: ${latitud!.toStringAsFixed(6)}',
                  ),
                  Text(
                    'Longitud: ${longitud!.toStringAsFixed(6)}',
                  ),
                  const SizedBox(height: 10),
                ] else
                  const Text(
                    'La ubicación solo se consulta cuando tú la solicitas.',
                  ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed:
                        obteniendoUbicacion ? null : obtenerUbicacion,
                    icon: obteniendoUbicacion
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.my_location),
                    label: Text(
                      obteniendoUbicacion
                          ? 'Obteniendo ubicación...'
                          : 'Obtener mi ubicación',
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: cargando
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : notas.isEmpty
                    ? const Center(
                        child: Text(
                          'No tienes notas registradas',
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: cargarNotas,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: notas.length,
                          itemBuilder: (context, index) {
                            final nota = notas[index];

                            final sincronizada =
                                nota.estadoSync == 'synced';

                            return Card(
                              margin: const EdgeInsets.only(
                                bottom: 12,
                              ),
                              child: ListTile(
                                onTap: () => abrirFormulario(nota),
                                title: Text(
                                  nota.titulo,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 6),
                                    Text(nota.contenido),
                                    const SizedBox(height: 6),
                                    Text(
                                      sincronizada
                                          ? 'Sincronizada'
                                          : 'Pendiente de sincronización',
                                      style: TextStyle(
                                        color: sincronizada
                                            ? Colors.green
                                            : Colors.orange,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  tooltip: 'Eliminar nota',
                                  onPressed: () => eliminar(nota),
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => abrirFormulario(),
        child: const Icon(Icons.add),
      ),
    );
  }
}