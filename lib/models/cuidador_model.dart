class CuidadorConfig {
  final int id;
  final String pinHash;
  final String contactoNombre;
  final String contactoTelefono;
  final String nombrePaciente;
  final int edadPaciente;
  final String tipoSangre;
  final String notasMedicas;

  CuidadorConfig({
    required this.id,
    required this.pinHash,
    required this.contactoNombre,
    required this.contactoTelefono,
    required this.nombrePaciente,
    required this.edadPaciente,
    required this.tipoSangre,
    required this.notasMedicas,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pin_hash': pinHash,
      'contacto_nombre': contactoNombre,
      'contacto_telefono': contactoTelefono,
      'nombre_paciente': nombrePaciente,
      'edad_paciente': edadPaciente,
      'tipo_sangre': tipoSangre,
      'notas_medicas': notasMedicas,
    };
  }

  factory CuidadorConfig.fromMap(Map<String, dynamic> map) {
    return CuidadorConfig(
      id: map['id'],
      pinHash: map['pin_hash'],
      contactoNombre: map['contacto_nombre'],
      contactoTelefono: map['contacto_telefono'],
      nombrePaciente: map['nombre_paciente'] ?? 'Roberto',
      edadPaciente: map['edad_paciente'] ?? 70,
      tipoSangre: map['tipo_sangre'] ?? 'O+',
      notasMedicas: map['notas_medicas'] ?? '',
    );
  }
}