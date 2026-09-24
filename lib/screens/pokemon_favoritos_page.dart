import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'pokemon_detail_page.dart';

class PokemonFavoritosPage extends StatefulWidget {
  /// Crea la pantalla que muestra los Pokemon marcados como favoritos.
  const PokemonFavoritosPage({super.key});

  /// Crea el estado que carga y actualiza la lista de favoritos.
  @override
  State<PokemonFavoritosPage> createState() =>
      _PokemonFavoritosPageState();
}

class _PokemonFavoritosPageState
    extends State<PokemonFavoritosPage> {
  final DatabaseHelper db = DatabaseHelper.instance;

  List<Map<String, dynamic>> favoritos = [];

  bool cargando = true;

  /// Solicita los favoritos cuando la pantalla se monta.
  @override
  void initState() {
    super.initState();
    cargarFavoritos();
  }

  /// Consulta SQLite y actualiza la cuadricula de Pokemon favoritos.
  /// Comprueba que la pantalla siga montada antes de cambiar su estado.
  Future<void> cargarFavoritos() async {
    final datos = await db.obtenerFavoritos();

    if (!mounted) {
      return;
    }

    setState(() {
      favoritos = datos;
      cargando = false;
    });
  }

  /// Construye el indicador de carga, el estado vacio o la cuadricula.
  @override
  Widget build(BuildContext context) {
    return cargando
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : favoritos.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border,
                        size: 80,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Todavía no tienes Pokémon favoritos.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Agrega Pokémon a favoritos desde sus detalles.',
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
                padding: const EdgeInsets.fromLTRB(
                  12,
                  15,
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
                itemCount: favoritos.length,
                itemBuilder: (context, index) {
                  final pokemon = favoritos[index];

                  final int id = int.parse(
                    pokemon['id'].toString(),
                  );

                  final String nombre = pokemon['nombre']
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

                        await cargarFavoritos();
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
                                  nombre,
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
              );
  }
}