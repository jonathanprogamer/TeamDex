import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../services/poke_api_service.dart';

class PokemonDetailPage extends StatefulWidget {
  final int pokemonId;

  const PokemonDetailPage({
    super.key,
    required this.pokemonId,
  });

  @override
  State<PokemonDetailPage> createState() => _PokemonDetailPageState();
}

class _PokemonDetailPageState extends State<PokemonDetailPage> {
  final PokeApiService api = PokeApiService();
  final DatabaseHelper db = DatabaseHelper.instance;

  Map<String, dynamic>? pokemon;

  bool cargando = true;
  bool favorito = false;

  @override
  void initState() {
    super.initState();
    cargarDetalles();
  }

  Future<void> cargarDetalles() async {
    try {
      final datos = await api.obtenerDetallesPokemon(
        widget.pokemonId,
      );

      final esFavorito = await db.esFavorito(
        widget.pokemonId,
      );

      setState(() {
        pokemon = datos;
        favorito = esFavorito;
        cargando = false;
      });
    } catch (e) {
      setState(() {
        cargando = false;
      });
    }
  }

  Future<void> cambiarFavorito() async {
    if (pokemon == null) {
      return;
    }

    final id = pokemon!['id'];

    if (favorito) {
      await db.eliminarFavorito(id);

      setState(() {
        favorito = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Pokémon eliminado de favoritos.',
            ),
          ),
        );
      }
    } else {
      final nombre = pokemon!['name'];

      final sprite =
          pokemon!['sprites']['other']['official-artwork']
              ['front_default'] ??
          pokemon!['sprites']['front_default'];

      if (sprite == null) {
        return;
      }

      await db.agregarFavorito(
        id,
        nombre,
        sprite,
      );

      setState(() {
        favorito = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Pokémon agregado a favoritos ❤️',
            ),
          ),
        );
      }
    }
  }

  // ==========================================
  // TRADUCIR NOMBRES
  // ==========================================

  String traducirTipo(String tipo) {
    const tipos = {
      'normal': 'Normal',
      'fire': 'Fuego',
      'water': 'Agua',
      'electric': 'Eléctrico',
      'grass': 'Planta',
      'ice': 'Hielo',
      'fighting': 'Lucha',
      'poison': 'Veneno',
      'ground': 'Tierra',
      'flying': 'Volador',
      'psychic': 'Psíquico',
      'bug': 'Bicho',
      'rock': 'Roca',
      'ghost': 'Fantasma',
      'dragon': 'Dragón',
      'dark': 'Siniestro',
      'steel': 'Acero',
      'fairy': 'Hada',
    };

    return tipos[tipo] ?? tipo;
  }

  String obtenerIconoTipo(String tipo) {
    const iconos = {
      'normal': '⚪',
      'fire': '🔥',
      'water': '💧',
      'electric': '⚡',
      'grass': '🌿',
      'ice': '❄️',
      'fighting': '🥊',
      'poison': '☠️',
      'ground': '🌎',
      'flying': '🪽',
      'psychic': '🔮',
      'bug': '🐛',
      'rock': '🪨',
      'ghost': '👻',
      'dragon': '🐉',
      'dark': '🌑',
      'steel': '⚙️',
      'fairy': '✨',
    };

    return iconos[tipo] ?? '❔';
  }

  String traducirHabilidad(String habilidad) {
    const habilidades = {
      'overgrow': 'Espesura',
      'chlorophyll': 'Clorofila',
      'blaze': 'Mar Llamas',
      'solar-power': 'Poder Solar',
      'torrent': 'Torrente',
      'rain-dish': 'Cura Lluvia',
      'static': 'Electricidad Estática',
      'lightning-rod': 'Pararrayos',
      'run-away': 'Fuga',
      'adaptability': 'Adaptable',
      'anticipation': 'Anticipación',
      'intimidate': 'Intimidación',
      'levitate': 'Levitación',
      'synchronize': 'Sincronía',
      'inner-focus': 'Foco Interno',
      'keen-eye': 'Vista Lince',
      'pressure': 'Presión',
      'swift-swim': 'Nado Rápido',
      'water-absorb': 'Absorbe Agua',
      'volt-absorb': 'Absorbe Electricidad',
      'flame-body': 'Cuerpo Llama',
      'flash-fire': 'Absorbe Fuego',
      'guts': 'Agallas',
      'huge-power': 'Potencia',
      'pure-power': 'Energía Pura',
      'serene-grace': 'Dicha',
      'cute-charm': 'Gran Encanto',
      'compound-eyes': 'Ojo Compuesto',
      'insomnia': 'Insomnio',
      'early-bird': 'Madrugar',
      'sand-veil': 'Velo Arena',
      'snow-cloak': 'Manto Níveo',
      'clear-body': 'Cuerpo Puro',
      'sturdy': 'Robustez',
      'shell-armor': 'Armadura Caparazón',
      'magma-armor': 'Escudo Magma',
      'sticky-hold': 'Viscosidad',
      'own-tempo': 'Ritmo Propio',
      'oblivious': 'Despiste',
      'unaware': 'Ignorante',
      'moxie': 'Autoestima',
      'reckless': 'Audaz',
      'technician': 'Experto',
      'skill-link': 'Encadenado',
      'natural-cure': 'Cura Natural',
      'magic-guard': 'Muro Mágico',
      'multiscale': 'Compensación',
      'regenerator': 'Regeneración',
      'mimicry': 'Mimetismo',
      'protean': 'Mutatipo',
      'libero': 'Líbero',
    };

    return habilidades[habilidad] ?? traducirNombre(habilidad);
  }

  String traducirEstadistica(String estadistica) {
    const estadisticas = {
      'hp': 'PS',
      'attack': 'Ataque',
      'defense': 'Defensa',
      'special-attack': 'At. Esp.',
      'special-defense': 'Def. Esp.',
      'speed': 'Velocidad',
    };

    return estadisticas[estadistica] ?? estadistica;
  }

  String traducirNombre(String nombre) {
    return nombre
        .replaceAll('-', ' ')
        .split(' ')
        .map(
          (palabra) => palabra.isEmpty
              ? ''
              : palabra[0].toUpperCase() +
                  palabra.substring(1),
        )
        .join(' ');
  }

  // ==========================================
  // PANTALLA
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detalles',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!cargando)
            IconButton(
              onPressed: cambiarFavorito,
              icon: Icon(
                favorito
                    ? Icons.favorite
                    : Icons.favorite_border,
              ),
              color: favorito ? Colors.red : null,
              tooltip: favorito
                  ? 'Quitar de favoritos'
                  : 'Agregar a favoritos',
            ),
        ],
      ),
      body: cargando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : pokemon == null
              ? const Center(
                  child: Text(
                    'No se pudo cargar la información.',
                  ),
                )
              : _construirContenido(),
    );
  }

  Widget _construirContenido() {
    final nombre = traducirNombre(
      pokemon!['name'],
    );

    final id = pokemon!['id'];

    final sprite =
        pokemon!['sprites']['other']['official-artwork']
            ['front_default'] ??
        pokemon!['sprites']['front_default'];

    final tipos = pokemon!['types'] as List;
    final habilidades = pokemon!['abilities'] as List;
    final estadisticas = pokemon!['stats'] as List;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            '#${id.toString().padLeft(3, '0')}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            nombre,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          if (sprite != null)
            Image.network(
              sprite,
              height: 220,
              fit: BoxFit.contain,
            ),

          const SizedBox(height: 15),

          // ==========================================
          // TIPOS
          // ==========================================

          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Tipos',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 10),

          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: tipos.map((tipo) {
              final tipoOriginal =
                  tipo['type']['name'];

              return Chip(
                avatar: Text(
                  obtenerIconoTipo(tipoOriginal),
                  style: const TextStyle(
                    fontSize: 18,
                  ),
                ),
                label: Text(
                  traducirTipo(tipoOriginal),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
          ),

          const Align(
  alignment: Alignment.centerLeft,
  child: Text(
    'Descripción',
    style: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
    ),
  ),
),
const SizedBox(height: 10),
Card(
  child: Padding(
    padding: const EdgeInsets.all(15),
    child: Text(
      pokemon!['descripcion'] ??
          'No hay una descripción disponible.',
      textAlign: TextAlign.justify,
      style: const TextStyle(
        fontSize: 16,
        height: 1.5,
      ),
    ),
  ),
),
const SizedBox(height: 25),

          const SizedBox(height: 25),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Características',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      children: [
                        const Text(
                          'Altura',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${(pokemon!['height'] / 10).toStringAsFixed(1)} m',
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      children: [
                        const Text(
                          'Peso',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${(pokemon!['weight'] / 10).toStringAsFixed(1)} kg',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),

          // ==========================================
          // HABILIDADES
          // ==========================================

          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Habilidades',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 10),

          Column(
            children: habilidades.map((habilidad) {
              final nombreHabilidad =
                  habilidad['ability']['name'];

              final esOculta =
                  habilidad['is_hidden'] == true;

              return Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.auto_awesome,
                  ),
                  title: Text(
                    traducirHabilidad(
                      nombreHabilidad,
                    ),
                  ),
                  subtitle: esOculta
                      ? const Text(
                          'Habilidad oculta',
                        )
                      : null,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 25),

          // ==========================================
          // ESTADÍSTICAS
          // ==========================================

          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Estadísticas',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 10),

          Column(
            children: estadisticas.map((estadistica) {
              final nombreEstadistica =
                  estadistica['stat']['name'];

              final valor =
                  estadistica['base_stat'] as int;

              return Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 90,
                      child: Text(
                        traducirEstadistica(
                          nombreEstadistica,
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    Expanded(
                      child: LinearProgressIndicator(
                        value: valor / 255,
                        minHeight: 8,
                      ),
                    ),

                    const SizedBox(width: 10),

                    SizedBox(
                      width: 35,
                      child: Text(
                        valor.toString(),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}