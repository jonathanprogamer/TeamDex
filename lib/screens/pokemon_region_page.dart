import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../services/poke_api_service.dart';
import 'pokemon_detail_page.dart';

class PokemonRegionPage extends StatefulWidget {
  final String region;
  final int inicio;
  final int cantidad;

  const PokemonRegionPage({
    super.key,
    required this.region,
    required this.inicio,
    required this.cantidad,
  });

  @override
  State<PokemonRegionPage> createState() => _PokemonRegionPageState();
}

class _PokemonRegionPageState extends State<PokemonRegionPage> {
  final PokeApiService api = PokeApiService();
  final DatabaseHelper db = DatabaseHelper.instance;

  List<Map<String, dynamic>> pokemons = [];
  List<Map<String, dynamic>> pokemonsFiltrados = [];

  Set<int> favoritos = {};

  bool cargando = true;
  String textoBusqueda = '';

  @override
  void initState() {
    super.initState();
    cargarPokemons();
  }

  Future<void> cargarPokemons() async {
    try {
      final datos = await api.obtenerPokemonsPorRegion(
        widget.inicio,
        widget.cantidad,
      );

      final datosFavoritos = await db.obtenerFavoritos();

      final Set<int> idsFavoritos = {};

      for (final favorito in datosFavoritos) {
        final id = int.tryParse(
          favorito['id'].toString(),
        );

        if (id != null) {
          idsFavoritos.add(id);
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        pokemons = datos;
        pokemonsFiltrados = datos;
        favoritos = idsFavoritos;
        cargando = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        cargando = false;
      });
    }
  }

  Future<void> actualizarFavoritos() async {
    final datosFavoritos = await db.obtenerFavoritos();

    final Set<int> idsFavoritos = {};

    for (final favorito in datosFavoritos) {
      final id = int.tryParse(
        favorito['id'].toString(),
      );

      if (id != null) {
        idsFavoritos.add(id);
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      favoritos = idsFavoritos;
    });
  }

  void buscarPokemon(String texto) {
    setState(() {
      textoBusqueda = texto;

      if (texto.trim().isEmpty) {
        pokemonsFiltrados = pokemons;
      } else {
        pokemonsFiltrados = pokemons.where((pokemon) {
          final nombre = pokemon['nombre']
              .toString()
              .toLowerCase();

          return nombre.contains(
            texto.toLowerCase(),
          );
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.region,
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
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    16,
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
                        borderRadius: BorderRadius.circular(15),
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
                          padding: const EdgeInsets.fromLTRB(
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
                          itemCount: pokemonsFiltrados.length,
                          itemBuilder: (context, index) {
                            final pokemon =
                                pokemonsFiltrados[index];

                            final int id = int.parse(
                              pokemon['id'].toString(),
                            );

                            final bool esFavorito =
                                favoritos.contains(id);

                            return Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(18),
                              ),
                              child: InkWell(
                                borderRadius:
                                    BorderRadius.circular(18),
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          PokemonDetailPage(
                                        pokemonId: id,
                                      ),
                                    ),
                                  );

                                  await actualizarFavoritos();
                                },
                                child: Stack(
                                  children: [
                                    Padding(
                                      padding:
                                          const EdgeInsets.all(8),
                                      child: Column(
                                        children: [
                                          Align(
                                            alignment:
                                                Alignment.topLeft,
                                            child: Text(
                                              '#${id.toString().padLeft(3, '0')}',
                                              style:
                                                  const TextStyle(
                                                fontSize: 12,
                                                fontWeight:
                                                    FontWeight.bold,
                                              ),
                                            ),
                                          ),

                                          Expanded(
                                            child: Image.network(
                                              pokemon['sprite'],
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

                                          const SizedBox(height: 5),

                                          Text(
                                            pokemon['nombre']
                                                .toString()
                                                .replaceAll(
                                                  '-',
                                                  ' ',
                                                ),
                                            textAlign:
                                                TextAlign.center,
                                            maxLines: 1,
                                            overflow:
                                                TextOverflow.ellipsis,
                                            style:
                                                const TextStyle(
                                              fontSize: 13,
                                              fontWeight:
                                                  FontWeight.bold,
                                            ),
                                          ),

                                          const SizedBox(height: 5),
                                        ],
                                      ),
                                    ),

                                    // ❤️ CORAZÓN DE FAVORITO
                                    if (esFavorito)
                                      const Positioned(
                                        top: 7,
                                        right: 7,
                                        child: Icon(
                                          Icons.favorite,
                                          color: Colors.red,
                                          size: 24,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}