import 'package:flutter/material.dart';

class CrearEquipoPage extends StatefulWidget {
  const CrearEquipoPage({super.key});

  @override
  State<CrearEquipoPage> createState() => _CrearEquipoPageState();
}

class _CrearEquipoPageState extends State<CrearEquipoPage> {
  final TextEditingController nombreController = TextEditingController();

  @override
  void dispose() {
    nombreController.dispose();
    super.dispose();
  }

  void crearEquipo() {
    String nombre = nombreController.text.trim();

    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes escribir un nombre para el equipo.'),
        ),
      );
      return;
    }

    Navigator.pop(context, nombre);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Crear equipo',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nuevo equipo',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Escribe un nombre para tu equipo Pokémon.',
              style: TextStyle(
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 30),

            TextField(
              controller: nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre del equipo',
                hintText: 'Ej: Equipo principal',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.groups),
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: crearEquipo,
                icon: const Icon(Icons.check),
                label: const Text('Crear equipo'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}