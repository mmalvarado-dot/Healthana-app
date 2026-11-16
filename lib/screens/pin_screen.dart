import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/app_provider.dart';
import 'ajustes_screen.dart'; // ajustes cuidador
import 'tutorial_cuidador_screen.dart'; // Lo crearemos en el siguiente paso

class PinScreen extends StatefulWidget {
  const PinScreen({super.key});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _isError = false;

  void _verificarPin() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    // Verificamos en la base de datos si el PIN es correcto
    final esValido = await provider.verificarPin(_pinController.text);

    if (esValido) {
      // Leemos las preferencias para saber si es la primera vez que entra al modo cuidador
      final prefs = await SharedPreferences.getInstance();
      final vistoTutorialCuidador = prefs.getBool('vistoTutorialCuidador') ?? false;

      if (!mounted) return;

      if (vistoTutorialCuidador) {
        // SI YA VIO EL TUTORIAL: Vamos a la pantalla de Ajustes directo
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AjustesScreen()),
        );
      } else {
        // SI ES SU PRIMERA VEZ: Vamos al tutorial del Cuidador
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TutorialCuidadorScreen()),
        );
      }
    } else {
      // Si es incorrecto, mostramos el error en rojo
      setState(() {
        _isError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modo Cuidador'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security, size: 80, color: Color(0xFF1885FF)),
            const SizedBox(height: 24),
            const Text(
              'Ingrese su PIN de seguridad',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true, // Oculta los números como contraseña
              textAlign: TextAlign.center,
              maxLength: 4,
              style: const TextStyle(fontSize: 32, letterSpacing: 16),
              decoration: InputDecoration(
                hintText: '****',
                errorText: _isError ? 'PIN incorrecto. Intente de nuevo.' : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onChanged: (value) {
                if (_isError) setState(() => _isError = false);
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1885FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _verificarPin,
                child: const Text(
                  'INGRESAR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}