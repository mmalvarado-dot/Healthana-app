import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../providers/app_provider.dart';
import '../main.dart';

class NotificacionesService {
  static const int idRecordatorioSintomas = 88888;

  // 1. Programar la alarma inicial o siguiente toma de un medicamento
  static Future<void> programarAlarmaMedicamento({
    required int idMedicamento,
    required String nombreMedicamento,
    required DateTime horaProgramada,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: idMedicamento,
        channelKey: 'medication_channel',
        title: '¡Hora de tu medicina!',
        body: 'Es hora de tomar: $nombreMedicamento',
        category: NotificationCategory.Alarm,
        wakeUpScreen: true,
        fullScreenIntent: true,
        criticalAlert: true,
        payload: {
          'medicamentoId': idMedicamento.toString(),
          'horaProgramada': horaProgramada.toIso8601String(),
          'retrasado': 'false',
        },
      ),
      schedule: NotificationCalendar.fromDate(date: horaProgramada),
      actionButtons: [
        NotificationActionButton(
          key: 'TAKE_NOW',
          label: 'Tomar Ahora',
          color: Colors.green,
          autoDismissible: true,
        ),
        NotificationActionButton(
          key: 'SNOOZE',
          label: 'Posponer 15 min',
          color: Colors.orange,
          autoDismissible: true,
        ),
      ],
    );
  }

  // 2. Cancelar la alarma de un medicamento
  static Future<void> cancelarAlarmaMedicamento(int idMedicamento) async {
    await AwesomeNotifications().cancel(idMedicamento);
  }

  // 3. Programar recordatorios para Citas Médicas
  static Future<void> programarRecordatorioCita({
    required int idCita,
    required String titulo,
    required DateTime fechaHoraCita,
  }) async {
    final recordatorio24h = fechaHoraCita.subtract(const Duration(hours: 24));
    if (recordatorio24h.isAfter(DateTime.now())) {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: idCita * 10,
          channelKey: 'appointment_channel',
          title: 'Cita Médica Mañana 📅',
          body:
              'Mañana tienes la cita: $titulo a las ${fechaHoraCita.hour.toString().padLeft(2, '0')}:${fechaHoraCita.minute.toString().padLeft(2, '0')}.',
          category: NotificationCategory.Reminder,
        ),
        schedule: NotificationCalendar.fromDate(date: recordatorio24h),
      );
    }

    final recordatorio2h = fechaHoraCita.subtract(const Duration(hours: 2));
    if (recordatorio2h.isAfter(DateTime.now())) {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: (idCita * 10) + 1,
          channelKey: 'appointment_channel',
          title: 'Cita Médica Próxima 🚨',
          body: 'En 2 horas tienes la cita: $titulo. ¡Prepárate!',
          category: NotificationCategory.Reminder,
        ),
        schedule: NotificationCalendar.fromDate(date: recordatorio2h),
      );
    }
  }

  // 4. Programar Recordatorio Diario para Síntomas
  static Future<void> programarRecordatorioDiario({
    required int hora,
    required int minuto,
  }) async {
    await cancelarRecordatorioDiario();

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: idRecordatorioSintomas,
        channelKey: 'symptom_channel',
        title: '¿Cómo te sentiste hoy? 😊',
        body: 'Tómate un segundo para registrar cómo te has sentido. ¡Tu salud es importante!',
        category: NotificationCategory.Reminder,
        payload: {
          'tipo': 'sintoma_diario',
        },
      ),
      schedule: NotificationCalendar(
        hour: hora,
        minute: minuto,
        second: 0,
        millisecond: 0,
        repeats: true,
      ),
    );
  }

  static Future<void> programarRecordatorioDiarioSintomas() async {
    await programarRecordatorioDiario(hora: 20, minuto: 0);
  }

  static Future<void> cancelarRecordatorioDiario() async {
    await AwesomeNotifications().cancel(idRecordatorioSintomas);
  }

  // 5. Escuchador de acciones en notificaciones
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    final payload = receivedAction.payload;

    // --- ACCIÓN: REDIRECCIÓN A SÍNTOMAS ---
    if (payload != null && payload['tipo'] == 'sintoma_diario') {
      final context = MyApp.navigatorKey.currentContext;
      if (context != null) {
        Provider.of<AppProvider>(context, listen: false).cambiarPestana(1);
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
      return;
    }

    // --- ACCIÓN: MEDICAMENTOS ---
    if (payload == null || !payload.containsKey('medicamentoId')) return;

    final int medId = int.parse(payload['medicamentoId']!);
    final String horaProgramadaStr = payload['horaProgramada']!;
    final bool esRetrasado = payload['retrasado'] == 'true';

    if (receivedAction.buttonKeyPressed == 'TAKE_NOW') {
      final estado = esRetrasado ? 'RETRASO' : 'TOMADO_A_TIEMPO';
      final ahora = DateTime.now().toIso8601String();

      // 1. Registrar la toma en BD
      await DatabaseHelper.instance
          .registrarToma(medId, horaProgramadaStr, ahora, estado);

      // 2. Actualizar inventario y programar la siguiente alarma
      final meds = await DatabaseHelper.instance.getMedicamentos();
      try {
        final medicamento = meds.firstWhere((m) => m.id == medId);
        
        if (medicamento.inventarioActual > 0) {
          await DatabaseHelper.instance.actualizarInventario(
              medId, medicamento.inventarioActual - 1);
        }

        // 3. Programar la siguiente toma según la frecuencia (ej: cada 8 horas)
        final DateTime horaAnterior = DateTime.tryParse(horaProgramadaStr) ?? DateTime.now();
        final DateTime proximaToma = horaAnterior.add(Duration(hours: medicamento.frecuenciaHoras));

        await programarAlarmaMedicamento(
          idMedicamento: medId,
          nombreMedicamento: medicamento.nombre,
          horaProgramada: proximaToma,
        );
      } catch (e) {
        // En caso de que el medicamento haya sido eliminado
      }
    } else if (receivedAction.buttonKeyPressed == 'SNOOZE') {
      final nuevaHora = DateTime.now().add(const Duration(minutes: 15));

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: medId,
          channelKey: 'medication_channel',
          title: 'Medicamento Pospuesto',
          body:
              'Debías tomar ${receivedAction.body?.replaceAll('Es hora de tomar: ', '') ?? 'tu medicina'}. ¡No lo olvides!',
          category: NotificationCategory.Alarm,
          wakeUpScreen: true,
          fullScreenIntent: true,
          criticalAlert: true,
          payload: {
            'medicamentoId': medId.toString(),
            'horaProgramada': horaProgramadaStr,
            'retrasado': 'true',
          },
        ),
        schedule: NotificationCalendar.fromDate(date: nuevaHora),
        actionButtons: [
          NotificationActionButton(
              key: 'TAKE_NOW', label: 'Tomar Ahora', color: Colors.green),
          NotificationActionButton(
              key: 'SNOOZE',
              label: 'Posponer 15 min más',
              color: Colors.orange),
        ],
      );
    }
  }
}