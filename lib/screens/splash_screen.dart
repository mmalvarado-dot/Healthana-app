import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_screen.dart';
import 'tutorial_paciente_screen.dart'; // Lo crearemos en el siguiente paso

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    // Animación continua para el efecto de carga de los puntos
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    // Iniciamos la lógica para saber a dónde ir después del splash
    _iniciarNavegacion();
  }

  Future<void> _iniciarNavegacion() async {
    // Esperamos 3 segundos para mostrar tu hermoso diseño
    await Future.delayed(const Duration(seconds: 3));
    
    if (!mounted) return;

    // Leemos las preferencias para saber si es la primera vez
    final prefs = await SharedPreferences.getInstance();
    final vistoTutorialPaciente = prefs.getBool('vistoTutorialPaciente') ?? false;

    if (vistoTutorialPaciente) {
      // Si ya lo vio, va directo a la pantalla principal
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else {
      // Si es la primera vez, va al tutorial del paciente
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const TutorialPacienteScreen()),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedDot(double delay) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _animationController,
        curve: Interval(delay, 1.0, curve: Curves.easeInOut),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE53935),
              Color(0xFFB71C1C),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            // Bloque del Logo alineado a la derecha
            IntrinsicWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Text(
                    'HEALTHANA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.8,
                    ),
                  ),
                  SizedBox(height: 0),
                  Text(
                    'Ama la vida..',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontStyle: FontStyle.italic,
                      fontFamily: 'serif',
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Indicador de carga con animación pulsante
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAnimatedDot(0.0),
                _buildAnimatedDot(0.3),
                _buildAnimatedDot(0.6),
              ],
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}