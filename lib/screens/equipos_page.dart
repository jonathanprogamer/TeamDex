import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import 'crear_equipo_page.dart';
import 'equipo_detalle_page.dart';

class EquiposPage extends StatefulWidget {
  /// Crea la pantalla que muestra los equipos guardados por el usuario.
  const EquiposPage({super.key});

  /// Crea el estado que carga, muestra y modifica la lista de equipos.
  @override
  State<EquiposPage> createState() => _EquiposPageState();
}

class _EquiposPageState extends State<EquiposPage> {
  final DatabaseHelper db = DatabaseHelper.instance;

  List<Map<String, dynamic>> equipos = [];
  bool cargando = true;

  /// Solicita los equipos guardados cuando la pantalla se monta.
  @override
  void initState() {
    super.initState();
    cargarEquipos();
  }

  /// Consulta SQLite y actualiza la lista visible de equipos.
  ///
  /// Comprueba [mounted] antes de modificar el estado porque la consulta es
  /// asincrona y la pantalla podria haberse cerrado mientras esperaba.
  Future<void> cargarEquipos() async {
    final datos = await db.obtenerEquipos();

    if (!mounted) {
      return;
    }

    setState(() {
      equipos = datos;
      cargando = false;
    });
  }

  // ==========================================================
  // CREAR EQUIPO
  // ==========================================================

  /// Abre el formulario de creacion y guarda el nombre que devuelve.
  ///
  /// Si el usuario cancela, no realiza cambios. Si recibe un nombre valido,
  /// lo inserta en SQLite, recarga la lista y muestra una confirmacion.
  Future<void> abrirCrearEquipo() async {
    final String? nombreEquipo = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const CrearEquipoPage(),
      ),
    );

    // Si el usuario salió de la pantalla sin crear nada,
    // no hacemos nada.
    if (nombreEquipo == null || nombreEquipo.trim().isEmpty) {
      return;
    }

    // Guardamos el nuevo equipo en SQLite.
    await db.insertarEquipo(
      nombreEquipo.trim(),
    );

    // Actualizamos la lista.
    await cargarEquipos();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Equipo "$nombreEquipo" creado correctamente.',
        ),
      ),
    );
  }

  // ==========================================================
  // ABRIR EQUIPO
  // ==========================================================

  /// Abre el detalle del equipo seleccionado y refresca la lista al regresar.
  Future<void> abrirEquipo(
    int equipoId,
    String nombreEquipo,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EquipoDetallePage(
          equipoId: equipoId,
          nombreEquipo: nombreEquipo,
        ),
      ),
    );

    await cargarEquipos();
  }

  // ==========================================================
  // ELIMINAR EQUIPO
  // ==========================================================

  /// Solicita confirmacion, elimina el equipo y actualiza la pantalla.
  ///
  /// Al eliminar el equipo tambien se eliminan sus relaciones de Pokemon por
  /// la regla de cascada definida en la base de datos.
  Future<void> eliminarEquipo(
    int equipoId,
    String nombre,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Eliminar equipo',
          ),
          content: Text(
            '¿Seguro que quieres eliminar el equipo "$nombre"?\n\n'
            'También se eliminarán los Pokémon que tenga dentro.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'Cancelar',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                'Eliminar',
              ),
            ),
          ],
        );
      },
    );

    if (confirmar != true) {
      return;
    }

    await db.eliminarEquipo(
      equipoId,
    );

    if (!mounted) {
      return;
    }

    await cargarEquipos();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Equipo eliminado.',
        ),
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  /// Construye la lista de equipos, el estado vacio y el boton de creacion.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mis equipos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      // ======================================================
      // BOTÓN CREAR EQUIPO
      // ======================================================

      floatingActionButton: FloatingActionButton.extended(
        onPressed: abrirCrearEquipo,
        icon: const Icon(
          Icons.add,
        ),
        label: const Text(
          'Crear equipo',
        ),
      ),

      // ======================================================
      // CONTENIDO
      // ======================================================

      body: cargando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : equipos.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.groups_outlined,
                          size: 90,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        const Text(
                          'No tienes equipos todavía',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Text(
                          'Crea tu primer equipo Pokémon para comenzar.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(
                          height: 25,
                        ),
                        ElevatedButton.icon(
                          onPressed: abrirCrearEquipo,
                          icon: const Icon(
                            Icons.add,
                          ),
                          label: const Text(
                            'Crear equipo',
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    100,
                  ),
                  itemCount: equipos.length,
                  itemBuilder: (context, index) {
                    final equipo = equipos[index];

                    final int equipoId =
                        equipo['id'] as int;

                    final String nombre =
                        equipo['nombre']?.toString() ??
                            'Equipo sin nombre';

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(
                        bottom: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        leading: const CircleAvatar(
                          radius: 25,
                          child: Icon(
                            Icons.groups,
                            size: 28,
                          ),
                        ),
                        title: Text(
                          nombre,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: const Text(
                          'Toca para ver el equipo',
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                          ),
                          tooltip: 'Eliminar equipo',
                          onPressed: () {
                            eliminarEquipo(
                              equipoId,
                              nombre,
                            );
                          },
                        ),
                        onTap: () {
                          abrirEquipo(
                            equipoId,
                            nombre,
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}