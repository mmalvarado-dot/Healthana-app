import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../models/medicamento_model.dart';
import '../models/sintoma_model.dart';
import '../models/cuidador_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<int> insertCita(Map<String, dynamic> citaMap) async {
    Database db = await instance.database;
    return await db.insert('citas', citaMap);
  }

  Future<List<Map<String, dynamic>>> getCitas() async {
    Database db = await instance.database;
    return await db.query('citas', orderBy: 'fecha_hora ASC');
  }

  Future<int> updateCita(Map<String, dynamic> citaMap) async {
    Database db = await instance.database;
    return await db.update(
      'citas',
      citaMap,
      where: 'id = ?',
      whereArgs: [citaMap['id']],
    );
  }

  Future<int> deleteCita(int id) async {
    Database db = await instance.database;
    return await db.delete(
      'citas',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('healthana.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
      CREATE TABLE citas(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT,
        medico TEXT,
        fecha_hora TEXT,
        lugar TEXT,
        notas TEXT,
        repeticion TEXT DEFAULT 'ninguna'
      )
    ''');

    await db.execute('''
      CREATE TABLE cuidador_config (
        id INTEGER PRIMARY KEY,
        pin_hash $textType,
        contacto_nombre $textType,
        contacto_telefono $textType,
        nombre_paciente $textType,
        edad_paciente $intType,
        tipo_sangre $textType,
        notas_medicas $textNullable
      )
    ''');

    await db.execute('''
      CREATE TABLE medicamentos (
        id $idType,
        nombre $textType,
        dosis $textType,
        hora_programada $textType,
        frecuencia_horas $intType,
        estado_activo INTEGER NOT NULL DEFAULT 1,
        inventario_actual INTEGER NOT NULL DEFAULT 0,
        inventario_alerta INTEGER NOT NULL DEFAULT 5
      )
    ''');

    await db.execute('''
      CREATE TABLE registro_tomas (
        id $idType,
        medicamento_id $intType,
        fecha_hora_programada $textType,
        fecha_hora_real $textNullable,
        estado $textType,
        FOREIGN KEY (medicamento_id) REFERENCES medicamentos (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE registro_sintomas (
        id $idType,
        carita_id $intType,
        audio_path $textNullable,
        transcripcion_texto $textNullable,
        fecha_hora $textType
      )
    ''');

    await db.insert('cuidador_config', {
      'id': 1,
      'pin_hash': '1234',
      'contacto_nombre': '',
      'contacto_telefono': '',
      'nombre_paciente': '',
      'edad_paciente': 0,
      'tipo_sangre': '',
      'notas_medicas': '',
    });
  }

  // ==========================================
  // MÉTODOS CUIDADOR Y CONFIGURACIÓN
  // ==========================================
  Future<CuidadorConfig?> getCuidadorConfig() async {
    final db = await instance.database;
    final maps = await db.query('cuidador_config', where: 'id = ?', whereArgs: [1]);
    if (maps.isNotEmpty) {
      return CuidadorConfig.fromMap(maps.first);
    }
    return null;
  }

  Future<bool> verificarPin(String pinIngresado) async {
    final config = await getCuidadorConfig();
    if (config == null) return false;
    return config.pinHash == pinIngresado;
  }

  Future<int> actualizarPin(String nuevoPin) async {
    final db = await instance.database;
    return await db.update(
      'cuidador_config',
      {'pin_hash': nuevoPin},
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  Future<int> actualizarCuidadorConfig(CuidadorConfig config) async {
    final db = await instance.database;
    return await db.update(
      'cuidador_config',
      config.toMap(),
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  // ==========================================
  // MÉTODOS MEDICAMENTOS
  // ==========================================
  Future<List<Medicamento>> getMedicamentos() async {
    final db = await instance.database;
    final result = await db.query('medicamentos', orderBy: 'id DESC');
    return result.map((json) => Medicamento.fromMap(json)).toList();
  }

  Future<int> insertMedicamento(Medicamento med) async {
    final db = await instance.database;
    return await db.insert('medicamentos', med.toMap());
  }

  Future<int> updateMedicamento(Medicamento med) async {
    final db = await instance.database;
    return await db.update(
      'medicamentos',
      med.toMap(),
      where: 'id = ?',
      whereArgs: [med.id],
    );
  }

  Future<int> cambiarEstadoMedicamento(int id, int nuevoEstado) async {
    final db = await instance.database;
    return await db.update(
      'medicamentos',
      {'estado_activo': nuevoEstado},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteMedicamento(int id) async {
    final db = await instance.database;
    return await db.delete(
      'medicamentos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> actualizarInventario(int id, int nuevaCantidad) async {
    final db = await instance.database;
    return await db.update(
      'medicamentos',
      {'inventario_actual': nuevaCantidad},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==========================================
  // MÉTODOS SÍNTOMAS
  // ==========================================
  Future<int> insertSintoma(Sintoma sintoma) async {
    final db = await instance.database;
    return await db.insert('registro_sintomas', sintoma.toMap());
  }

  Future<List<Sintoma>> getSintomas() async {
    final db = await instance.database;
    final result = await db.query('registro_sintomas', orderBy: 'fecha_hora DESC');
    return result.map((json) => Sintoma.fromMap(json)).toList();
  }

  // ==========================================
  // MÉTODOS REGISTRO DE TOMAS
  // ==========================================
  Future<int> registrarToma(int medicamentoId, String fechaProg, String fechaReal, String estado) async {
    final db = await instance.database;
    return await db.insert('registro_tomas', {
      'medicamento_id': medicamentoId,
      'fecha_hora_programada': fechaProg,
      'fecha_hora_real': fechaReal,
      'estado': estado,
    });
  }

  Future<List<Map<String, dynamic>>> getHistorialTomas() async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT t.id, t.fecha_hora_real, t.estado, m.nombre, m.dosis
      FROM registro_tomas t
      JOIN medicamentos m ON t.medicamento_id = m.id
      ORDER BY t.fecha_hora_real DESC
    ''');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}