import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../models/nota.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';
import 'login_screen.dart';
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

  StreamSubscription<List<ConnectivityResult>>? conexionSubscription;

  @override
  void initState() {
    super.initState();

    cargarNotas();

    conexionSubscription =
        Connectivity().onConnectivityChanged.listen((resultados) async {
      final tieneConexion =
          !resultados.contains(ConnectivityResult.none);

      if (tieneConexion) {
        await SyncService.sincronizar();
        await cargarNotas();
      }
    });
  }

  @override
  void dispose() {
    conexionSubscription?.cancel();
    super.dispose();
  }

  Future<void> cargarNotas() async {
    setState(() => cargando = true);

    await SyncService.sincronizar();

    final datos = await db.obtenerNotas();

    if (!mounted) return;

    setState(() {
      notas = datos;
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

  Future<void> cerrarSesion() async {
    await ApiService.cerrarSesion();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
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
      body: cargando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: cargarNotas,
              child: notas.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 180),
                        Icon(
                          Icons.note_alt_outlined,
                          size: 80,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 15),
                        Center(
                          child: Text(
                            'Todavía no tienes notas',
                            style: TextStyle(
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: notas.length,
                      itemBuilder: (context, index) {
                        final nota = notas[index];

                        return Card(
                          child: ListTile(
                            title: Text(
                              nota.titulo,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 5),
                                Text(nota.contenido),
                                const SizedBox(height: 6),
                                Text(
                                  nota.estadoSync == 'synced'
                                      ? 'Sincronizada'
                                      : 'Pendiente de sincronización',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        nota.estadoSync == 'synced'
                                            ? Colors.green
                                            : Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () => abrirFormulario(nota),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                              onPressed: () => eliminar(nota),
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => abrirFormulario(),
        child: const Icon(Icons.add),
      ),
    );
  }
}