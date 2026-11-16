import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'providers/app_provider.dart';
import 'screens/splash_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/notificaciones_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa el formato de fechas en español
  await initializeDateFormatting('es', null);

  // Inicialización de Awesome Notifications
  await AwesomeNotifications().initialize(
    null,
    [
      // Canal 1: Alarmas de Medicación (Pantalla completa, sonido fuerte, vibración)
      NotificationChannel(
        channelGroupKey: 'medication_alarms',
        channelKey: 'medication_channel',
        channelName: 'Alarmas de Medicación',
        channelDescription: 'Notificaciones a pantalla completa para tomar medicamentos',
        defaultColor: const Color(0xFFE53935),
        ledColor: Colors.white,
        importance: NotificationImportance.Max,
        channelShowBadge: true,
        locked: true,
        criticalAlerts: true,
        playSound: true,
        enableVibration: true,
      ),
      // Canal 2: Recordatorios de Citas Médicas
      NotificationChannel(
        channelGroupKey: 'appointment_reminders',
        channelKey: 'appointment_channel',
        channelName: 'Recordatorios de Citas',
        channelDescription: 'Avisos de 24h y 2h antes de citas médicas',
        defaultColor: const Color(0xFF1885FF),
        ledColor: Colors.blue,
        importance: NotificationImportance.High,
        channelShowBadge: true,
        playSound: true,
      ),
      // Canal 3: Recordatorio Diario de Síntomas
      NotificationChannel(
        channelGroupKey: 'symptom_reminders',
        channelKey: 'symptom_channel',
        channelName: 'Recordatorio de Síntomas',
        channelDescription: 'Aviso diario para registrar estado de ánimo y síntomas',
        defaultColor: const Color(0xFF4CAF50),
        ledColor: Colors.green,
        importance: NotificationImportance.High,
        channelShowBadge: true,
        playSound: true,
      ),
    ],
    channelGroups: [
      NotificationChannelGroup(
        channelGroupKey: 'medication_alarms',
        channelGroupName: 'Alarmas Médicas',
      ),
      NotificationChannelGroup(
        channelGroupKey: 'appointment_reminders',
        channelGroupName: 'Citas',
      ),
      NotificationChannelGroup(
        channelGroupKey: 'symptom_reminders',
        channelGroupName: 'Síntomas',
      ),
    ],
    debug: true,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()..cargarDatos()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // Listener de acciones al tocar las notificaciones
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: NotificacionesService.onActionReceivedMethod,
    );

    // Solicitar todos los permisos necesarios (Alarmas precisas, Sonido, Alertas críticas)
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications(
          permissions: [
            NotificationPermission.Alert,
            NotificationPermission.Sound,
            NotificationPermission.Vibration,
            NotificationPermission.PreciseAlarms,
            NotificationPermission.FullScreenIntent,
            NotificationPermission.CriticalAlert,
          ],
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: MyApp.navigatorKey,
      title: 'HEALTHANA',
      debugShowCheckedModeBanner: false, 
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE53935),
          primary: const Color(0xFFE53935),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      ),
      home: const SplashScreen(),
    );
  }
}