import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'seleccionar_pokemon_page.dart';

class EquipoDetallePage extends StatefulWidget {
  final int equipoId;
  final String nombreEquipo;

  const EquipoDetallePage({
    super.key,
    required this.equipoId,
    required this.nombreEquipo,
  });

  @override
  State<EquipoDetallePage> createState() =>
      _EquipoDetallePageState();
}

class _EquipoDetallePageState
    extends State<EquipoDetallePage> {
  final DatabaseHelper db = DatabaseHelper.instance;

  List<Map<String, dynamic>> pokemons = [];

  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarPokemons();
  }

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

    // Recargamos los Pokémon al volver
    // desde la pantalla de selección.
    await cargarPokemons();
  }

  Future<void> eliminarPokemon(int pokemonId) async {
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
                Navigator.pop(context, false);
              },
              child: const Text(
                'Cancelar',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
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
      await eliminarPokemon(pokemonId);
    }
  }

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
                      const SizedBox(width: 10),
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
                                SizedBox(height: 20),
                                Text(
                                  'Todavía no tienes Pokémon en este equipo.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'Agrega Pokémon para comenzar a formar tu equipo.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : GridView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(
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
                            childAspectRatio: 1.0,
                          ),
                          itemCount: pokemons.length,
                          itemBuilder: (context, index) {
                            final pokemon =
                                pokemons[index];

                            final int pokemonId =
                                int.parse(
                              pokemon['pokemon_id']
                                  .toString(),
                            );

                            final String nombre =
                                pokemon['nombre']
                                    .toString()
                                    .replaceAll(
                                      '-',
                                      ' ',
                                    );

                            return Card(
                              elevation: 3,
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  18,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Padding(
                                    padding:
                                        const EdgeInsets.all(
                                      10,
                                    ),
                                    child: Column(
                                      children: [
                                        Align(
                                          alignment:
                                              Alignment
                                                  .topLeft,
                                          child: Text(
                                            '#${pokemonId.toString().padLeft(3, '0')}',
                                            style:
                                                const TextStyle(
                                              fontSize: 12,
                                              fontWeight:
                                                  FontWeight
                                                      .bold,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child:
                                              Image.network(
                                            pokemon['sprite'],
                                            fit: BoxFit
                                                .contain,
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
                                        Text(
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
                                                FontWeight
                                                    .bold,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 8,
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Botón para eliminar
                                  // el Pokémon del equipo.
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
                                ],
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