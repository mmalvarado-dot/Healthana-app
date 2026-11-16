import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/cuidador_model.dart';
import '../models/medicamento_model.dart'; // Importante para usar el tipo Medicamento
import 'agregar_medicamento_screen.dart';
import 'citas_screen.dart'; // NUEVO: Importación de la pantalla de citas

class AjustesScreen extends StatefulWidget {
  const AjustesScreen({super.key});

  @override
  State<AjustesScreen> createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  final _nombreCtrl = TextEditingController();
  final _edadCtrl = TextEditingController();
  final _sangreCtrl = TextEditingController();
  final _contactoNombreCtrl = TextEditingController();
  final _contactoTelCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();

  final _pinActualCtrl = TextEditingController();
  final _nuevoPinCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final config = Provider.of<AppProvider>(context, listen: false).cuidadorConfig;
    if (config != null) {
      _nombreCtrl.text = config.nombrePaciente;
      _edadCtrl.text = config.edadPaciente.toString();
      _sangreCtrl.text = config.tipoSangre;
      _contactoNombreCtrl.text = config.contactoNombre;
      _contactoTelCtrl.text = config.contactoTelefono;
      _notasCtrl.text = config.notasMedicas;
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _edadCtrl.dispose();
    _sangreCtrl.dispose();
    _contactoNombreCtrl.dispose();
    _contactoTelCtrl.dispose();
    _notasCtrl.dispose();
    _pinActualCtrl.dispose();
    _nuevoPinCtrl.dispose();
    super.dispose();
  }

  void _guardarPerfil() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final configActual = provider.cuidadorConfig;
    if (configActual == null) return;

    final nuevaConfig = CuidadorConfig(
      id: configActual.id,
      pinHash: configActual.pinHash,
      nombrePaciente: _nombreCtrl.text,
      edadPaciente: int.tryParse(_edadCtrl.text) ?? 0,
      tipoSangre: _sangreCtrl.text,
      contactoNombre: _contactoNombreCtrl.text,
      contactoTelefono: _contactoTelCtrl.text,
      notasMedicas: _notasCtrl.text,
    );

    await provider.actualizarConfiguracion(nuevaConfig);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado correctamente'), backgroundColor: Colors.green),
      );
    }
  }

  void _cambiarPin() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    
    bool esCorrecto = await provider.verificarPin(_pinActualCtrl.text);
    if (!esCorrecto) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El PIN actual es incorrecto'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    if (_nuevoPinCtrl.text.length != 4) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El nuevo PIN debe tener 4 dígitos'), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    await provider.cambiarPin(_nuevoPinCtrl.text);
    _pinActualCtrl.clear();
    _nuevoPinCtrl.clear();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN de seguridad actualizado'), backgroundColor: Colors.green),
      );
    }
  }

  // NUEVO: Método para confirmar la eliminación de un medicamento
  void _confirmarEliminacion(BuildContext context, Medicamento med) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [Icon(Icons.warning, color: Colors.red), SizedBox(width: 10), Text('Eliminar', style: TextStyle(fontSize: 18))]),
        content: Text('¿Estás seguro de que deseas eliminar permanentemente ${med.nombre}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              // Asegúrate de tener el método eliminarMedicamento en tu AppProvider
              await provider.eliminarMedicamento(med.id!); 
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Medicamento eliminado'), backgroundColor: Colors.red)
                );
              }
            },
            child: const Text('ELIMINAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryRed = Color(0xFFE53935);

    return DefaultTabController(
      length: 4, 
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: primaryRed,
          title: const Text('Modo Cuidador', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            isScrollable: true, // Recomendable para 4 pestañas o más
            tabs: [
              Tab(icon: Icon(Icons.medication), text: 'Recetas'),
              Tab(icon: Icon(Icons.person), text: 'Perfil'),
              Tab(icon: Icon(Icons.security), text: 'Seguridad'),
              Tab(icon: Icon(Icons.event_note), text: 'Citas'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPestanaMedicamentos(primaryRed),
            _buildPestanaPerfil(primaryRed),
            _buildPestanaSeguridad(primaryRed),
            const CitasScreen(),
          ],
        ),
      ),
    );
  }

  Widget _buildPestanaMedicamentos(Color color) {
    final provider = Provider.of<AppProvider>(context);
    final medicamentos = provider.medicamentos;

    return Column(
      children: [
        Expanded(
          child: medicamentos.isEmpty
              ? const Center(child: Text('No hay medicamentos registrados.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: medicamentos.length,
                  itemBuilder: (context, index) {
                    final med = medicamentos[index];
                    final bool alertaStock = med.inventarioActual <= med.inventarioAlerta;
                    
                    // Lee de la base de datos si está activo o pausado
bool estaActivo = med.isActivo; 

                    return Card(
                      color: alertaStock ? Colors.red.shade50 : Colors.white,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            title: Text(med.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            subtitle: Text(
                              '${med.dosis}\nHora: ${med.horaProgramada} | Cada ${med.frecuenciaHoras}h\nStock: ${med.inventarioActual} pastillas',
                              style: const TextStyle(height: 1.4),
                            ),
                            trailing: alertaStock 
                              ? const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 30)
                              : null,
                          ),
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // SECCIÓN IZQUIERDA: Switch Activar/Desactivar
                                Row(
                                  children: [
                                    const Text('Activo:', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold)),
                                    Switch(
  value: estaActivo,
  activeColor: Colors.green,
  onChanged: (valor) {
    // ¡Ahora sí llama a la base de datos para encender o apagar!
    provider.cambiarEstadoMedicamento(med.id!, valor);
  },
),
                                  ],
                                ),
                                // SECCIÓN DERECHA: Botones Editar y Eliminar
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                      tooltip: 'Editar receta',
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            // Se asume que AgregarMedicamentoScreen acepta un medicamento por parámetro para editar
                                            builder: (_) => AgregarMedicamentoScreen(medicamento: med), 
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      tooltip: 'Eliminar receta',
                                      onPressed: () => _confirmarEliminacion(context, med),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('AÑADIR MEDICAMENTO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AgregarMedicamentoScreen()));
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPestanaPerfil(Color color) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Datos del Paciente', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(controller: _nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
          TextField(controller: _edadCtrl, decoration: const InputDecoration(labelText: 'Edad'), keyboardType: TextInputType.number),
          TextField(controller: _sangreCtrl, decoration: const InputDecoration(labelText: 'Tipo de Sangre')),
          const SizedBox(height: 20),
          const Text('Contacto de Emergencia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(controller: _contactoNombreCtrl, decoration: const InputDecoration(labelText: 'Nombre del Contacto')),
          TextField(controller: _contactoTelCtrl, decoration: const InputDecoration(labelText: 'Teléfono (Ej: +593...)'), keyboardType: TextInputType.phone),
          const SizedBox(height: 20),
          const Text('Información Médica', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(controller: _notasCtrl, decoration: const InputDecoration(labelText: 'Notas / Alergias'), maxLines: 3),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: _guardarPerfil,
            child: const Text('GUARDAR CAMBIOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildPestanaSeguridad(Color color) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.lock_outline, size: 60, color: Colors.grey),
          const SizedBox(height: 20),
          const Text('Cambiar PIN de Acceso', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextField(controller: _pinActualCtrl, decoration: const InputDecoration(labelText: 'PIN Actual', border: OutlineInputBorder()), keyboardType: TextInputType.number, obscureText: true, maxLength: 4),
          const SizedBox(height: 10),
          TextField(controller: _nuevoPinCtrl, decoration: const InputDecoration(labelText: 'Nuevo PIN (4 dígitos)', border: OutlineInputBorder()), keyboardType: TextInputType.number, obscureText: true, maxLength: 4),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: _cambiarPin,
            child: const Text('ACTUALIZAR PIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}