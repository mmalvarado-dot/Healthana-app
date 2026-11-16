import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_provider.dart';
import '../models/medicamento_model.dart';
import '../models/cuidador_model.dart';
import 'ajustes_screen.dart';
import 'tutorial_cuidador_screen.dart';

class InicioScreen extends StatelessWidget {
  const InicioScreen({super.key});

  final Color _primaryRed = const Color(0xFFE53935);

  bool _fueTomadoHoy(Medicamento med, List<dynamic> historialRaw) {
    final ahora = DateTime.now();
    
    for (var item in historialRaw) {
      if (item is Map) {
        final toma = Map<String, dynamic>.from(item);
        if (toma['nombre'] == med.nombre && toma['fecha_hora_real'] != null) {
          try {
            final fechaToma = DateTime.parse(toma['fecha_hora_real'].toString());
            if (fechaToma.year == ahora.year && 
                fechaToma.month == ahora.month && 
                fechaToma.day == ahora.day) {
              return true;
            }
          } catch (e) {
            continue;
          }
        }
      }
    }
    return false;
  }

  void _mostrarPerfilPaciente(BuildContext context, CuidadorConfig? config) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, 
                  height: 4, 
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))
                )
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  CircleAvatar(
                    radius: 28, 
                    backgroundColor: _primaryRed.withOpacity(0.12), 
                    child: Icon(Icons.person, size: 34, color: _primaryRed)
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(config?.nombrePaciente ?? 'Paciente', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        const Text('Perfil de usuario (Solo Lectura)', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 30),
              _buildItemPerfil(Icons.cake_outlined, 'Edad', '${config?.edadPaciente ?? "--"} años'),
              const SizedBox(height: 14),
              _buildItemPerfil(Icons.water_drop_outlined, 'Tipo de Sangre', config?.tipoSangre ?? 'No registrado'),
              const SizedBox(height: 14),
              _buildItemPerfil(Icons.phone_android_outlined, 'Contacto de Emergencia', '${config?.contactoNombre ?? "No asignado"}\n${config?.contactoTelefono ?? ""}'),
              const SizedBox(height: 14),
              _buildItemPerfil(Icons.assignment_outlined, 'Notas Médicas', config?.notasMedicas.isNotEmpty == true ? config!.notasMedicas : 'Sin observaciones registradas.'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200, 
                    foregroundColor: Colors.black87, 
                    elevation: 0, 
                    padding: const EdgeInsets.symmetric(vertical: 14), 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('ENTENDIDO', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItemPerfil(IconData icono, String titulo, String valor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, color: _primaryRed, size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(valor, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
            ],
          ),
        ),
      ],
    );
  }

  void _mostrarOpcionesContacto(BuildContext context, String? numero) {
    if (numero == null || numero.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay número de emergencia guardado.')));
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(padding: EdgeInsets.all(16.0), child: Text('Contactar cuidador', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.blue),
              title: const Text('Llamada telefónica'),
              onTap: () async {
                Navigator.pop(ctx);
                final Uri url = Uri.parse('tel:$numero');
                if (await canLaunchUrl(url)) await launchUrl(url);
              },
            ),
            ListTile(
              leading: const Icon(Icons.message, color: Colors.green),
              title: const Text('Mensaje por WhatsApp'),
              onTap: () async {
                Navigator.pop(ctx);
                final Uri url = Uri.parse('https://wa.me/${numero.replaceAll('+', '').replaceAll(' ', '')}');
                if (await canLaunchUrl(url)) await launchUrl(url);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _solicitarPinCuidador(BuildContext context) {
    final pinController = TextEditingController();
    final provider = Provider.of<AppProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [Icon(Icons.lock, color: _primaryRed), const SizedBox(width: 10), const Text('Modo Cuidador', style: TextStyle(fontSize: 18))]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ingrese el PIN de 4 dígitos para continuar:'),
            const SizedBox(height: 16),
            TextField(
              controller: pinController, 
              keyboardType: TextInputType.number, 
              obscureText: true, 
              maxLength: 4, 
              textAlign: TextAlign.center, 
              style: const TextStyle(fontSize: 24, letterSpacing: 8), 
              decoration: InputDecoration(counterText: '', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('CANCELAR')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primaryRed),
            onPressed: () async {
              final esCorrecto = await provider.verificarPin(pinController.text.trim());
              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
              
              if (esCorrecto) {
                if (!context.mounted) return;
                final prefs = await SharedPreferences.getInstance();
                if (!context.mounted) return;
                
                final yaVioTutorial = prefs.getBool('vistoTutorialCuidador') ?? false;

                if (!yaVioTutorial) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TutorialCuidadorScreen()));
                } else {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AjustesScreen()));
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN incorrecto.'), backgroundColor: Colors.red));
                }
              }
            },
            child: const Text('INGRESAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final cuidadorConfig = provider.cuidadorConfig;
    final nombrePaciente = cuidadorConfig?.nombrePaciente ?? 'Paciente';

    final historialList = provider.historialTomas;

    List<Medicamento> medicamentosPendientes = provider.medicamentos
        .where((med) => med.isActivo && !_fueTomadoHoy(med, historialList))
        .toList();

    List<Medicamento> manana = [];
    List<Medicamento> tardeNoche = [];

    for (var med in medicamentosPendientes) {
      if (med.horaProgramada.toUpperCase().contains('AM')) {
        manana.add(med);
      } else {
        tardeNoche.add(med);
      }
    }

    List<dynamic> citasPendientes = provider.citas; 

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: GestureDetector(
          onTap: () => _mostrarPerfilPaciente(context, cuidadorConfig),
          child: Row(
            children: [
              CircleAvatar(radius: 20, backgroundColor: _primaryRed.withOpacity(0.15), child: Icon(Icons.person, color: _primaryRed, size: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Bienvenido/a', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text('¡Hola, $nombrePaciente!', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.phone_in_talk, color: Colors.green, size: 26), tooltip: 'Contactar', onPressed: () => _mostrarOpcionesContacto(context, cuidadorConfig?.contactoTelefono)),
          IconButton(icon: const Icon(Icons.settings, color: Colors.black87, size: 26), tooltip: 'Modo Cuidador', onPressed: () => _solicitarPinCuidador(context)),
          const SizedBox(width: 6),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => provider.cargarDatos(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (medicamentosPendientes.isNotEmpty) ...[
                      _buildTarjetaProximaToma(context, medicamentosPendientes.first, provider),
                      const SizedBox(height: 24),
                    ],

                    const Text('Medicamentos Programados', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    if (provider.medicamentos.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24), 
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)), 
                        child: const Center(child: Text('No tienes medicamentos registrados.\nUsa la tuerca ⚙️ (Modo Cuidador) para agregar uno.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 14)))
                      )
                    else if (medicamentosPendientes.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.green.shade200)),
                        child: const Column(
                          children: [
                            Icon(Icons.celebration, color: Colors.green, size: 40),
                            SizedBox(height: 10),
                            Text('¡Felicidades!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                            Text('Ya tomaste todos tus medicamentos de hoy.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black87)),
                          ],
                        ),
                      )
                    else ...[
                      if (manana.isNotEmpty) ...[
                        _buildEncabezadoGrupo(Icons.wb_sunny_outlined, 'Mañana', Colors.orange),
                        ...manana.map((med) => _buildCardMedicamento(context, med, provider)),
                        const SizedBox(height: 10),
                      ],
                      if (tardeNoche.isNotEmpty) ...[
                        _buildEncabezadoGrupo(Icons.nights_stay_outlined, 'Tarde / Noche', Colors.indigo),
                        ...tardeNoche.map((med) => _buildCardMedicamento(context, med, provider)),
                      ]
                    ],

                    const SizedBox(height: 32),

                    const Text('Próximas Citas Médicas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    if (citasPendientes.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
                        child: const Center(
                          child: Text('No tienes citas médicas programadas.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 14))
                        ),
                      )
                    else
                      ...citasPendientes.map((cita) => _buildCardCita(context, cita)),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildEncabezadoGrupo(IconData icono, String titulo, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Row(
        children: [
          Icon(icono, color: color, size: 20),
          const SizedBox(width: 8),
          Text(titulo, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
        ],
      ),
    );
  }

  Widget _buildTarjetaProximaToma(BuildContext context, Medicamento med, AppProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_primaryRed, Colors.red.shade800], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _primaryRed.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('PRÓXIMA TOMA', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), 
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)), 
                child: Text(med.horaProgramada, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(med.nombre, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(med.dosis, style: const TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white, 
                foregroundColor: _primaryRed, 
                padding: const EdgeInsets.symmetric(vertical: 12), 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
              ),
              icon: const Icon(Icons.check_circle),
              label: const Text('MARCAR COMO TOMADO', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () async {
                await provider.registrarTomaMedicamento(med.id!, horaProgramada: med.horaProgramada);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Toma registrada para ${med.nombre}'), backgroundColor: Colors.green));
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardMedicamento(BuildContext context, Medicamento med, AppProvider provider) {
    bool esStockBajo = med.inventarioActual <= med.inventarioAlerta;

    return Card(
      elevation: 0,
      color: esStockBajo ? const Color(0xFFFFEBEE) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14), 
        side: BorderSide(color: esStockBajo ? Colors.red.shade200 : Colors.grey.shade300)
      ),
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: esStockBajo ? Colors.white : Colors.grey.shade100, 
              child: Icon(Icons.medication, color: _primaryRed)
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(med.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                  const SizedBox(height: 2),
                  Text('${med.dosis}\n${med.horaProgramada}', style: TextStyle(color: Colors.red.shade900, fontSize: 13)),
                  if (esStockBajo)
                    Text('Stock bajo: ${med.inventarioActual} pastillas', style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            if (esStockBajo)
              const Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: Icon(Icons.warning_amber_rounded, color: Colors.orange),
              ),
            IconButton(
              icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
              tooltip: 'Registrar toma',
              onPressed: () async {
                await provider.registrarTomaMedicamento(med.id!, horaProgramada: med.horaProgramada);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Toma de ${med.nombre} registrada'), backgroundColor: Colors.green)
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardCita(BuildContext context, dynamic cita) {
    String fechaMostrada = cita.fechaHora;
    try {
      DateTime dt = DateTime.parse(cita.fechaHora);
      String dia = dt.day.toString().padLeft(2, '0');
      String mes = dt.month.toString().padLeft(2, '0');
      String anio = dt.year.toString();
      String hora = dt.hour.toString().padLeft(2, '0');
      String min = dt.minute.toString().padLeft(2, '0');
      fechaMostrada = '$dia/$mes/$anio\n$hora:$min hs';
    } catch (e) {
      fechaMostrada = cita.fechaHora;
    }

    return Card(
      elevation: 0,
      color: Colors.blue.shade50, 
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.blue.shade200),
      ),
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.calendar_month, color: Colors.blue),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cita.medico, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                  const SizedBox(height: 2),
                  Text(cita.titulo, style: TextStyle(color: Colors.blue.shade900, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: Colors.black54),
                      const SizedBox(width: 6),
                      Text(fechaMostrada, style: const TextStyle(color: Colors.black87, fontSize: 13)),
                    ],
                  ),
                  if (cita.lugar.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.black54),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(cita.lugar, style: const TextStyle(color: Colors.black87, fontSize: 13), overflow: TextOverflow.ellipsis, maxLines: 2),
                        ),
                      ],
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}