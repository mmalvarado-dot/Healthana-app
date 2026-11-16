import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../providers/app_provider.dart';

class SintomasScreen extends StatefulWidget {
  const SintomasScreen({super.key});

  @override
  State<SintomasScreen> createState() => _SintomasScreenState();
}

class _SintomasScreenState extends State<SintomasScreen> {
  int? _caritaSeleccionada;
  final TextEditingController _notaController = TextEditingController();

  // Variables para la dictación por voz
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechAvailable = false;

  // Lista de caritas (CORREGIDO: tipo genérico completo)
  final List<Map<String, dynamic>> _caritas = [
    {'id': 1, 'emoji': '🤩', 'label': 'Muy bien', 'color': const Color(0xFF00897B)},
    {'id': 2, 'emoji': '🙂', 'label': 'Bien', 'color': const Color(0xFFC2185B)},
    {'id': 3, 'emoji': '😐', 'label': 'Regular', 'color': const Color(0xFFD84315)},
    {'id': 4, 'emoji': '🤒', 'label': 'Mal', 'color': const Color(0xFFD84315)},
    {'id': 5, 'emoji': '😫', 'label': 'Muy mal', 'color': const Color(0xFFB71C1C)},
  ];

  // Lista de atajos rápidos
  final List<String> _atajos = [
    'Buen ánimo',
    'Sin dolor',
    'Cansancio leve',
    'Dolor de cabeza',
  ];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _isListening = false);
        }
      },
      onError: (error) {
        if (mounted) setState(() => _isListening = false);
      },
    );
    if (mounted) setState(() {});
  }

  Future<void> _toggleEscuchar() async {
    if (!_speechAvailable) {
      // Intenta inicializar nuevamente si falló al inicio
      await _initSpeech();
      if (!_speechAvailable) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El micrófono no está disponible. Revisa los permisos de la app.'),
          ),
        );
        return;
      }
    }

    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (val) {
          if (!mounted) return;
          setState(() {
            // Reemplaza el texto con lo que va escuchando
            _notaController.text = val.recognizedWords;
            _notaController.selection = TextSelection.fromPosition(
              TextPosition(offset: _notaController.text.length),
            );
          });
        },
        localeId: 'es_ES',
      );
    }
  }

  void _agregarAtajo(String atajo) {
    setState(() {
      final textoActual = _notaController.text.trim();
      if (textoActual.isEmpty) {
        _notaController.text = atajo;
      } else {
        _notaController.text = '$textoActual, $atajo';
      }
      // Mueve el cursor al final
      _notaController.selection = TextSelection.fromPosition(
        TextPosition(offset: _notaController.text.length),
      );
    });
  }

  bool get _esValido {
    if (_caritaSeleccionada == null) return false;
    if (_caritaSeleccionada! >= 3 && _notaController.text.trim().isEmpty) {
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    _speech.stop();
    _notaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final esDetalleObligatorio =
        _caritaSeleccionada != null && _caritaSeleccionada! >= 3;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F9),
      appBar: AppBar(
        title: const Text(
          '¿Cómo te sientes hoy?',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 24,
            color: Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Selecciona una carita:',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF475569),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),

              // Fila de Emojis
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _caritas.map((carita) {
                  // Casteo explícito para evitar errores del editor
                  final int id = carita['id'] as int;
                  final Color colorCarita = carita['color'] as Color;
                  final String emoji = carita['emoji'] as String;
                  final String label = carita['label'] as String;

                  final isSelected = _caritaSeleccionada == id;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _caritaSeleccionada = id;
                      });
                    },
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 60,
                          height: 85,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFC2185B)
                                  : Colors.grey.shade200,
                              width: isSelected ? 2.5 : 1.5,
                            ),
                            boxShadow: [
                              if (!isSelected)
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(emoji, style: const TextStyle(fontSize: 28)),
                              const SizedBox(height: 4),
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: colorCarita,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Círculo de selección debajo de la carita
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? const Color(0xFFC2185B)
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFC2185B)
                                  : Colors.grey.shade400,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, size: 14, color: Colors.white)
                              : null,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Título de la caja de texto
              RichText(
                text: TextSpan(
                  text: esDetalleObligatorio
                      ? 'Escribe o dicta el motivo '
                      : '¿Quieres añadir un detalle? ',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  children: [
                    TextSpan(
                      text: esDetalleObligatorio ? '(Obligatorio)' : '(Opcional)',
                      style: const TextStyle(
                        fontWeight: FontWeight.normal,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Caja de texto
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F3), // Fondo rosado muy suave
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: esDetalleObligatorio && _notaController.text.trim().isEmpty
                        ? Colors.red.shade400
                        : const Color(0xFFFFD1DC), // Borde rosado
                    width: 1.5,
                  ),
                ),
                child: TextField(
                  controller: _notaController,
                  maxLines: 4,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Ej: Me siento con buena energía...',
                    hintStyle: TextStyle(color: Colors.black54),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Botón de Micrófono (Estilo píldora)
              Center(
                child: GestureDetector(
                  onTap: _toggleEscuchar,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: const Color(0xFFFFD1DC), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.pink.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: const Color(0xFFC2185B),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isListening ? 'Escuchando...' : 'Presiona para hablar',
                          style: const TextStyle(
                            color: Color(0xFFC2185B),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Atajos rápidos
              const Text(
                'ATAJOS RÁPIDOS:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _atajos.map((atajo) {
                  return GestureDetector(
                    onTap: () => _agregarAtajo(atajo),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        '+ $atajo',
                        style: const TextStyle(
                          color: Color(0xFF334155),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 40),

              // Botón Guardar
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC2185B),
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _esValido
                      ? () async {
                          await provider.guardarSintoma(
                            caritaId: _caritaSeleccionada!,
                            transcripcion: _notaController.text,
                          );

                          if (!mounted) return;

                          setState(() {
                            _caritaSeleccionada = null;
                            _notaController.clear();
                          });

                          provider.cambiarPestana(0);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('¡Registro guardado con éxito!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      : null,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'GUARDAR REGISTRO',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.check, color: Colors.white),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Texto del pie de página
              const Center(
                child: Text(
                  'Tus cuidadores y doctores podrán ver este informe.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}