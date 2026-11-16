import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'inicio_screen.dart';
import 'sintomas_screen.dart';
import 'historial_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  final List<Widget> _pantallas = const [
    InicioScreen(),
    SintomasScreen(),
    HistorialScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return Scaffold(
      body: IndexedStack(
        index: provider.pestanaActual,
        children: _pantallas,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: provider.pestanaActual,
        onTap: (index) => provider.cambiarPestana(index),
        selectedItemColor: const Color(0xFF1885FF),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Síntomas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Historial',
          ),
        ],
      ),
    );
  }
}