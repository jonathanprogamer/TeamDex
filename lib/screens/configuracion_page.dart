import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class ConfiguracionPage extends StatefulWidget {
  /// Crea la pantalla que permite cambiar el nivel de conocimiento del usuario.
  const ConfiguracionPage({super.key});

  /// Crea el objeto de estado que mantiene la seleccion y el estado de carga.
  @override
  State<ConfiguracionPage> createState() =>
      _ConfiguracionPageState();
}

class _ConfiguracionPageState
    extends State<ConfiguracionPage> {
  final DatabaseHelper db = DatabaseHelper.instance;

  String nivelSeleccionado = 'novato';
  bool cargando = true;

  /// Inicializa el estado y solicita el nivel guardado en SQLite antes de
  /// mostrar las opciones disponibles.
  @override
  void initState() {
    super.initState();
    cargarConfiguracion();
  }

  /// Consulta el nivel de conocimiento persistido mediante [DatabaseHelper].
  /// Cuando termina, actualiza la opcion seleccionada y oculta el indicador de
  /// carga. Comprueba [mounted] antes de llamar a [setState] porque la consulta
  /// se ejecuta de forma asincrona y la pantalla podria haberse cerrado.
  Future<void> cargarConfiguracion() async {
    final nivel = await db.obtenerNivelConocimiento();

    if (!mounted) {
      return;
    }

    setState(() {
      nivelSeleccionado = nivel;
      cargando = false;
    });
  }

  /// Persiste el nivel seleccionado, actualiza la opcion marcada y muestra una
  /// notificacion indicando si se activo el modo Novato o el modo Experto.
  /// La comprobacion de [mounted] evita actualizar una pantalla que ya no esta
  /// conectada al arbol de widgets despues de guardar los datos.
  Future<void> cambiarNivel(String nivel) async {
    await db.guardarNivelConocimiento(nivel);

    if (!mounted) {
      return;
    }

    setState(() {
      nivelSeleccionado = nivel;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          nivel == 'novato'
              ? 'Modo Novato activado.'
              : 'Modo Experto activado.',
        ),
      ),
    );
  }

  /// Construye el [Scaffold] de configuracion, incluido el indicador de carga,
  /// el texto informativo, las dos opciones de nivel y el resumen del modo
  /// actualmente activo.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Configuración',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: cargando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nivel de conocimiento',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Selecciona cómo quieres que Teamdex '
                    'muestre la información de los Pokémon.',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 25),

                  // NOVATO
                  _construirOpcion(
                    nivel: 'novato',
                    icono: Icons.school,
                    titulo: 'Novato',
                    descripcion:
                        'Explicaciones sencillas y amigables '
                        'para quienes están comenzando.',
                  ),

                  const SizedBox(height: 15),

                  // EXPERTO
                  _construirOpcion(
                    nivel: 'experto',
                    icono: Icons.auto_awesome,
                    titulo: 'Experto',
                    descripcion:
                        'Información más técnica y detallada '
                        'para jugadores con experiencia.',
                  ),

                  const SizedBox(height: 30),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(16),
                      color: Colors.grey.shade100,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            nivelSeleccionado == 'novato'
                                ? 'Actualmente estás usando el '
                                  'modo Novato.'
                                : 'Actualmente estás usando el '
                                  'modo Experto.',
                            style: const TextStyle(
                              fontSize: 15,
                            ),
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

  /// Construye la tarjeta visual de un nivel de conocimiento.
  ///
  /// La tarjeta cambia su borde, color, icono y elevacion cuando [nivel] es el
  /// nivel seleccionado. Al tocarla, guarda ese nivel mediante [cambiarNivel].
  Widget _construirOpcion({
    required String nivel,
    required IconData icono,
    required String titulo,
    required String descripcion,
  }) {
    final bool seleccionado =
        nivelSeleccionado == nivel;

    return Card(
      elevation: seleccionado ? 4 : 2,
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
          cambiarNivel(nivel);
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