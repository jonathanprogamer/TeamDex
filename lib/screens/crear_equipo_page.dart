import 'package:flutter/material.dart';

class CrearEquipoPage extends StatefulWidget {
  /// Crea la pantalla que permite introducir el nombre de un equipo Pokemon.
  const CrearEquipoPage({super.key});

  /// Crea el estado que administra el campo de texto y el formulario.
  @override
  State<CrearEquipoPage> createState() =>
      _CrearEquipoPageState();
}

class _CrearEquipoPageState
    extends State<CrearEquipoPage> {
  final TextEditingController nombreController =
      TextEditingController();

  static const int limiteCaracteres = 20;

  /// Libera el controlador del campo de nombre cuando se cierra la pantalla.
  ///
  /// Esto evita conservar listeners y recursos asociados al [TextField] una
  /// vez que el formulario deja de formar parte del arbol de widgets.
  @override
  void dispose() {
    nombreController.dispose();
    super.dispose();
  }

  /// Valida el nombre escrito y devuelve el resultado a la pantalla anterior.
  ///
  /// El texto se limpia para ignorar espacios al principio y al final. Si queda
  /// vacio, muestra un mensaje y mantiene abierto el formulario. Cuando es
  /// valido, [Navigator.pop] lo devuelve como resultado para que la pantalla
  /// de equipos pueda guardarlo en la base de datos.
  void crearEquipo() {
    String nombre = nombreController.text.trim();

    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Debes escribir un nombre para el equipo.',
          ),
        ),
      );
      return;
    }

    Navigator.pop(context, nombre);
  }

  /// Construye el formulario completo para crear un equipo.
  ///
  /// Incluye el campo limitado a [limiteCaracteres], el contador visual de
  /// caracteres y el boton que ejecuta [crearEquipo] al ser pulsado.
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
          crossAxisAlignment:
              CrossAxisAlignment.start,
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
              maxLength: limiteCaracteres,
              decoration: const InputDecoration(
                labelText: 'Nombre del equipo',
                hintText: 'Ej: Equipo principal',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.groups),
                counterText: '',
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: ValueListenableBuilder<
                  TextEditingValue>(
                valueListenable: nombreController,
                builder: (context, value, child) {
                  return Text(
                    '${value.text.length}/$limiteCaracteres',
                    style: TextStyle(
                      fontSize: 12,
                      color: value.text.length >=
                              limiteCaracteres
                          ? Colors.red
                          : Colors.grey.shade600,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
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