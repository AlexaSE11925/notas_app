import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/nota.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();

  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('notas.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notas (
        localId INTEGER PRIMARY KEY AUTOINCREMENT,
        serverId INTEGER,
        titulo TEXT NOT NULL,
        contenido TEXT,
        fecha TEXT,
        estadoSync TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertarNota(Nota nota) async {
    final db = await database;

    final datos = nota.toMap();
    datos.remove('localId');

    return db.insert('notas', datos);
  }

  Future<List<Nota>> obtenerNotas() async {
    final db = await database;

    final resultado = await db.query(
      'notas',
      where: 'estadoSync != ?',
      whereArgs: ['delete'],
      orderBy: 'localId DESC',
    );

    return resultado.map((map) => Nota.fromMap(map)).toList();
  }

  Future<List<Nota>> obtenerPendientes() async {
    final db = await database;

    final resultado = await db.query(
      'notas',
      where: 'estadoSync != ?',
      whereArgs: ['synced'],
    );

    return resultado.map((map) => Nota.fromMap(map)).toList();
  }

  Future<void> actualizarNota(Nota nota) async {
    final db = await database;

    final datos = nota.toMap();
    datos.remove('localId');

    await db.update(
      'notas',
      datos,
      where: 'localId = ?',
      whereArgs: [nota.localId],
    );
  }

  Future<void> marcarEliminada(Nota nota) async {
    final db = await database;

    if (nota.serverId == null) {
      await db.delete(
        'notas',
        where: 'localId = ?',
        whereArgs: [nota.localId],
      );
    } else {
      await db.update(
        'notas',
        {'estadoSync': 'delete'},
        where: 'localId = ?',
        whereArgs: [nota.localId],
      );
    }
  }

  Future<void> eliminarLocal(int localId) async {
    final db = await database;

    await db.delete(
      'notas',
      where: 'localId = ?',
      whereArgs: [localId],
    );
  }

  Future<void> guardarNotaServidor(Nota nota) async {
    final db = await database;

    final existente = await db.query(
      'notas',
      where: 'serverId = ?',
      whereArgs: [nota.serverId],
    );

    if (existente.isEmpty) {
      final datos = nota.toMap();
      datos.remove('localId');

      await db.insert('notas', datos);
    } else {
      final local = Nota.fromMap(existente.first);

      if (local.estadoSync == 'synced') {
        final datos = nota.toMap();
        datos.remove('localId');

        await db.update(
          'notas',
          datos,
          where: 'serverId = ?',
          whereArgs: [nota.serverId],
        );
      }
    }
  }
}