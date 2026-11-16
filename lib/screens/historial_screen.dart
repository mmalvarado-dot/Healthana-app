import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; 
import '../providers/app_provider.dart'; 
import '../models/sintoma_model.dart'; 
import '../services/pdf_service.dart'; // Importante para el PDF

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({Key? key}) : super(key: key);

  @override
  _HistorialScreenState createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppProvider>(context, listen: false).cargarDatos();
    });
  }

  String _formatFecha(String? isoString) {
    if (isoString == null || isoString.isEmpty) return "--/--/----";
    try {
      final date = DateTime.parse(isoString);
      final dia = date.day.toString().padLeft(2, '0');
      final mes = date.month.toString().padLeft(2, '0');
      final hora = date.hour.toString().padLeft(2, '0');
      final min = date.minute.toString().padLeft(2, '0');
      return "$dia/$mes/${date.year}\n$hora:$min";
    } catch (e) {
      return isoString.split('T').first;
    }
  }

  String _getGravedad(int caritaId) {
    switch (caritaId) {
      case 1: return "Grave";
      case 2: return "Moderado";
      case 3: return "Leve";
      case 4: return "Bien";
      case 5: return "Excelente";
      default: return "Registrado";
    }
  }

  void _mostrarOpcionesContacto(String telefono) {
    // Validación: Si no hay teléfono, muestra un mensaje de alerta y no abre el menú
    if (telefono.isEmpty || telefono == "--" || telefono == "Sin registrar") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Aún no has registrado el número de teléfono del contacto de emergencia."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFFF0EC), 
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Contactar cuidador',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.phone, color: Color(0xFF42A5F5)), 
                title: const Text(
                  'Llamada telefónica',
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final Uri url = Uri.parse('tel:$telefono');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.message, color: Color(0xFF4CAF50)), 
                title: const Text(
                  'Mensaje por WhatsApp',
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final numero = telefono.replaceAll(RegExp(r'[^0-9]'), '');
                  final Uri url = Uri.parse('https://wa.me/$numero');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final config = provider.cuidadorConfig;

    final tomas = provider.historialTomas;
    int totalTomas = tomas.length;
    int tomasATiempo = tomas.where((t) => t['estado'] == 'TOMADO_A_TIEMPO').length;
    String adherencia = totalTomas == 0 
        ? "100%" 
        : "${((tomasATiempo / totalTomas) * 100).toInt()}%";

    final sintomas = provider.sintomas;
    final diasUnicos = sintomas.map((s) => s.fechaHora.split('T').first).toSet().length;
    String diasSintomasText = diasUnicos.toString();

    final retrasos = tomas.where((t) => t['estado'] != 'TOMADO_A_TIEMPO').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F9),
      body: SafeArea(
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.red))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopBar(provider),
                    const SizedBox(height: 20),
                    _buildHeaderTitle(),
                    const SizedBox(height: 20),
                    
                    _buildPatientInfoCard(config),
                    const SizedBox(height: 20),
                    
                    _buildSectionTitle("CONTACTO DE EMERGENCIA"),
                    _buildEmergencyContactCard(config),
                    const SizedBox(height: 20),
                    
                    _buildSectionTitle("INFORMACIÓN MÉDICA"),
                    _buildMedicalInfoCard(config),
                    const SizedBox(height: 20),
                    
                    _buildSectionTitle("RESUMEN ESTADÍSTICO"),
                    _buildStatisticsStats(adherencia, diasSintomasText, diasUnicos),
                    const SizedBox(height: 20),
                    
                    _buildSectionTitle("RETRASOS EN MEDICACIÓN"),
                    _buildMedicationDelays(retrasos),
                    const SizedBox(height: 20),
                    
                    _buildSectionTitle("SÍNTOMAS REGISTRADOS"),
                    _buildSymptomsList(sintomas),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTopBar(AppProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: const [
              Icon(Icons.medical_information_outlined, color: Color(0xFFA020F0), size: 18),
              SizedBox(width: 8),
              Text("HISTORIAL CLÍNICO", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            // Se usa el nuevo PdfService en lugar del método obsoleto en AppProvider
            PdfService.generarYCompartirPDF(
              config: provider.cuidadorConfig,
              historialTomas: provider.historialTomas,
              sintomas: provider.sintomas,
              context: context,
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: const [
                Icon(Icons.picture_as_pdf, color: Colors.red, size: 18),
                SizedBox(width: 8),
                Text("Exportar PDF", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderTitle() {
    const meses = ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"];
    final now = DateTime.now();
    // Cálculo del mes actual corregido (restamos 1 porque los arrays empiezan en 0)
    final mesActual = "${meses[now.month - 1]} ${now.year}";

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("HELTHANA", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF333333))),
            Text("REPORTE CLÍNICO MENSUAL", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(mesActual, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
            const Text("ID: 22839-A", style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  Widget _buildPatientInfoCard(dynamic config) {
    return _buildCardContainer(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabelText("PACIENTE"),
              Text(config?.nombrePaciente?.isNotEmpty == true ? config!.nombrePaciente! : "Sin registrar", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildLabelText("MÉDICO TRATANTE"),
              Row(
                children: const [
                  Icon(Icons.circle, size: 8, color: Colors.grey),
                  SizedBox(width: 4),
                  Text("Sin registrar", style: TextStyle(fontSize: 14, color: Colors.black87)),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabelText("EDAD"),
              Text(config?.edadPaciente != null && config!.edadPaciente! > 0 ? "${config.edadPaciente} años" : "--", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildLabelText("TIPO DE SANGRE"),
              Row(
                children: [
                  const Icon(Icons.bloodtype, size: 16, color: Colors.red),
                  const SizedBox(width: 4),
                  Text(config?.tipoSangre?.isNotEmpty == true ? config!.tipoSangre! : "--", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactCard(dynamic config) {
    return _buildCardContainer(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabelText("NOMBRE DEL CONTACTO"),
              Text(config?.contactoNombre?.isNotEmpty == true ? config!.contactoNombre! : "Sin registrar", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildLabelText("TELÉFONO"),
              Text(config?.contactoTelefono?.isNotEmpty == true ? config!.contactoTelefono! : "--", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF5A4036))),
            ],
          ),
          GestureDetector(
            onTap: () => _mostrarOpcionesContacto(config?.contactoTelefono ?? ""),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.call, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalInfoCard(dynamic config) {
    return _buildCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange),
              const SizedBox(width: 6),
              _buildLabelText("NOTAS / ALERGIAS"),
            ],
          ),
          const SizedBox(height: 8),
          Text(config?.notasMedicas?.isNotEmpty == true ? config!.notasMedicas! : "Sin notas registradas.", style: const TextStyle(fontSize: 15, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildStatisticsStats(String adherencia, String diasSintomas, int diasUnicos) {
    String estadoSintomas = diasUnicos == 0 ? "Óptimo" : diasUnicos < 3 ? "Regular" : "Alerta";
    Color colorSintomas = diasUnicos == 0 ? Colors.green : diasUnicos < 3 ? Colors.orange : Colors.red;

    return Row(
      children: [
        Expanded(
          child: _buildCardContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabelText("ADHERENCIA MED"),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(adherencia, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                      child: const Icon(Icons.trending_up, color: Colors.red, size: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildCardContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabelText("DÍAS CON SÍNTOMAS"),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(diasSintomas, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: colorSintomas.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Text(estadoSintomas, style: TextStyle(color: colorSintomas, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMedicationDelays(List retrasos) {
    if (retrasos.isEmpty) {
      return _buildTableContainer(
        header: const ["FECHA", "MEDICACIÓN", "HORARIOS / ESTADO"],
        content: _buildEmptyState(
          icon: Icons.check_circle_outline,
          iconColor: Colors.teal,
          message: "Sin retrasos registrados en la medicación este mes.",
        ),
      );
    }

    return _buildTableContainer(
      header: const ["FECHA", "MEDICACIÓN", "ESTADO"],
      content: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: retrasos.length,
        separatorBuilder: (_, __) => const Divider(color: Color(0xFFEEEEEE), height: 24),
        itemBuilder: (context, index) {
          final item = retrasos[index];
          return Row(
            children: [
              Expanded(child: Text(_formatFecha(item['fecha_hora_real']), style: const TextStyle(fontSize: 11, color: Colors.black87), textAlign: TextAlign.center)),
              Expanded(
                child: Column(
                  children: [
                    Text(item['nombre'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    Text(item['dosis'] ?? '', style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
                  ],
                ),
              ),
              Expanded(
                child: Text(
                  (item['estado'] ?? '').toString().replaceAll('_', ' '), 
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange), 
                  textAlign: TextAlign.center
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSymptomsList(List sintomas) {
    if (sintomas.isEmpty) {
      return _buildTableContainer(
        header: const ["FECHA", "SÍNTOMA", "GRAVEDAD / NOTA"],
        content: _buildEmptyState(
          icon: Icons.health_and_safety_outlined,
          iconColor: Colors.red,
          message: "Sin síntomas de cuidado registrados este\nmes.",
        ),
      );
    }

    return _buildTableContainer(
      header: const ["FECHA", "SÍNTOMA", "NOTA"],
      content: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sintomas.length,
        separatorBuilder: (_, __) => const Divider(color: Color(0xFFEEEEEE), height: 24),
        itemBuilder: (context, index) {
          final item = sintomas[index];
          return Row(
            children: [
              Expanded(flex: 2, child: Text(_formatFecha(item.fechaHora), style: const TextStyle(fontSize: 11, color: Colors.black87), textAlign: TextAlign.center)),
              Expanded(flex: 2, child: Text(_getGravedad(item.caritaId), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
              Expanded(flex: 3, child: Text(item.transcripcionTexto ?? 'Sin nota de voz', style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.grey), textAlign: TextAlign.center)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
    );
  }

  Widget _buildLabelText(String text) {
    return Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey));
  }

  Widget _buildCardContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }

  Widget _buildTableContainer({required List<String> header, required Widget content}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: header.map((t) => Expanded(
                child: Text(t, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black54), textAlign: TextAlign.center),
              )).toList(),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          Padding(padding: const EdgeInsets.all(16.0), child: content),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required Color iconColor, required String message}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.grey)),
        ],
      ),
    );
  }
}