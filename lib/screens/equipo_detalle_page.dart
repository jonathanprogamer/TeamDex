import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import 'detalle_pokemon_equipo_page.dart';
import 'seleccionar_pokemon_page.dart';

class EquipoDetallePage extends StatefulWidget {
  final int equipoId;
  final String nombreEquipo;

  /// Crea el detalle de un equipo usando su ID y nombre para cargarlo.
  const EquipoDetallePage({
    super.key,
    required this.equipoId,
    required this.nombreEquipo,
  });

  /// Crea el estado que administra los Pokemon pertenecientes al equipo.
  @override
  State<EquipoDetallePage> createState() => _EquipoDetallePageState();
}

class _EquipoDetallePageState extends State<EquipoDetallePage> {
  final DatabaseHelper db = DatabaseHelper.instance;

  List<Map<String, dynamic>> pokemons = [];
  bool cargando = true;

  /// Inicia la carga de los Pokemon del equipo al mostrar la pantalla.
  @override
  void initState() {
    super.initState();
    cargarPokemons();
  }

  /// Consulta SQLite y actualiza la lista de Pokemon del equipo.
  Future<void> cargarPokemons() async {
    final datos = await db.obtenerPokemonsDelEquipo(
      widget.equipoId,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      pokemons = datos;
      cargando = false;
    });
  }

  /// Abre el selector de Pokemon si el equipo tiene menos de seis integrantes.
  /// Al volver, recarga la lista para reflejar cualquier Pokemon agregado.
  Future<void> abrirSeleccionPokemon() async {
    if (pokemons.length >= 6) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SeleccionarPokemonPage(
          equipoId: widget.equipoId,
        ),
      ),
    );

    await cargarPokemons();
  }

  /// Abre la configuracion detallada del Pokemon seleccionado.
  /// Al regresar, vuelve a consultar el equipo para mostrar los cambios.
  Future<void> abrirDetallePokemon(
    Map<String, dynamic> pokemon,
  ) async {
    final int pokemonId = int.parse(
      pokemon['pokemon_id'].toString(),
    );

    final String nombre = pokemon['nombre'].toString();
    final String sprite = pokemon['sprite'].toString();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetallePokemonEquipoPage(
          equipoId: widget.equipoId,
          pokemonId: pokemonId,
          nombrePokemon: nombre,
          sprite: sprite,
        ),
      ),
    );

    await cargarPokemons();
  }

  /// Elimina un Pokemon del equipo, recarga la lista y muestra una confirmacion.
  Future<void> eliminarPokemon(
    int pokemonId,
  ) async {
    await db.eliminarPokemonDelEquipo(
      widget.equipoId,
      pokemonId,
    );

    await cargarPokemons();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Pokémon eliminado del equipo.',
        ),
      ),
    );
  }

  /// Muestra un dialogo de confirmacion antes de eliminar un Pokemon.
  /// Solo llama a [eliminarPokemon] si el usuario confirma la accion.
  Future<void> confirmarEliminarPokemon(
    int pokemonId,
    String nombre,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Eliminar Pokémon',
          ),
          content: Text(
            '¿Quieres eliminar a $nombre de este equipo?',
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
            ElevatedButton(
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

    if (confirmar == true) {
      await eliminarPokemon(
        pokemonId,
      );
    }
  }

  /// Construye el encabezado, la cuadricula de Pokemon y sus acciones.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.nombreEquipo,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: cargando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.groups,
                        size: 32,
                        color: Colors.red,
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Text(
                        '${pokemons.length} / 6 Pokémon',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: pokemons.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(30),
                            child: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.catching_pokemon,
                                  size: 80,
                                  color: Colors.grey,
                                ),
                                SizedBox(
                                  height: 20,
                                ),
                                Text(
                                  'Todavía no tienes Pokémon en este equipo.',
                                  textAlign:
                                      TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                Text(
                                  'Agrega Pokémon para comenzar a formar tu equipo.',
                                  textAlign:
                                      TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(
                            12,
                            0,
                            12,
                            20,
                          ),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,

                            // Antes era 1.0.
                            // Ahora las tarjetas son un poco más altas.
                            childAspectRatio: 0.82,
                          ),
                          itemCount: pokemons.length,
                          itemBuilder: (context, index) {
                            final pokemon = pokemons[index];

                            final int pokemonId = int.parse(
                              pokemon['pokemon_id'].toString(),
                            );

                            final String nombre =
                                pokemon['nombre']
                                    .toString()
                                    .replaceAll('-', ' ');

                            return Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(18),
                              ),
                              child: InkWell(
                                borderRadius:
                                    BorderRadius.circular(18),
                                onTap: () {
                                  abrirDetallePokemon(
                                    pokemon,
                                  );
                                },
                                child: Stack(
                                  children: [
                                    Padding(
                                      padding:
                                          const EdgeInsets.all(10),
                                      child: Column(
                                        children: [
                                          Align(
                                            alignment:
                                                Alignment.topLeft,
                                            child: Text(
                                              '#${pokemonId.toString().padLeft(3, '0')}',
                                              style:
                                                  const TextStyle(
                                                fontSize: 12,
                                                fontWeight:
                                                    FontWeight.bold,
                                              ),
                                            ),
                                          ),

                                          // ==========================
                                          // ÁREA DEL SPRITE
                                          // ==========================
                                          Expanded(
                                            child: Center(
                                              child:
                                                  Image.network(
                                                pokemon['sprite'],
                                                width: 115,
                                                height: 115,
                                                fit: BoxFit.contain,
                                                errorBuilder: (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) {
                                                  return const Icon(
                                                    Icons
                                                        .catching_pokemon,
                                                    size: 50,
                                                  );
                                                },
                                              ),
                                            ),
                                          ),

                                          // ==========================
                                          // NOMBRE
                                          // ==========================
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(
                                              bottom: 4,
                                            ),
                                            child: Text(
                                              nombre,
                                              textAlign:
                                                  TextAlign.center,
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow
                                                      .ellipsis,
                                              style:
                                                  const TextStyle(
                                                fontSize: 15,
                                                fontWeight:
                                                    FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // ==========================
                                    // BOTÓN ELIMINAR
                                    // ==========================
                                    Positioned(
                                      top: 5,
                                      right: 5,
                                      child: IconButton(
                                        onPressed: () {
                                          confirmarEliminarPokemon(
                                            pokemonId,
                                            nombre,
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                          size: 22,
                                        ),
                                        tooltip:
                                            'Eliminar del equipo',
                                      ),
                                    ),

                                    // ==========================
                                    // INDICADOR DE CONFIGURACIÓN
                                    // ==========================
                                    Positioned(
                                      bottom: 8,
                                      right: 8,
                                      child: Container(
                                        padding:
                                            const EdgeInsets.all(5),
                                        decoration:
                                            BoxDecoration(
                                          color: Colors.red
                                              .withOpacity(0.9),
                                          shape:
                                              BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.edit,
                                          color: Colors.white,
                                          size: 17,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    10,
                    20,
                    20,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: pokemons.length >= 6
                          ? null
                          : abrirSeleccionPokemon,
                      icon: const Icon(
                        Icons.add,
                      ),
                      label: Text(
                        pokemons.length >= 6
                            ? 'Equipo completo'
                            : 'Agregar Pokémon',
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}