import 'package:flutter/material.dart';

import 'database/database_helper.dart';
import 'screens/configuracion_page.dart';
import 'screens/equipos_page.dart';
import 'screens/regiones_page.dart';
import 'screens/seleccionar_nivel_page.dart';

/// Punto de entrada de la aplicacion Flutter.
///
/// Inicia el arbol de widgets colocando [PokedexApp] como widget raiz.
void main() {
  runApp(const PokedexApp());
}

class PokedexApp extends StatelessWidget {
  /// Crea el widget raiz que contiene la configuracion general de la app.
  const PokedexApp({super.key});

  /// Construye el [MaterialApp] con el tema global y la primera pantalla.
  ///
  /// Desactiva la etiqueta de depuracion, define el nombre de la aplicacion,
  /// configura el color base y muestra [InicioInicialPage] al iniciar.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Teamdex',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
        ),
        useMaterial3: true,
      ),
      home: const InicioInicialPage(),
    );
  }
}

// ==========================================================
// PANTALLA INICIAL DE COMPROBACIÓN
// ==========================================================

class InicioInicialPage extends StatefulWidget {
  /// Crea la pantalla que decide si debe mostrarse la configuracion inicial.
  const InicioInicialPage({super.key});

  /// Crea el estado encargado de consultar la configuracion persistida.
  @override
  State<InicioInicialPage> createState() => _InicioInicialPageState();
}

class _InicioInicialPageState extends State<InicioInicialPage> {
  final DatabaseHelper db = DatabaseHelper.instance;

  bool cargando = true;
  bool configurado = false;

  /// Inicia la comprobacion de la configuracion una vez creado el estado.
  @override
  void initState() {
    super.initState();
    comprobarConfiguracion();
  }

  /// Consulta en SQLite si el usuario ya completo la configuracion inicial.
  ///
  /// Actualiza [configurado] y [cargando] cuando termina. Comprueba [mounted]
  /// antes de llamar a [setState] porque la consulta es asincrona.
  Future<void> comprobarConfiguracion() async {
    final resultado = await db.configuracionRealizada();

    if (!mounted) {
      return;
    }

    setState(() {
      configurado = resultado;
      cargando = false;
    });
  }

  /// Muestra carga, seleccion de nivel o la pantalla principal segun el estado.
  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!configurado) {
      return const SeleccionarNivelPage(
        paginaSiguiente: InicioPage(),
      );
    }

    return const InicioPage();
  }
}

// ==========================================================
// INICIO DE TEAMDEX
// ==========================================================

class InicioPage extends StatelessWidget {
  /// Crea la pantalla principal con los accesos de la aplicacion.
  const InicioPage({super.key});

  /// Construye la pantalla inicial y sus accesos a configuracion, regiones y equipos.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Teamdex',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Configuración',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ConfiguracionPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.catching_pokemon,
                  size: 110,
                  color: Colors.red,
                ),

                const SizedBox(height: 20),

                const Text(
                  'Mi Pokédex',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Crea y organiza tus equipos Pokémon.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                  ),
                ),

                const SizedBox(height: 40),

                // BOTÓN POKÉMON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegionesPage(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.catching_pokemon,
                    ),
                    label: const Text(
                      'Pokémon',
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // BOTÓN MIS EQUIPOS
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EquiposPage(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.groups,
                    ),
                    label: const Text(
                      'Mis equipos',
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Créditos de la aplicación
          Positioned(
            right: 12,
            bottom: 10,
            child: Text(
              'App creada por Jonathan Julio y Victor Orellana',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}