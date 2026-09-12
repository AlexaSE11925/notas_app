import 'package:flutter/material.dart';

import '../models/nota.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';

class NotaFormScreen extends StatefulWidget {
  final Nota? nota;

  const NotaFormScreen({
    super.key,
    this.nota,
  });

  @override
  State<NotaFormScreen> createState() => _NotaFormScreenState();
}

class _NotaFormScreenState extends State<NotaFormScreen> {
  final DatabaseService db = DatabaseService.instance;

  late TextEditingController tituloController;
  late TextEditingController contenidoController;

  @override
  void initState() {
    super.initState();

    tituloController = TextEditingController(
      text: widget.nota?.titulo ?? '',
    );

    contenidoController = TextEditingController(
      text: widget.nota?.contenido ?? '',
    );
  }

  Future<void> guardar() async {
    final titulo = tituloController.text.trim();
    final contenido = contenidoController.text.trim();

    if (titulo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El título es obligatorio'),
        ),
      );
      return;
    }

    if (widget.nota == null) {
      final nuevaNota = Nota(
        titulo: titulo,
        contenido: contenido,
        fecha: DateTime.now().toIso8601String(),
        estadoSync: 'create',
      );

      await db.insertarNota(nuevaNota);
    } else {
      String estado;

      if (widget.nota!.estadoSync == 'create') {
        estado = 'create';
      } else {
        estado = 'update';
      }

      final actualizada = Nota(
        localId: widget.nota!.localId,
        serverId: widget.nota!.serverId,
        titulo: titulo,
        contenido: contenido,
        fecha: DateTime.now().toIso8601String(),
        estadoSync: estado,
      );

      await db.actualizarNota(actualizada);
    }

    await SyncService.sincronizar();

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.nota != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          editando ? 'Editar nota' : 'Nueva nota',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: tituloController,
              decoration: const InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: contenidoController,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Contenido',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: guardar,
                icon: const Icon(Icons.save),
                label: const Text('Guardar nota'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}