import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ajustes_screen.dart'; 

class TutorialCuidadorScreen extends StatefulWidget {
  const TutorialCuidadorScreen({super.key});

  @override
  State<TutorialCuidadorScreen> createState() => _TutorialCuidadorScreenState();
}

class _TutorialCuidadorScreenState extends State<TutorialCuidadorScreen> {
  final PageController _pageController = PageController();
  int _paginaActual = 0;

  // Tutorial basado en las 4 pestañas del Modo Cuidador
  final List<Map<String, dynamic>> _paginas = [
    {
      'titulo': 'Recetas:\nGestión Médica',
      'descripcion': 'Añade los medicamentos del paciente, configura sus dosis, horarios y mantén el control del inventario de pastillas disponibles.',
      'icono': Icons.medication_rounded,
      'color': const Color(0xFFE53935), // Rojo, alineado con tu AppBar
    },
    {
      'titulo': 'Perfil:\nDatos del Paciente',
      'descripcion': 'Administra la información básica y el perfil del paciente para personalizar su experiencia en la aplicación.',
      'icono': Icons.person_rounded,
      'color': const Color(0xFF1885FF), // Azul
    },
    {
      'titulo': 'Seguridad:\nProtege el Acceso',
      'descripcion': 'Cambia tu PIN de cuidador en cualquier momento. Mantén esta sección protegida para que el paciente no modifique sus alarmas por error.',
      'icono': Icons.security_rounded,
      'color': const Color(0xFF3949AB), // Índigo
    },
    {
      'titulo': 'Citas:\nAgenda Automática',
      'descripcion': 'Programa citas con especialistas. El sistema se encargará de enviar recordatorios automáticos 24 horas y 2 horas antes de cada consulta.',
      'icono': Icons.edit_calendar_rounded,
      'color': const Color(0xFF00897B), // Verde azulado
    },
  ];

  void _finalizarTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vistoTutorialCuidador', true);

    if (!mounted) return;
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AjustesScreen()),
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
      backgroundColor: const Color(0xFFF8F9FA),
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
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: pagina['color'].withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(pagina['icono'], size: 100, color: pagina['color']),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          pagina['titulo'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, height: 1.2, color: Color(0xFF2C3E50)),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          pagina['descripcion'],
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade700, height: 1.5),
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
                        height: 8,
                        width: _paginaActual == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _paginaActual == index ? _paginas[index]['color'] : Colors.grey.shade400,
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