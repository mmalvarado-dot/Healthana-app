import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_screen.dart';

class TutorialPacienteScreen extends StatefulWidget {
  const TutorialPacienteScreen({super.key});

  @override
  State<TutorialPacienteScreen> createState() => _TutorialPacienteScreenState();
}

class _TutorialPacienteScreenState extends State<TutorialPacienteScreen> {
  final PageController _pageController = PageController();
  int _paginaActual = 0;

  // Tutorial basado en las 3 pestañas: Inicio, Síntomas e Historial
  final List<Map<String, dynamic>> _paginas = [
    {
      'titulo': 'Inicio:\nTus Medicinas',
      'descripcion': 'Tu próxima medicina aparecerá resaltada en un recuadro rojo. Si la pantalla está vacía, tu cuidador debe usar el ícono de la tuerca ⚙️ para agregar tus recetas.',
      'icono': Icons.home_rounded,
      'color': const Color(0xFFE53935), // Rojo para coincidir con la próxima toma
    },
    {
      'titulo': 'Síntomas:\n¿Cómo te sientes?',
      'descripcion': 'Registra tu estado de ánimo usando las caritas. Si te sientes regular o mal, te pediremos una breve descripción para mantener informado a tu cuidador.',
      'icono': Icons.add_circle_outline_rounded,
      'color': const Color(0xFF1885FF), // Azul
    },
    {
      'titulo': 'Historial:\nTu Progreso',
      'descripcion': 'Revisa el registro completo de todas las medicinas que has tomado y el historial de los síntomas que has guardado con el tiempo.',
      'icono': Icons.history_rounded,
      'color': const Color(0xFF43A047), // Verde
    },
  ];

  void _finalizarTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vistoTutorialPaciente', true);

    if (!mounted) return;
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainScreen()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finalizarTutorial,
                child: const Text(
                  'Omitir',
                  style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _paginaActual = index),
                itemCount: _paginas.length,
                itemBuilder: (context, index) {
                  final pagina = _paginas[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(pagina['icono'], size: 120, color: pagina['color']),
                        const SizedBox(height: 40),
                        Text(
                          pagina['titulo'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, height: 1.2),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          pagina['descripcion'],
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, color: Colors.grey.shade700, height: 1.5),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      _paginas.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        height: 10,
                        width: _paginaActual == index ? 24 : 10,
                        decoration: BoxDecoration(
                          color: _paginaActual == index ? _paginas[index]['color'] : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  FloatingActionButton(
                    backgroundColor: _paginas[_paginaActual]['color'],
                    elevation: 0,
                    onPressed: () {
                      if (_paginaActual == _paginas.length - 1) {
                        _finalizarTutorial();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Icon(
                      _paginaActual == _paginas.length - 1 ? Icons.check : Icons.arrow_forward_ios,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}