import 'dart:io';
import 'package:flutter/material.dart' show BuildContext, ScaffoldMessenger, SnackBar, Text, Colors, Duration;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfService {
  static Future<void> generarYCompartirPDF({
    required dynamic config,
    required List<dynamic> historialTomas,
    List<dynamic> sintomas = const [],
    BuildContext? context,
  }) async {
    try {
      final pdf = pw.Document();
      final fontRegular = pw.Font.helvetica();
      final fontBold = pw.Font.helveticaBold();

      final fechaActual = DateTime.now();
      final fechaFormateada = '${fechaActual.day.toString().padLeft(2, '0')}/${fechaActual.month.toString().padLeft(2, '0')}/${fechaActual.year}';

      String getCampo(dynamic obj, List<String> llaves, String defecto) {
        if (obj == null) return defecto;
        if (obj is Map) {
          for (var k in llaves) {
            if (obj[k] != null && obj[k].toString().trim().isNotEmpty) {
              return obj[k].toString().trim();
            }
          }
        } else {
          for (var k in llaves) {
            try {
              dynamic val;
              if (k == 'nombrePaciente') val = obj.nombrePaciente;
              else if (k == 'edadPaciente') val = obj.edadPaciente;
              else if (k == 'tipoSangre') val = obj.tipoSangre;
              else if (k == 'contactoNombre') val = obj.contactoNombre;
              else if (k == 'contactoTelefono') val = obj.contactoTelefono;
              else if (k == 'notasMedicas') val = obj.notasMedicas;
              if (val != null && val.toString().trim().isNotEmpty) return val.toString().trim();
            } catch (_) {}
          }
        }
        return defecto;
      }

      final nombre = getCampo(config, ['nombrePaciente', 'nombre'], 'Paciente');
      final edad = getCampo(config, ['edadPaciente', 'edad'], '--');
      final sangre = getCampo(config, ['tipoSangre', 'sangre'], '--');
      final contactoNom = getCampo(config, ['contactoNombre', 'contacto'], 'Sin registrar');
      final contactoTel = getCampo(config, ['contactoTelefono', 'telefono'], 'Sin registrar');
      final notas = getCampo(config, ['notasMedicas', 'notas'], 'Sin observaciones.');

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
          build: (pw.Context ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('HEALTHANA - REPORTE CLÍNICO', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
                    pw.Text('Fecha: $fechaFormateada', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Divider(thickness: 1, color: PdfColors.red800),
                pw.SizedBox(height: 10),
                pw.Text('DATOS DEL PACIENTE', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text('Nombre: $nombre   |   Edad: $edad años   |   Tipo de Sangre: $sangre', style: const pw.TextStyle(fontSize: 10)),
                pw.SizedBox(height: 10),
                pw.Text('CONTACTO DE EMERGENCIA', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text('Nombre: $contactoNom   |   Teléfono: $contactoTel', style: const pw.TextStyle(fontSize: 10)),
                pw.SizedBox(height: 10),
                pw.Text('NOTAS MÉDICAS Y OBSERVACIONES', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text(notas, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
                pw.SizedBox(height: 14),
                pw.Text('HISTORIAL DE MEDICAMENTOS (${historialTomas.length} tomas)', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                if (historialTomas.isEmpty)
                  pw.Text('No hay tomas registradas en el historial.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600))
                else
                  pw.Column(
                    children: historialTomas.take(12).map((toma) {
                      final nomMed = getCampo(toma, ['nombre', 'medicamento'], 'Medicamento');
                      final dosisMed = getCampo(toma, ['dosis'], '');
                      final fechaReal = getCampo(toma, ['fecha_hora_real', 'fecha'], '--');
                      final estado = getCampo(toma, ['estado'], 'Tomado');
                      return pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 2),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('$nomMed $dosisMed'.trim(), style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                            pw.Text('$fechaReal ($estado)', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                pw.SizedBox(height: 14),
                pw.Text('SÍNTOMAS REGISTRADOS (${sintomas.length} registros)', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                if (sintomas.isEmpty)
                  pw.Text('No hay síntomas registrados.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600))
                else
                  pw.Column(
                    children: sintomas.take(8).map((s) {
                      final carita = getCampo(s, ['caritaId', 'carita_id'], 'N/A');
                      final nota = getCampo(s, ['transcripcionTexto', 'descripcion'], 'Sin nota');
                      final fecha = getCampo(s, ['fechaHora', 'fecha'], '--');
                      return pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 2),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Nivel $carita: $nota', style: const pw.TextStyle(fontSize: 9)),
                            pw.Text(fecha, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            );
          },
        ),
      );

      final bytes = await pdf.save();

      // Ruta de guardado interna en almacenamiento de la app (No se bloquea por permisos de Android 13)
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/Reporte_HEALTHANA.pdf');
      await file.writeAsBytes(bytes);

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Reporte PDF guardado con éxito:\n${file.path}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}