import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../services/poke_api_service.dart';

class SeleccionarPokemonPage extends StatefulWidget {
  final int equipoId;

  /// Crea el selector de Pokemon asociado al equipo [equipoId].
  const SeleccionarPokemonPage({
    super.key,
    required this.equipoId,
  });

  /// Crea el estado que administra la lista, el filtro y las selecciones.
  @override
  State<SeleccionarPokemonPage> createState() =>
      _SeleccionarPokemonPageState();
}

class _SeleccionarPokemonPageState
    extends State<SeleccionarPokemonPage> {
  final PokeApiService api = PokeApiService();
  final DatabaseHelper db = DatabaseHelper.instance;

  List<Map<String, dynamic>> pokemons = [];
  List<Map<String, dynamic>> pokemonsFiltrados = [];

  Set<int> pokemonsSeleccionados = {};

  bool cargando = true;
  String textoBusqueda = '';

  /// Inicia la carga de todos los Pokemon y los ya incluidos en el equipo.
  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  /// Obtiene Pokemon desde la API y marca los que ya pertenecen al equipo.
  ///
  /// Si alguna consulta falla, detiene el indicador de carga y muestra un
  /// mensaje de error sin modificar la lista parcialmente.
  Future<void> cargarDatos() async {
    try {
      final datos = await api.obtenerPokemonsPorRegion(
        1,
        1018,
      );

      final datosEquipo =
          await db.obtenerPokemonsDelEquipo(
        widget.equipoId,
      );

      final Set<int> idsSeleccionados = {};

      for (final pokemon in datosEquipo) {
        final id = int.tryParse(
          pokemon['pokemon_id'].toString(),
        );

        if (id != null) {
          idsSeleccionados.add(id);
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        pokemons = datos;
        pokemonsFiltrados = datos;
        pokemonsSeleccionados = idsSeleccionados;
        cargando = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        cargando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudieron cargar los Pokémon.',
          ),
        ),
      );
    }
  }

/// Filtra los Pokemon por nombre o por numero de Pokedex.
///
/// Una busqueda numerica exige coincidencia exacta del ID; una busqueda textual
/// permite coincidencias parciales y no distingue mayusculas de minusculas.
void buscarPokemon(String texto) {
  setState(() {
    textoBusqueda = texto;

    final busqueda = texto.trim().toLowerCase();

    if (busqueda.isEmpty) {
      pokemonsFiltrados = pokemons;
      return;
    }

    final numeroBuscado = int.tryParse(busqueda);

    pokemonsFiltrados = pokemons.where((pokemon) {
      final nombre = pokemon['nombre']
          .toString()
          .toLowerCase();

      final id = int.tryParse(
        pokemon['id'].toString(),
      );

      // Si el usuario escribió un número,
      // buscamos por número de Pokédex.
      if (numeroBuscado != null) {
        return id == numeroBuscado;
      }

      // Si escribió texto, buscamos por nombre.
      return nombre.contains(busqueda);
    }).toList();
  });
}

  /// Agrega un Pokemon al equipo respetando los limites de duplicados y cupo.
  ///
  /// Persiste la relacion en SQLite, actualiza el conjunto de seleccionados y
  /// notifica al usuario cuando la operacion se completa correctamente.
  Future<void> seleccionarPokemon(
    Map<String, dynamic> pokemon,
  ) async {
    final int id = int.parse(
      pokemon['id'].toString(),
    );

    final String nombre =
        pokemon['nombre'].toString();

    final String sprite =
        pokemon['sprite'].toString();

    // Si ya está seleccionado, no hacemos nada.
    if (pokemonsSeleccionados.contains(id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Este Pokémon ya está en tu equipo.',
          ),
        ),
      );
      return;
    }

    // No permitimos más de 6 Pokémon.
    if (pokemonsSeleccionados.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tu equipo ya tiene 6 Pokémon.',
          ),
        ),
      );
      return;
    }

    await db.agregarPokemonAlEquipo(
      widget.equipoId,
      id,
      nombre,
      sprite,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      pokemonsSeleccionados.add(id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${nombre.replaceAll('-', ' ')} fue agregado al equipo.',
        ),
      ),
    );
  }

  /// Construye el buscador, contador de cupo, cuadricula y boton de salida.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Seleccionar Pokémon',
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
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    8,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.groups,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${pokemonsSeleccionados.length} / 6 Pokémon seleccionados',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    12,
                  ),
                  child: TextField(
                    onChanged: buscarPokemon,
                    decoration: InputDecoration(
                      hintText: 'Buscar Pokémon...',
                      prefixIcon: const Icon(
                        Icons.search,
                      ),
                      suffixIcon: textoBusqueda.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                buscarPokemon('');
                              },
                              icon: const Icon(
                                Icons.clear,
                              ),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: pokemonsFiltrados.isEmpty
                      ? const Center(
                          child: Text(
                            'No se encontraron Pokémon.',
                            style: TextStyle(
                              fontSize: 16,
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
                            crossAxisCount: 3,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.78,
                          ),
                          itemCount:
                              pokemonsFiltrados.length,
                          itemBuilder:
                              (context, index) {
                            final pokemon =
                                pokemonsFiltrados[index];

                            final int id = int.parse(
                              pokemon['id'].toString(),
                            );

                            final String nombre =
                                pokemon['nombre']
                                    .toString()
                                    .replaceAll(
                                      '-',
                                      ' ',
                                    );

                            final bool seleccionado =
                                pokemonsSeleccionados
                                    .contains(id);

                            return Card(
                              elevation: 3,
                              color: seleccionado
                                  ? Colors.grey.shade200
                                  : null,
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  18,
                                ),
                              ),
                              child: InkWell(
                                borderRadius:
                                    BorderRadius.circular(
                                  18,
                                ),
                                onTap: () {
                                  seleccionarPokemon(
                                    pokemon,
                                  );
                                },
                                child: Stack(
                                  children: [
                                    Padding(
                                      padding:
                                          const EdgeInsets.all(
                                        8,
                                      ),
                                      child: Column(
                                        children: [
                                          Align(
                                            alignment:
                                                Alignment
                                                    .topLeft,
                                            child: Text(
                                              '#${id.toString().padLeft(3, '0')}',
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
                                          const SizedBox(
                                            height: 5,
                                          ),
                                          Text(
                                            nombre,
                                            textAlign:
                                                TextAlign
                                                    .center,
                                            maxLines: 1,
                                            overflow:
                                                TextOverflow
                                                    .ellipsis,
                                            style:
                                                const TextStyle(
                                              fontSize: 13,
                                              fontWeight:
                                                  FontWeight
                                                      .bold,
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 5,
                                          ),
                                        ],
                                      ),
                                    ),

                                    if (seleccionado)
                                      Positioned(
                                        top: 7,
                                        right: 7,
                                        child: Container(
                                          padding:
                                              const EdgeInsets
                                                  .all(4),
                                          decoration:
                                              const BoxDecoration(
                                            shape:
                                                BoxShape
                                                    .circle,
                                            color:
                                                Colors.green,
                                          ),
                                          child: const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 18,
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
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.check,
                      ),
                      label: const Text(
                        'Terminar selección',
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}