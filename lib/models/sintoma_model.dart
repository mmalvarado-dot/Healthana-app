class Sintoma {
  final int? id;
  final int caritaId;
  final String? audioPath;
  final String? transcripcionTexto;
  final String fechaHora;

  Sintoma({
    this.id,
    required this.caritaId,
    this.audioPath,
    this.transcripcionTexto,
    required this.fechaHora,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'carita_id': caritaId,
      'audio_path': audioPath,
      'transcripcion_texto': transcripcionTexto,
      'fecha_hora': fechaHora,
    };
  }

  factory Sintoma.fromMap(Map<String, dynamic> map) {
    return Sintoma(
      id: map['id'],
      caritaId: map['carita_id'],
      audioPath: map['audio_path'],
      transcripcionTexto: map['transcripcion_texto'],
      fechaHora: map['fecha_hora'],
    );
  }
}