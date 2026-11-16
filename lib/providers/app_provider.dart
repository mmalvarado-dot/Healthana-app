import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/medicamento_model.dart';
import '../models/sintoma_model.dart';
import '../models/cuidador_model.dart';
import '../models/cita_model.dart';
import '../services/notificaciones_service.dart';

class AppProvider extends ChangeNotifier {
  List<Medicamento> _medicamentos = [];
  List<Sintoma> _sintomas = [];
  
  // Línea simplificada para que no se borre al copiar y pegar
  List _historialTomas = [];
  
  List<CitaMedica> _citas = [];
  CuidadorConfig? _cuidadorConfig;
  bool _isLoading = false;

  int _pestanaActual = 0;

  // Getters
  List<Medicamento> get medicamentos => _medicamentos;
  List<Sintoma> get sintomas => _sintomas;
  
  // Línea simplificada
  List get historialTomas => _historialTomas;
  
  List<CitaMedica> get citas => _citas;
  CuidadorConfig? get cuidadorConfig => _cuidadorConfig;
  bool get isLoading => _isLoading;
  int get pestanaActual => _pestanaActual;

  void cambiarPestana(int nuevoIndice) {
    _pestanaActual = nuevoIndice;
    notifyListeners();
  }

  Future<void> cargarDatos() async {
    _isLoading = true;
    notifyListeners();

    _medicamentos = await DatabaseHelper.instance.getMedicamentos();
    _sintomas = await DatabaseHelper.instance.getSintomas();
    _cuidadorConfig = await DatabaseHelper.instance.getCuidadorConfig();
    _historialTomas = await DatabaseHelper.instance.getHistorialTomas();
    
    final citasData = await DatabaseHelper.instance.getCitas();
    _citas = citasData.map((c) => CitaMedica.fromMap(c)).toList();

    // =========================================================
    // PROGRAMACIÓN DEL RECORDATORIO DIARIO DE SÍNTOMAS
    // =========================================================
    await NotificacionesService.programarRecordatorioDiarioSintomas();

    // =========================================================
    // LÓGICA DE RENOVACIÓN AUTOMÁTICA DE CITAS MENSUALES
    // =========================================================
    bool huboCambios = false;
    final ahora = DateTime.now();

    for (var cita in _citas) {
      if (cita.repeticion == 'mensual') {
        final fechaCita = DateTime.parse(cita.fechaHora);
        
        if (fechaCita.isBefore(ahora)) {
          final proximaFecha = DateTime(
            fechaCita.year,
            fechaCita.month + 1,
            fechaCita.day,
            fechaCita.hour,
            fechaCita.minute,
          );

          final nuevaCita = CitaMedica(
            titulo: cita.titulo,
            medico: cita.medico,
            lugar: cita.lugar,
            notas: cita.notas,
            fechaHora: proximaFecha.toIso8601String(),
            repeticion: 'mensual', 
          );
          
          final nuevoId = await DatabaseHelper.instance.insertCita(nuevaCita.toMap());
          
          if (proximaFecha.isAfter(ahora)) {
            await NotificacionesService.programarRecordatorioCita(
              idCita: nuevoId,
              titulo: nuevaCita.titulo,
              fechaHoraCita: proximaFecha,
            );
          }

          final citaViejaActualizada = CitaMedica(
            id: cita.id,
            titulo: cita.titulo,
            medico: cita.medico,
            lugar: cita.lugar,
            notas: cita.notas,
            fechaHora: cita.fechaHora,
            repeticion: 'ninguna', 
          );
          await DatabaseHelper.instance.updateCita(citaViejaActualizada.toMap());

          huboCambios = true;
        }
      }
    }

    if (huboCambios) {
      final citasActualizadas = await DatabaseHelper.instance.getCitas();
      _citas = citasActualizadas.map((c) => CitaMedica.fromMap(c)).toList();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> verificarPin(String pinIngresado) async {
    return await DatabaseHelper.instance.verificarPin(pinIngresado);
  }

  Future<void> cambiarPin(String nuevoPin) async {
    await DatabaseHelper.instance.actualizarPin(nuevoPin);
    await cargarDatos();
  }

  Future<void> actualizarConfiguracion(CuidadorConfig nuevaConfig) async {
    await DatabaseHelper.instance.actualizarCuidadorConfig(nuevaConfig);
    await cargarDatos();
  }

  Future<void> registrarTomaMedicamento(int medicamentoId, {String estado = 'TOMADO_A_TIEMPO', String? horaProgramada}) async {
    final ahora = DateTime.now().toIso8601String();
    final horaProg = horaProgramada ?? ahora;
    
    await DatabaseHelper.instance.registrarToma(
      medicamentoId,
      horaProg,
      ahora,
      estado,
    );

    final medIndex = _medicamentos.indexWhere((m) => m.id == medicamentoId);
    if (medIndex != -1) {
      final med = _medicamentos[medIndex];
      if (med.inventarioActual > 0) {
        await DatabaseHelper.instance.actualizarInventario(med.id!, med.inventarioActual - 1);
      }
    }

    await cargarDatos();
  }

  Future<void> guardarSintoma({
    required int caritaId,
    String? audioPath,
    String? transcripcion,
  }) async {
    final nuevoSintoma = Sintoma(
      caritaId: caritaId,
      audioPath: audioPath,
      transcripcionTexto: transcripcion,
      fechaHora: DateTime.now().toIso8601String(),
    );
    await DatabaseHelper.instance.insertSintoma(nuevoSintoma);
    await cargarDatos();
  }

  Future<int> agregarMedicamento(Medicamento med) async {
    final idInsertado = await DatabaseHelper.instance.insertMedicamento(med);
    await cargarDatos();
    return idInsertado;
  }

  Future<void> actualizarMedicamento(Medicamento med) async {
    await DatabaseHelper.instance.updateMedicamento(med);
    await cargarDatos();
  }

  Future<void> cambiarEstadoMedicamento(int id, bool activar) async {
    int nuevoEstado = activar ? 1 : 0; 
    await DatabaseHelper.instance.cambiarEstadoMedicamento(id, nuevoEstado);
    await cargarDatos();
  }

  Future<void> eliminarMedicamento(int id) async {
    await DatabaseHelper.instance.deleteMedicamento(id);
    await cargarDatos();
  }

  Future<void> agregarCita(CitaMedica cita) async {
    final idInsertado = await DatabaseHelper.instance.insertCita(cita.toMap());
    
    final fechaCita = DateTime.parse(cita.fechaHora);
    if (fechaCita.isAfter(DateTime.now())) {
      await NotificacionesService.programarRecordatorioCita(
        idCita: idInsertado,
        titulo: cita.titulo,
        fechaHoraCita: fechaCita,
      );
    }
    await cargarDatos();
  }

  Future<void> actualizarCita(CitaMedica cita) async {
    await DatabaseHelper.instance.updateCita(cita.toMap());
    
    final fechaCita = DateTime.parse(cita.fechaHora);
    if (fechaCita.isAfter(DateTime.now())) {
      await NotificacionesService.programarRecordatorioCita(
        idCita: cita.id!,
        titulo: cita.titulo,
        fechaHoraCita: fechaCita,
      );
    }
    await cargarDatos();
  }

  Future<void> eliminarCita(int id) async {
    await DatabaseHelper.instance.deleteCita(id);
    await cargarDatos();
  }
}

