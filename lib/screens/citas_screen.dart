import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/cita_model.dart';
import '../services/notificaciones_service.dart';

class CitasScreen extends StatefulWidget {
  const CitasScreen({super.key});

  @override
  State<CitasScreen> createState() => _CitasScreenState();
}

class _CitasScreenState extends State<CitasScreen> {
  static const primaryRed = Color(0xFFE53935);
  static const textDark = Color(0xFF1E293B);
  static const textMuted = Color(0xFF64748B);
  static const borderGrey = Color(0xFFE2E8F0);

  // Estado local para la tarjeta de recordatorio de síntomas
  bool _recordatorioSintomasActivo = true;
  TimeOfDay _horaRecordatorioSintomas = const TimeOfDay(hour: 20, minute: 0);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final citas = provider.citas;

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarModalAgregarCita(context),
        backgroundColor: primaryRed,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nueva Cita',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Tarjeta Especial: Recordatorio Diario de Síntomas
              _buildTarjetaRecordatorioSintomas(),

              const SizedBox(height: 16),
              const Divider(color: borderGrey, height: 1),
              const SizedBox(height: 16),

              // 2. Sección: Citas Médicas
              const Text(
                'Recordatorios de Citas',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Se enviarán notificaciones automáticas 24h y 2h antes de cada cita.',
                style: TextStyle(fontSize: 12, color: textMuted),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: citas.isEmpty
                    ? _buildEstadoVacio()
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: citas.length,
                        itemBuilder: (context, index) {
                          final cita = citas[index];
                          return _buildTarjetacita(cita);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tarjeta especial diferenciada para el registro diario de síntomas
  Widget _buildTarjetaRecordatorioSintomas() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8FF), // Violeta suave
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD8B4FE), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF9333EA), // Púrpura principal
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recordatorio de Síntomas',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF581C87),
                      ),
                    ),
                    Text(
                      'Notificación diaria para registrar tu estado',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF7E22CE),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _recordatorioSintomasActivo,
                activeColor: const Color(0xFF9333EA),
                onChanged: (val) {
                  setState(() {
                    _recordatorioSintomasActivo = val;
                  });
                  if (val) {
                    NotificacionesService.programarRecordatorioDiario(
                      hora: _horaRecordatorioSintomas.hour,
                      minuto: _horaRecordatorioSintomas.minute,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Recordatorio diario activado')),
                    );
                  } else {
                    NotificacionesService.cancelarRecordatorioDiario();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Recordatorio diario desactivado')),
                    );
                  }
                },
              ),
            ],
          ),
          if (_recordatorioSintomasActivo) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Hora del aviso:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF581C87),
                  ),
                ),
                InkWell(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _horaRecordatorioSintomas,
                    );
                    if (picked != null) {
                      setState(() {
                        _horaRecordatorioSintomas = picked;
                      });
                      NotificacionesService.programarRecordatorioDiario(
                        hora: picked.hour,
                        minuto: picked.minute,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Recordatorio actualizado a las ${picked.format(context)}',
                            ),
                          ),
                        );
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFC084FC)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, size: 16, color: Color(0xFF9333EA)),
                        const SizedBox(width: 6),
                        Text(
                          _horaRecordatorioSintomas.format(context),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF581C87),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEstadoVacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.event_available, size: 64, color: textMuted),
          SizedBox(height: 12),
          Text(
            'No hay citas médicas programadas',
            style: TextStyle(fontSize: 14, color: textMuted, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            'Presiona "+ Nueva Cita" para agendar una.',
            style: TextStyle(fontSize: 12, color: textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetacita(CitaMedica cita) {
    DateTime? fecha;
    try {
      fecha = DateTime.parse(cita.fechaHora);
    } catch (_) {}

    final fechaTexto = fecha != null
        ? DateFormat('EEEE d "de" MMMM - hh:mm a', 'es').format(fecha)
        : cita.fechaHora;

    final esFutura = fecha != null && fecha.isAfter(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderGrey, width: 0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  cita.titulo,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: esFutura ? Colors.blue.shade50 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  esFutura ? 'Pendiente' : 'Pasada',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: esFutura ? Colors.blue.shade700 : textMuted,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: textMuted, size: 20),
                onSelected: (value) {
                  if (value == 'editar') {
                    _mostrarModalAgregarCita(context, citaAEditar: cita);
                  } else if (value == 'eliminar') {
                    Provider.of<AppProvider>(context, listen: false).eliminarCita(cita.id!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cita eliminada correctamente')),
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'editar', child: Text('Editar Cita')),
                  const PopupMenuItem(value: 'eliminar', child: Text('Eliminar Cita')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: primaryRed),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  fechaTexto,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: primaryRed,
                  ),
                ),
              ),
            ],
          ),
          if (cita.repeticion == 'mensual') ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.autorenew, size: 14, color: Colors.green),
                const SizedBox(width: 6),
                const Text(
                  'Se repite cada mes',
                  style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
          if (cita.medico.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 14, color: textMuted),
                const SizedBox(width: 6),
                Text(
                  'Médico: ${cita.medico}',
                  style: const TextStyle(fontSize: 12, color: textDark),
                ),
              ],
            ),
          ],
          if (cita.lugar.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: textMuted),
                const SizedBox(width: 6),
                Text(
                  'Lugar: ${cita.lugar}',
                  style: const TextStyle(fontSize: 12, color: textDark),
                ),
              ],
            ),
          ],
          if (cita.notas.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Notas: ${cita.notas}',
              style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: textMuted),
            ),
          ],
        ],
      ),
    );
  }

  void _mostrarModalAgregarCita(BuildContext context, {CitaMedica? citaAEditar}) {
    final tituloCtrl = TextEditingController(text: citaAEditar?.titulo ?? '');
    final medicoCtrl = TextEditingController(text: citaAEditar?.medico ?? '');
    final lugarCtrl = TextEditingController(text: citaAEditar?.lugar ?? '');
    final notasCtrl = TextEditingController(text: citaAEditar?.notas ?? '');

    DateTime fechaSeleccionada = citaAEditar != null 
      ? DateTime.parse(citaAEditar.fechaHora) 
      : DateTime.now().add(const Duration(days: 1));
      
    TimeOfDay horaSeleccionada = citaAEditar != null
      ? TimeOfDay.fromDateTime(DateTime.parse(citaAEditar.fechaHora))
      : const TimeOfDay(hour: 9, minute: 0);

    String repeticionSeleccionada = citaAEditar?.repeticion ?? 'ninguna';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      citaAEditar != null ? 'Editar Cita Médica' : 'Agendar Cita Médica',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: tituloCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Motivo / Especialidad *',
                        hintText: 'Ej. Odontología, Chequeo general',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: medicoCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Médico',
                        hintText: 'Ej. Dr. Carlos Mendoza',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: lugarCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Lugar / Clínica',
                        hintText: 'Ej. Hospital Central, Consultorio 302',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: repeticionSeleccionada,
                      decoration: const InputDecoration(
                        labelText: 'Repetición',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'ninguna', child: Text('No repetir (Solo una vez)')),
                        DropdownMenuItem(value: 'mensual', child: Text('Repetir todos los meses')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => repeticionSeleccionada = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: modalContext,
                                initialDate: fechaSeleccionada,
                                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                lastDate: DateTime.now().add(const Duration(days: 730)),
                              );
                              if (picked != null) {
                                setModalState(() => fechaSeleccionada = picked);
                              }
                            },
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(DateFormat('dd/MM/yyyy').format(fechaSeleccionada)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: modalContext,
                                initialTime: horaSeleccionada,
                              );
                              if (picked != null) {
                                setModalState(() => horaSeleccionada = picked);
                              }
                            },
                            icon: const Icon(Icons.access_time, size: 16),
                            label: Text(horaSeleccionada.format(modalContext)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notasCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Notas adicionales',
                        hintText: 'Ej. Llevar exámenes de sangre en ayunas',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryRed,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () async {
                          if (tituloCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Por favor ingresa el motivo de la cita.')),
                            );
                            return;
                          }

                          final fechaHoraFinal = DateTime(
                            fechaSeleccionada.year,
                            fechaSeleccionada.month,
                            fechaSeleccionada.day,
                            horaSeleccionada.hour,
                            horaSeleccionada.minute,
                          );

                          final nuevaCita = CitaMedica(
                            id: citaAEditar?.id,
                            titulo: tituloCtrl.text.trim(),
                            medico: medicoCtrl.text.trim(),
                            lugar: lugarCtrl.text.trim(),
                            notas: notasCtrl.text.trim(),
                            fechaHora: fechaHoraFinal.toIso8601String(),
                            repeticion: repeticionSeleccionada,
                          );

                          final provider = Provider.of<AppProvider>(context, listen: false);
                          
                          if (citaAEditar != null) {
                            await provider.actualizarCita(nuevaCita);
                          } else {
                            await provider.agregarCita(nuevaCita);
                          }

                          if (context.mounted) {
                            Navigator.pop(modalContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(citaAEditar != null ? 'Cita médica actualizada.' : 'Cita médica agendada.')),
                            );
                          }
                        },
                        child: Text(
                          citaAEditar != null ? 'ACTUALIZAR CITA' : 'GUARDAR CITA',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}