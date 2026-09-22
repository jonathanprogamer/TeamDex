import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'crear_equipo_page.dart';
import 'equipo_detalle_page.dart';

class EquiposPage extends StatefulWidget {
  const EquiposPage({super.key});

  @override
  State<EquiposPage> createState() => _EquiposPageState();
}

class _EquiposPageState extends State<EquiposPage> {
  final DatabaseHelper db = DatabaseHelper.instance;

  List<Map<String, dynamic>> equipos = [];

  @override
  void initState() {
    super.initState();
    cargarEquipos();
  }

  Future<void> cargarEquipos() async {
    final datos = await db.obtenerEquipos();

    if (!mounted) {
      return;
    }

    setState(() {
      equipos = datos;
    });
  }

  Future<void> crearEquipo() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CrearEquipoPage(),
      ),
    );

    if (resultado != null) {
      await db.insertarEquipo(resultado);
      await cargarEquipos();
    }
  }

  Future<void> editarEquipo(int index) async {
    String nuevoNombre = equipos[index]['nombre'];

    final resultado = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar equipo'),
          content: TextFormField(
            initialValue: equipos[index]['nombre'],
            onChanged: (valor) {
              nuevoNombre = valor;
            },
            decoration: const InputDecoration(
              labelText: 'Nombre del equipo',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final nombre = nuevoNombre.trim();

                if (nombre.isNotEmpty) {
                  Navigator.pop(context, nombre);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (resultado != null) {
      final id = equipos[index]['id'];

      await db.actualizarEquipo(
        id,
        resultado,
      );

      await cargarEquipos();
    }
  }

  Future<void> eliminarEquipo(int index) async {
    final nombreEquipo = equipos[index]['nombre'];

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar equipo'),
          content: Text(
            '¿Estás seguro de que quieres eliminar "$nombreEquipo"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      final id = equipos[index]['id'];

      await db.eliminarEquipo(id);

      await cargarEquipos();
    }
  }

  Future<void> abrirEquipo(int index) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EquipoDetallePage(
          equipoId: equipos[index]['id'],
          nombreEquipo: equipos[index]['nombre'],
        ),
      ),
    );

    await cargarEquipos();
  }

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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.groups,
              size: 80,
              color: Colors.red,
            ),

            const SizedBox(height: 15),

            const Text(
              'Mis equipos Pokémon',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: equipos.isEmpty
                  ? const Center(
                      child: Text(
                        'Todavía no tienes equipos creados.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: equipos.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: const EdgeInsets.only(
                            bottom: 12,
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(
                                Icons.catching_pokemon,
                              ),
                            ),

                            title: Text(
                              equipos[index]['nombre'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            subtitle: const Text(
                              'Equipo Pokémon',
                            ),

                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    editarEquipo(index);
                                  },
                                  icon: const Icon(
                                    Icons.edit,
                                  ),
                                  tooltip: 'Editar',
                                ),

                                IconButton(
                                  onPressed: () {
                                    eliminarEquipo(index);
                                  },
                                  icon: const Icon(
                                    Icons.delete,
                                  ),
                                  tooltip: 'Eliminar',
                                ),
                              ],
                            ),

                            onTap: () {
                              abrirEquipo(index);
                            },
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: crearEquipo,
                icon: const Icon(Icons.add),
                label: const Text(
                  'Crear equipo',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}