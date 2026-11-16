class CitaMedica {
  final int? id;
  final String titulo;
  final String medico;
  final String fechaHora; // Formato ISO-8601
  final String lugar;
  final String notas;
  final String repeticion; // 'ninguna' o 'mensual'

  CitaMedica({
    this.id,
    required this.titulo,
    required this.medico,
    required this.fechaHora,
    this.lugar = '',
    this.notas = '',
    this.repeticion = 'ninguna',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'medico': medico,
      'fecha_hora': fechaHora,
      'lugar': lugar,
      'notas': notas,
      'repeticion': repeticion,
    };
  }

  factory CitaMedica.fromMap(Map<String, dynamic> map) {
    return CitaMedica(
      id: map['id'],
      titulo: map['titulo'],
      medico: map['medico'],
      fechaHora: map['fecha_hora'],
      lugar: map['lugar'] ?? '',
      notas: map['notas'] ?? '',
      repeticion: map['repeticion'] ?? 'ninguna',
    );
  }
}