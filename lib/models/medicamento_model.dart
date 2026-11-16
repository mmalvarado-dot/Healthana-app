class Medicamento {
  final int? id;
  final String nombre;
  final String dosis;
  final String horaProgramada;
  final int frecuenciaHoras;
  final int estadoActivo;
  final int inventarioActual; 
  final int inventarioAlerta; 

  Medicamento({
    this.id,
    required this.nombre,
    required this.dosis,
    required this.horaProgramada,
    required this.frecuenciaHoras,
    this.estadoActivo = 1,
    this.inventarioActual = 0,
    this.inventarioAlerta = 5,
  });

  // NUEVO: Getter que transforma el 1 o 0 en true o false (Ideal para el Switch)
  bool get isActivo => estadoActivo == 1;

  // NUEVO: Método copyWith (súper útil para cuando vayamos a Editar la receta)
  Medicamento copyWith({
    int? id,
    String? nombre,
    String? dosis,
    String? horaProgramada,
    int? frecuenciaHoras,
    int? estadoActivo,
    int? inventarioActual,
    int? inventarioAlerta,
  }) {
    return Medicamento(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      dosis: dosis ?? this.dosis,
      horaProgramada: horaProgramada ?? this.horaProgramada,
      frecuenciaHoras: frecuenciaHoras ?? this.frecuenciaHoras,
      estadoActivo: estadoActivo ?? this.estadoActivo,
      inventarioActual: inventarioActual ?? this.inventarioActual,
      inventarioAlerta: inventarioAlerta ?? this.inventarioAlerta,
    );
  }

  // Convierte un objeto Medicamento a un Mapa para guardar en SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'dosis': dosis,
      'hora_programada': horaProgramada,
      'frecuencia_horas': frecuenciaHoras,
      'estado_activo': estadoActivo,
      'inventario_actual': inventarioActual,
      'inventario_alerta': inventarioAlerta,
    };
  }

  // Convierte una fila de SQLite a un objeto Medicamento para Flutter
  factory Medicamento.fromMap(Map<String, dynamic> map) {
    return Medicamento(
      id: map['id'],
      nombre: map['nombre'],
      dosis: map['dosis'],
      horaProgramada: map['hora_programada'],
      frecuenciaHoras: map['frecuencia_horas'],
      estadoActivo: map['estado_activo'] ?? 1,
      inventarioActual: map['inventario_actual'] ?? 0,
      inventarioAlerta: map['inventario_alerta'] ?? 5,
    );
  }
}