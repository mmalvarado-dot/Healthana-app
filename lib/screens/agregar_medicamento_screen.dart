import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../providers/app_provider.dart';
import '../models/medicamento_model.dart'; 
import '../services/notificaciones_service.dart';

class AgregarMedicamentoScreen extends StatefulWidget {
  final Medicamento? medicamento; // Nulo = Crear | Con valor = Editar

  const AgregarMedicamentoScreen({super.key, this.medicamento});

  @override
  State<AgregarMedicamentoScreen> createState() => _AgregarMedicamentoScreenState();
}

class _AgregarMedicamentoScreenState extends State<AgregarMedicamentoScreen> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _dosisController = TextEditingController();
  final TextEditingController _frecuenciaController = TextEditingController();
  final TextEditingController _inventarioController = TextEditingController();
  final TextEditingController _alertaController = TextEditingController();
  
  TimeOfDay _horaSeleccionada = const TimeOfDay(hour: 8, minute: 0);
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    if (widget.medicamento != null) {
      final med = widget.medicamento!;
      _nombreController.text = med.nombre;
      _dosisController.text = med.dosis;
      _frecuenciaController.text = med.frecuenciaHoras.toString();
      _inventarioController.text = med.inventarioActual.toString();
      _alertaController.text = med.inventarioAlerta.toString();
      
      _horaSeleccionada = _recuperarHora(med.horaProgramada);
    }
  }

  TimeOfDay _recuperarHora(String horaString) {
    try {
      final tieneAM = horaString.toUpperCase().contains('AM');
      final tienePM = horaString.toUpperCase().contains('PM');
      final textoLimpio = horaString.replaceAll(RegExp(r'[^0-9:]'), '');
      final partes = textoLimpio.split(':');
      
      int hora = int.parse(partes[0]);
      final int minuto = int.parse(partes[1]);
      
      if (tienePM && hora < 12) hora += 12; 
      if (tieneAM && hora == 12) hora = 0; 
      
      return TimeOfDay(hour: hora, minute: minuto);
    } catch (e) {
      return const TimeOfDay(hour: 8, minute: 0);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _dosisController.dispose();
    _frecuenciaController.dispose();
    _inventarioController.dispose();
    _alertaController.dispose();
    super.dispose();
  }

  Future<void> _escanearTextoOffline() async {
    final ImagePicker picker = ImagePicker();
    
    try {
      final XFile? foto = await picker.pickImage(source: ImageSource.camera);
      if (foto == null) return; 
      
      setState(() { _isScanning = true; });
      
      final inputImage = InputImage.fromFilePath(foto.path);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      
      String textoExtraido = recognizedText.text;
      await textRecognizer.close();
      
      setState(() { _isScanning = false; });
      
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Texto Encontrado', style: TextStyle(color: Color(0xFFD32F2F))),
          content: SingleChildScrollView(
            child: SelectableText(
              textoExtraido.isEmpty 
                ? 'No se detectó texto claro en la imagen. Intenta de nuevo con buena luz.' 
                : textoExtraido,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cerrar', style: TextStyle(color: Colors.grey)),
            ),
            if (textoExtraido.isNotEmpty)
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
                onPressed: () {
                  setState(() {
                    _nombreController.text = textoExtraido.split('\n').first;
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('Usar en Nombre', style: TextStyle(color: Colors.white)),
              )
          ],
        ),
      );
    } catch (e) {
      setState(() { _isScanning = false; });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al escanear: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _seleccionarHora() async {
    final TimeOfDay? hora = await showTimePicker(
      context: context,
      initialTime: _horaSeleccionada,
    );
    if (hora != null) {
      setState(() {
        _horaSeleccionada = hora;
      });
    }
  }

  void _guardar() async {
    if (_nombreController.text.trim().isEmpty || 
        _dosisController.text.trim().isEmpty || 
        _frecuenciaController.text.trim().isEmpty ||
        _inventarioController.text.trim().isEmpty ||
        _alertaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, llena todos los campos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final provider = Provider.of<AppProvider>(context, listen: false);
    final horaTexto = _horaSeleccionada.format(context);

    final now = DateTime.now();
    DateTime fechaHoraProgramada = DateTime(
      now.year, now.month, now.day,
      _horaSeleccionada.hour, _horaSeleccionada.minute,
    );

    if (fechaHoraProgramada.isBefore(now)) {
      fechaHoraProgramada = fechaHoraProgramada.add(const Duration(days: 1));
    }

    // --- LÍNEAS DE DEPURACIÓN AGREGADAS AQUÍ ---
    fechaHoraProgramada = fechaHoraProgramada.toLocal();
    print('=======================================');
    print('ALARMA PROGRAMADA PARA: $fechaHoraProgramada');
    print('HORA ACTUAL DEL SISTEMA: ${DateTime.now()}');
    print('=======================================');

    if (widget.medicamento == null) {
      // NUEVO MEDICAMENTO
      final nuevoMedicamento = Medicamento(
        nombre: _nombreController.text.trim(),
        dosis: _dosisController.text.trim(),
        frecuenciaHoras: int.tryParse(_frecuenciaController.text) ?? 24,
        horaProgramada: horaTexto,
        inventarioActual: int.tryParse(_inventarioController.text) ?? 0,
        inventarioAlerta: int.tryParse(_alertaController.text) ?? 0,
        estadoActivo: 1,
      );

      final int idParaAlarma = await provider.agregarMedicamento(nuevoMedicamento);

      // PROGRAMAR ALARMA
      await NotificacionesService.programarAlarmaMedicamento(
        idMedicamento: idParaAlarma,
        nombreMedicamento: nuevoMedicamento.nombre,
        horaProgramada: fechaHoraProgramada,
      );
    } else {
      // EDITAR MEDICAMENTO
      final med = widget.medicamento!;
      final medicamentoEditado = med.copyWith(
        nombre: _nombreController.text.trim(),
        dosis: _dosisController.text.trim(),
        frecuenciaHoras: int.tryParse(_frecuenciaController.text) ?? 24,
        horaProgramada: horaTexto,
        inventarioActual: int.tryParse(_inventarioController.text) ?? 0,
        inventarioAlerta: int.tryParse(_alertaController.text) ?? 0,
      );

      await provider.actualizarMedicamento(medicamentoEditado);

      // CANCELAR Y REPROGRAMAR ALARMA
      if (med.id != null) {
        await NotificacionesService.cancelarAlarmaMedicamento(med.id!);
        await NotificacionesService.programarAlarmaMedicamento(
          idMedicamento: med.id!,
          nombreMedicamento: medicamentoEditado.nombre,
          horaProgramada: fechaHoraProgramada,
        );
      }
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.medicamento == null 
            ? '¡Medicamento guardado con éxito!' 
            : '¡Medicamento actualizado con éxito!'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bool esEdicion = widget.medicamento != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(esEdicion ? 'Editar Medicamento' : 'Nuevo Medicamento', 
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFD32F2F),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isScanning)
              const Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F)))
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Escanear Caja o Receta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  onPressed: _escanearTextoOffline,
                ),
              ),
            
            const SizedBox(height: 25),

            const Text('Nombre del medicamento', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _nombreController,
              decoration: InputDecoration(
                hintText: 'Ej: Paracetamol',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            
            const Text('Dosis', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _dosisController,
              decoration: InputDecoration(
                hintText: 'Ej: 500mg - 1 pastilla',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            
            const Text('Frecuencia (en horas)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _frecuenciaController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Ej: 8',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),

            const Text('Cantidad en caja (Inventario)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _inventarioController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Ej: 30',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),

            const Text('Avisar cuando queden...', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _alertaController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Ej: 5 (Alerta mínima)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),

            const Text('Hora de la primera toma', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _seleccionarHora,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _horaSeleccionada.format(context),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Icon(Icons.access_time, color: Color(0xFFD32F2F)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _guardar,
                child: Text(
                  esEdicion ? 'ACTUALIZAR' : 'GUARDAR',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}