import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/pdf_service.dart';

class EstadisticasScreen extends StatefulWidget {
  const EstadisticasScreen({super.key});

  @override
  State<EstadisticasScreen> createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen> {
  bool _generandoPdf = false;

  String _obtenerDescripcionSintoma(int caritaId) {
    switch (caritaId) {
      case 1:
        return 'Excelente 😀';
      case 2:
        return 'Bueno 🙂';
      case 3:
        return 'Regular 😐';
      case 4:
        return 'Malo 🙁';
      case 5:
        return 'Muy Malo 😫';
      default:
        return 'No especificado ❓';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final historial = provider.historialTomas;
    final sintomas = provider.sintomas;
    final config = provider.cuidadorConfig;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas y Reportes', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: paddingBody(context, historial, sintomas, config),
    );
  }

  Widget paddingBody(BuildContext context, List<dynamic> historial, List<dynamic> sintomas, dynamic config) {
    if (config == null) {
      return const Center(child: Text('Faltan datos del paciente.'));
    }

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.medication_outlined, size: 36, color: Color(0xFFE53935)),
                      const SizedBox(height: 8),
                      const Text('Tomas Registradas', style: TextStyle(fontSize: 12, color: Colors.black54), textAlign: TextAlign.center),
                      Text('${historial.length}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFE53935))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.mood_outlined, size: 36, color: Colors.orange),
                      const SizedBox(height: 8),
                      const Text('Síntomas Grabados', style: TextStyle(fontSize: 12, color: Colors.black54), textAlign: TextAlign.center),
                      Text('${sintomas.length}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.orange)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Últimos Síntomas Registrados:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Expanded(
            child: sintomas.isEmpty
                ? const Center(child: Text('No hay registro de síntomas.', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: sintomas.length,
                    itemBuilder: (ctx, index) {
                      final s = sintomas[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange.shade100,
                            child: Text('${s.caritaId}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                          ),
                          title: Text(_obtenerDescripcionSintoma(s.caritaId), style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(s.transcripcionTexto != null && s.transcripcionTexto!.isNotEmpty 
                              ? s.transcripcionTexto! 
                              : 'Sin nota de voz transcrita'),
                          trailing: Text(
                            s.fechaHora.length >= 10 ? s.fechaHora.substring(0, 10) : s.fechaHora,
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Genera un documento PDF con el historial completo para enviarlo al médico.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: _generandoPdf 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.picture_as_pdf, color: Colors.white),
            label: Text(
              _generandoPdf ? 'GENERANDO PDF...' : 'EXPORTAR REPORTE PDF', 
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
            ),
            onPressed: _generandoPdf ? null : () async {
              setState(() => _generandoPdf = true);
              try {
                await PdfService.generarYCompartirPDF(
                  config: config,
                  historialTomas: historial,
                  sintomas: sintomas,
                  context: context,
                );
              } finally {
                if (mounted) setState(() => _generandoPdf = false);
              }
            },
          ),
        ],
      ),
    );
  }
}