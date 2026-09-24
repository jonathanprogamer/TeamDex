import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class SeleccionarNivelPage extends StatefulWidget {
  final Widget paginaSiguiente;

  /// Crea la pantalla que solicita el nivel antes de abrir [paginaSiguiente].
  const SeleccionarNivelPage({
    super.key,
    required this.paginaSiguiente,
  });

  /// Crea el estado que conserva el nivel elegido por el usuario.
  @override
  State<SeleccionarNivelPage> createState() =>
      _SeleccionarNivelPageState();
}

class _SeleccionarNivelPageState
    extends State<SeleccionarNivelPage> {
  final DatabaseHelper db = DatabaseHelper.instance;

  String? nivelSeleccionado;

  /// Valida y guarda el nivel, y reemplaza esta pantalla por la siguiente.
  ///
  /// Si no hay una opcion seleccionada, muestra un aviso y no navega. Cuando
  /// se guarda correctamente, usa `pushReplacement` para evitar volver al
  /// selector inicial con el boton de retroceso.
  Future<void> continuar() async {
    if (nivelSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selecciona un nivel de conocimiento.',
          ),
        ),
      );
      return;
    }

    // Guardamos la elección en SQLite.
    await db.guardarNivelConocimiento(
      nivelSeleccionado!,
    );

    if (!mounted) {
      return;
    }

    // Reemplazamos la pantalla actual por Teamdex.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => widget.paginaSiguiente,
      ),
    );
  }

  /// Construye la bienvenida, las opciones de nivel y el boton de comienzo.
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),

                const Icon(
                  Icons.catching_pokemon,
                  size: 100,
                  color: Colors.red,
                ),

                const SizedBox(height: 25),

                const Text(
                  '¡Bienvenido a Teamdex!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'Antes de comenzar, queremos saber '
                  'cuánto conoces sobre Pokémon.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                  ),
                ),

                const SizedBox(height: 35),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '¿Cuál es tu nivel?',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                _construirOpcion(
                  nivel: 'novato',
                  icono: Icons.school,
                  titulo: 'Novato',
                  descripcion:
                      'Soy nuevo en Pokémon y quiero '
                      'explicaciones sencillas.',
                ),

                const SizedBox(height: 15),

                _construirOpcion(
                  nivel: 'experto',
                  icono: Icons.auto_awesome,
                  titulo: 'Experto',
                  descripcion:
                      'Ya conozco Pokémon y quiero '
                      'información más técnica.',
                ),

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: continuar,
                    icon: const Icon(
                      Icons.arrow_forward,
                    ),
                    label: const Text(
                      'Comenzar',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Construye una tarjeta seleccionable para un nivel de conocimiento.
  /// La apariencia indica si [nivel] coincide con la opcion actual.
  Widget _construirOpcion({
    required String nivel,
    required IconData icono,
    required String titulo,
    required String descripcion,
  }) {
    final bool seleccionado =
        nivelSeleccionado == nivel;

    return Card(
      elevation: seleccionado ? 5 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: seleccionado
              ? Colors.red
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          setState(() {
            nivelSeleccionado = nivel;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: seleccionado
                    ? Colors.red
                    : Colors.grey.shade200,
                child: Icon(
                  icono,
                  color: seleccionado
                      ? Colors.white
                      : Colors.grey.shade700,
                  size: 28,
                ),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      descripcion,
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              Icon(
                seleccionado
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: seleccionado
                    ? Colors.red
                    : Colors.grey,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}