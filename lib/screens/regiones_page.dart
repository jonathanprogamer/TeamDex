import 'package:flutter/material.dart';
import 'pokemon_region_page.dart';
import 'pokemon_favoritos_page.dart';

class RegionesPage extends StatelessWidget {
  /// Crea la pantalla con las regiones y la pestaña de favoritos.
  const RegionesPage({super.key});

  final List<Map<String, dynamic>> regiones = const [
    {
      'nombre': 'Kanto',
      'inicio': 1,
      'cantidad': 151,
    },
    {
      'nombre': 'Johto',
      'inicio': 152,
      'cantidad': 100,
    },
    {
      'nombre': 'Hoenn',
      'inicio': 252,
      'cantidad': 135,
    },
    {
      'nombre': 'Sinnoh',
      'inicio': 387,
      'cantidad': 107,
    },
    {
      'nombre': 'Unova',
      'inicio': 494,
      'cantidad': 156,
    },
    {
      'nombre': 'Kalos',
      'inicio': 650,
      'cantidad': 72,
    },
    {
      'nombre': 'Alola',
      'inicio': 722,
      'cantidad': 88,
    },
    {
      'nombre': 'Galar',
      'inicio': 810,
      'cantidad': 89,
    },
    {
      'nombre': 'Paldea',
      'inicio': 899,
      'cantidad': 120,
    },
  ];

  @override
  /// Construye las pestañas y navega a la lista de Pokemon de cada region.
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Pokémon',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.map),
                text: 'Regiones',
              ),
              Tab(
                icon: Icon(Icons.favorite),
                text: 'Pokes favoritos',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selecciona una región',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Explora los Pokémon disponibles en cada región.',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 25),
                  Expanded(
                    child: ListView.builder(
                      itemCount: regiones.length,
                      itemBuilder: (context, index) {
                        final region = regiones[index];

                        return Card(
                          margin: const EdgeInsets.only(
                            bottom: 12,
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(
                                Icons.map,
                              ),
                            ),
                            title: Text(
                              region['nombre'],
                              style: const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 18,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PokemonRegionPage(
                                    region:
                                        region['nombre'],
                                    inicio:
                                        region['inicio'],
                                    cantidad:
                                        region['cantidad'],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const PokemonFavoritosPage(),
          ],
        ),
      ),
    );
  }
}