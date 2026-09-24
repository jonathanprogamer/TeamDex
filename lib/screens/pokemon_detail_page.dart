import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../database/database_helper.dart';
import '../services/poke_api_service.dart';

class PokemonDetailPage extends StatefulWidget {
  final int pokemonId;

  /// Crea la pantalla de detalles para el Pokemon identificado por [pokemonId].
  const PokemonDetailPage({
    super.key,
    required this.pokemonId,
  });

  /// Crea el estado que administra datos, favoritos, audio y apariencia shiny.
  @override
  State<PokemonDetailPage> createState() =>
      _PokemonDetailPageState();
}

class _PokemonDetailPageState
    extends State<PokemonDetailPage> {
  final PokeApiService api = PokeApiService();
  final DatabaseHelper db = DatabaseHelper.instance;

  final AudioPlayer reproductor = AudioPlayer();

  Map<String, dynamic>? pokemon;

  bool cargando = true;
  bool favorito = false;
  bool reproduciendo = false;
  bool mostrandoShiny = false;

  String nivelConocimiento = 'novato';

  /// Inicia la carga de los detalles del Pokemon al mostrar la pantalla.
  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  /// Libera el reproductor de audio cuando la pantalla se destruye.
  @override
  void dispose() {
    reproductor.dispose();
    super.dispose();
  }

  // ======================================================
  // CARGAR DATOS
  // ======================================================

  /// Obtiene los detalles desde la API, el favorito y el nivel del usuario.
  /// Actualiza la interfaz cuando todo esta disponible y muestra un aviso si
  /// alguna peticion falla.
  Future<void> cargarDatos() async {
    try {
      final datos =
          await api.obtenerDetallesPokemon(
        widget.pokemonId,
      );

      final esFavorito =
          await db.esFavorito(
        widget.pokemonId,
      );

      final nivel =
          await db.obtenerNivelConocimiento();

      if (!mounted) {
        return;
      }

      setState(() {
        pokemon = datos;
        favorito = esFavorito;
        nivelConocimiento = nivel;
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
            'No se pudo cargar la información del Pokémon.',
          ),
        ),
      );
    }
  }

  // ======================================================
  // FAVORITOS
  // ======================================================

  /// Agrega o elimina el Pokemon actual de la tabla de favoritos.
  /// Actualiza el icono de favorito despues de completar la operacion.
  Future<void> cambiarFavorito() async {
    if (pokemon == null) {
      return;
    }

    final nombre =
        pokemon!['name'].toString();

    final sprite =
        pokemon!['sprites']['front_default'];

    if (favorito) {
      await db.eliminarFavorito(
        widget.pokemonId,
      );
    } else {
      await db.agregarFavorito(
        widget.pokemonId,
        nombre,
        sprite.toString(),
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      favorito = !favorito;
    });
  }

  // ======================================================
  // REPRODUCIR CRY
  // ======================================================

  /// Reproduce o detiene el grito obtenido desde PokeAPI.
  /// Mantiene [reproduciendo] sincronizado con el reproductor y muestra un
  /// mensaje si el audio no puede iniciarse.
  Future<void> reproducirCry() async {
    if (pokemon == null) {
      return;
    }

    final cry = pokemon!['cry'];

    if (cry == null) {
      return;
    }

    try {
      if (reproduciendo) {
        await reproductor.stop();

        if (!mounted) {
          return;
        }

        setState(() {
          reproduciendo = false;
        });

        return;
      }

      setState(() {
        reproduciendo = true;
      });

      await reproductor.stop();

      await reproductor.play(
        UrlSource(
          cry.toString(),
        ),
      );

      reproductor.onPlayerComplete.listen(
        (event) {
          if (!mounted) {
            return;
          }

          setState(() {
            reproduciendo = false;
          });
        },
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        reproduciendo = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo reproducir el sonido del Pokémon.',
          ),
        ),
      );
    }
  }

  // ======================================================
  // TIPOS
  // ======================================================

  /// Convierte el identificador ingles de un tipo en su nombre en espanol.
  String traducirTipo(String tipo) {
    const traducciones = {
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

    return traducciones[tipo] ?? tipo;
  }

  /// Devuelve el icono de Material asociado al tipo recibido.
  IconData obtenerIconoTipo(String tipo) {
    const iconos = {
      'normal': Icons.circle,
      'fire': Icons.local_fire_department,
      'water': Icons.water_drop,
      'electric': Icons.bolt,
      'grass': Icons.eco,
      'ice': Icons.ac_unit,
      'fighting': Icons.sports_martial_arts,
      'poison': Icons.science,
      'ground': Icons.landscape,
      'flying': Icons.air,
      'psychic': Icons.visibility,
      'bug': Icons.bug_report,
      'rock': Icons.terrain,
      'ghost': Icons.auto_awesome,
      'dragon': Icons.whatshot,
      'dark': Icons.nightlight,
      'steel': Icons.build,
      'fairy': Icons.auto_awesome,
    };

    return iconos[tipo] ?? Icons.circle;
  }

  /// Devuelve una explicacion del tipo adaptada al nivel del usuario.
  /// El modo novato usa lenguaje sencillo y el experto conserva detalles
  /// competitivos sobre fortalezas, debilidades e inmunidades.
  String obtenerExplicacionTipo(String tipo) {
    if (nivelConocimiento == 'novato') {
      const explicaciones = {
        'normal':
            'Es un tipo equilibrado y sin una ventaja especial frente a otros tipos.',
        'fire':
            'Los Pokémon de Fuego destacan contra Pokémon de Planta, Bicho, Hielo y Acero.',
        'water':
            'Los Pokémon de Agua son fuertes contra Fuego, Tierra y Roca.',
        'electric':
            'Los Pokémon Eléctricos son especialmente efectivos contra Pokémon de Agua y Volador.',
        'grass':
            'Los Pokémon de Planta son fuertes contra Agua, Tierra y Roca.',
        'ice':
            'Los Pokémon de Hielo destacan contra Planta, Tierra, Volador y Dragón.',
        'fighting':
            'Los Pokémon de Lucha son fuertes contra Normal, Hielo, Roca, Siniestro y Acero.',
        'poison':
            'Los Pokémon de Veneno destacan contra Planta y Hada.',
        'ground':
            'Los Pokémon de Tierra son fuertes contra Fuego, Eléctrico, Veneno, Roca y Acero.',
        'flying':
            'Los Pokémon Voladores son fuertes contra Planta, Lucha y Bicho.',
        'psychic':
            'Los Pokémon Psíquicos destacan contra Lucha y Veneno.',
        'bug':
            'Los Pokémon de tipo Bicho son fuertes contra Planta, Psíquico y Siniestro.',
        'rock':
            'Los Pokémon de Roca destacan contra Fuego, Hielo, Volador y Bicho.',
        'ghost':
            'Los Pokémon Fantasma destacan contra Psíquico y Fantasma.',
        'dragon':
            'Los Pokémon Dragón son fuertes contra otros Pokémon Dragón.',
        'dark':
            'Los Pokémon Siniestro destacan contra Psíquico y Fantasma.',
        'steel':
            'Los Pokémon de Acero tienen muchas resistencias y destacan contra Hielo, Roca y Hada.',
        'fairy':
            'Los Pokémon Hada destacan contra Lucha, Dragón y Siniestro.',
      };

      return explicaciones[tipo] ??
          'Este tipo determina las fortalezas y debilidades del Pokémon.';
    }

    const explicaciones = {
      'normal':
          'Tipo sin ventajas ofensivas frente a la mayoría de tipos.',
      'fire':
          'Fuerte contra Planta, Hielo, Bicho y Acero.',
      'water':
          'Fuerte contra Fuego, Tierra y Roca.',
      'electric':
          'Fuerte contra Agua y Volador. Es inmune a Tierra.',
      'grass':
          'Fuerte contra Agua, Tierra y Roca.',
      'ice':
          'Fuerte contra Planta, Tierra, Volador y Dragón.',
      'fighting':
          'Fuerte contra Normal, Hielo, Roca, Siniestro y Acero.',
      'poison':
          'Fuerte contra Planta y Hada.',
      'ground':
          'Fuerte contra Fuego, Eléctrico, Veneno, Roca y Acero.',
      'flying':
          'Fuerte contra Planta, Lucha y Bicho.',
      'psychic':
          'Fuerte contra Lucha y Veneno.',
      'bug':
          'Fuerte contra Planta, Psíquico y Siniestro.',
      'rock':
          'Fuerte contra Fuego, Hielo, Volador y Bicho.',
      'ghost':
          'Fuerte contra Psíquico y Fantasma.',
      'dragon':
          'Fuerte contra Dragón.',
      'dark':
          'Fuerte contra Psíquico y Fantasma.',
      'steel':
          'Fuerte contra Hielo, Roca y Hada.',
      'fairy':
          'Fuerte contra Lucha, Dragón y Siniestro.',
    };

    return explicaciones[tipo] ??
        'Las interacciones entre tipos determinan el daño recibido y realizado.';
  }

  // ======================================================
  // HABILIDADES
  // ======================================================

  /// Devuelve la explicacion de una habilidad segun el nivel configurado.
  /// Mantiene textos sencillos para principiantes y valores tecnicos para
  /// usuarios expertos.
  String obtenerExplicacionHabilidad(
    String habilidad,
  ) {
    if (nivelConocimiento == 'novato') {
      const explicaciones = {
        'overgrow':
            'Cuando los PS están bajos, los movimientos de tipo Planta hacen más daño.',
        'blaze':
            'Cuando los PS están bajos, los movimientos de tipo Fuego hacen más daño.',
        'torrent':
            'Cuando los PS están bajos, los movimientos de tipo Agua hacen más daño.',
        'swarm':
            'Cuando los PS están bajos, los movimientos de tipo Bicho hacen más daño.',
        'solar-power':
            'Durante el sol, aumenta un 50% el Ataque Especial, pero pierde un 12,5% de sus PS máximos por turno.',
        'rain-dish':
            'Durante la lluvia, recupera un 6,25% de sus PS máximos cada turno.',
        'static':
            'Los movimientos de contacto tienen un 30% de probabilidad de paralizar al atacante.',
        'flame-body':
            'Los movimientos de contacto tienen un 30% de probabilidad de quemar al atacante.',
        'poison-point':
            'Los movimientos de contacto tienen un 30% de probabilidad de envenenar al atacante.',
        'cute-charm':
            'Los movimientos de contacto tienen un 30% de probabilidad de enamorar al atacante.',
        'water-absorb':
            'Los movimientos de tipo Agua no hacen daño y recupera un 25% de sus PS máximos.',
        'volt-absorb':
            'Los movimientos de tipo Eléctrico no hacen daño y recupera un 25% de sus PS máximos.',
        'flash-fire':
            'Los movimientos de tipo Fuego no hacen daño y aumenta un 50% el poder de sus propios movimientos de Fuego.',
        'guts':
            'Si tiene un problema de estado, su Ataque aumenta un 50%. Además, la quemadura no reduce su Ataque.',
        'technician':
            'Los movimientos con una potencia de 60 o menos reciben un aumento del 50%.',
        'adaptability':
            'Aumenta el poder adicional que reciben los movimientos del mismo tipo que el Pokémon.',
        'swift-swim':
            'Duplica la Velocidad durante la lluvia.',
        'chlorophyll':
            'Duplica la Velocidad durante el sol.',
        'sand-veil':
            'Aumenta un 20% la evasión durante una tormenta de arena.',
        'snow-cloak':
            'Aumenta un 20% la evasión durante nieve o granizo.',
        'sturdy':
            'Si tiene todos sus PS, puede sobrevivir a un ataque que normalmente lo derrotaría de un solo golpe, quedándose con 1 PS.',
        'moxie':
            'Cada vez que derrota a otro Pokémon, aumenta su Ataque.',
      };

      return explicaciones[habilidad] ??
          'Esta habilidad proporciona un efecto especial durante el combate.';
    }

    const explicaciones = {
      'overgrow':
          'Con PS ≤ 1/3 del máximo, los movimientos de tipo Planta reciben un multiplicador de 1,5×.',
      'blaze':
          'Con PS ≤ 1/3 del máximo, los movimientos de tipo Fuego reciben un multiplicador de 1,5×.',
      'torrent':
          'Con PS ≤ 1/3 del máximo, los movimientos de tipo Agua reciben un multiplicador de 1,5×.',
      'swarm':
          'Con PS ≤ 1/3 del máximo, los movimientos de tipo Bicho reciben un multiplicador de 1,5×.',
      'solar-power':
          'Bajo sol, aumenta el Ataque Especial un 50% y pierde un 12,5% de los PS máximos por turno.',
      'rain-dish':
          'Bajo lluvia, recupera un 6,25% de los PS máximos al final de cada turno.',
      'static':
          'Los movimientos de contacto tienen un 30% de probabilidad de paralizar al atacante.',
      'flame-body':
          'Los movimientos de contacto tienen un 30% de probabilidad de quemar al atacante.',
      'poison-point':
          'Los movimientos de contacto tienen un 30% de probabilidad de envenenar al atacante.',
      'cute-charm':
          'Los movimientos de contacto tienen un 30% de probabilidad de causar enamoramiento.',
      'water-absorb':
          'Anula el daño de movimientos de Agua y restaura un 25% de los PS máximos.',
      'volt-absorb':
          'Anula el daño de movimientos Eléctricos y restaura un 25% de los PS máximos.',
      'flash-fire':
          'Otorga inmunidad a movimientos de Fuego y aumenta un 50% el poder de los movimientos de Fuego tras activarse.',
      'guts':
          'Con un problema de estado, multiplica el Ataque por 1,5× e ignora la reducción de Ataque causada por quemadura.',
      'technician':
          'Los movimientos con potencia base ≤60 reciben un multiplicador de 1,5×.',
      'adaptability':
          'Aumenta el multiplicador STAB de 1,5× a 2×.',
      'swift-swim':
          'Duplica la Velocidad bajo lluvia.',
      'chlorophyll':
          'Duplica la Velocidad bajo sol.',
      'sand-veil':
          'Aumenta la evasión un 20% durante una tormenta de arena.',
      'snow-cloak':
          'Aumenta la evasión un 20% durante nieve.',
      'sturdy':
          'Con PS completos, evita el debilitamiento por un ataque de un solo golpe y deja al Pokémon con 1 PS.',
      'moxie':
          'Al debilitar a un Pokémon rival, aumenta el Ataque en 1 nivel.',
    };

    return explicaciones[habilidad] ??
        'Esta habilidad proporciona un efecto específico durante el combate.';
  }

  // ======================================================
  // ESTADÍSTICAS
  // ======================================================

  /// Convierte el nombre interno de una estadistica a su etiqueta en espanol.
  String traducirEstadistica(
    String estadistica,
  ) {
    const traducciones = {
      'hp': 'PS',
      'attack': 'Ataque',
      'defense': 'Defensa',
      'special-attack': 'Ataque Especial',
      'special-defense': 'Defensa Especial',
      'speed': 'Velocidad',
    };

    return traducciones[estadistica] ??
        estadistica;
  }

  /// Explica el efecto de una estadistica usando el modo seleccionado.
  String obtenerExplicacionEstadistica(
    String estadistica,
  ) {
    if (nivelConocimiento == 'novato') {
      const explicaciones = {
        'hp':
            'Indica cuánta vida puede soportar el Pokémon antes de debilitarse.',
        'attack':
            'Determina principalmente el daño de los movimientos físicos.',
        'defense':
            'Ayuda a reducir el daño recibido de movimientos físicos.',
        'special-attack':
            'Determina principalmente el daño de los movimientos especiales.',
        'special-defense':
            'Ayuda a reducir el daño recibido de movimientos especiales.',
        'speed':
            'Determina qué Pokémon suele atacar primero.',
      };

      return explicaciones[estadistica] ??
          'Esta estadística influye en el rendimiento del Pokémon durante el combate.';
    }

    const explicaciones = {
      'hp':
          'Determina la cantidad máxima de PS del Pokémon.',
      'attack':
          'Influye en el daño causado por movimientos físicos.',
      'defense':
          'Reduce el daño recibido de movimientos físicos.',
      'special-attack':
          'Influye en el daño causado por movimientos especiales.',
      'special-defense':
          'Reduce el daño recibido de movimientos especiales.',
      'speed':
          'Determina el orden de acción según la Velocidad de los Pokémon.',
    };

    return explicaciones[estadistica] ??
        'Esta estadística influye en el rendimiento del Pokémon.';
  }

  // ======================================================
  // BUILD
  // ======================================================

  /// Construye la vista completa con sprite, tipos, habilidades y estadisticas.
  /// Tambien muestra estados de carga o error antes de disponer de los datos.
  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (pokemon == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'No se pudo cargar el Pokémon.',
          ),
        ),
      );
    }

    final nombre =
        pokemon!['name'].toString();

    final sprite =
        pokemon!['sprites']['front_default'];

    final spriteShiny =
        pokemon!['sprite_shiny'];

    final tipos =
        pokemon!['types'] as List;

    final habilidades =
        pokemon!['abilities'] as List;

    final estadisticas =
        pokemon!['stats'] as List;

    final descripcion =
        pokemon!['descripcion'];

    final altura =
        (pokemon!['height'] as num) / 10;

    final peso =
        (pokemon!['weight'] as num) / 10;

    final spriteActual =
        mostrandoShiny
            ? spriteShiny
            : sprite;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detalles del Pokémon',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: cambiarFavorito,
            icon: Icon(
              favorito
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: favorito
                  ? Colors.red
                  : null,
            ),
            tooltip: favorito
                ? 'Quitar de favoritos'
                : 'Agregar a favoritos',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ==================================================
            // SPRITE
            // ==================================================

            Image.network(
              spriteActual,
              height: 220,
              width: 220,
              fit: BoxFit.contain,
              errorBuilder: (
                context,
                error,
                stackTrace,
              ) {
                return const Icon(
                  Icons.catching_pokemon,
                  size: 150,
                );
              },
            ),

            const SizedBox(height: 10),

            // ==================================================
            // BOTONES DE SONIDO Y SHINY
            // ==================================================

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: reproducirCry,
                  icon: Icon(
                    reproduciendo
                        ? Icons.volume_up
                        : Icons.volume_up_outlined,
                  ),
                  label: Text(
                    reproduciendo
                        ? 'Reproduciendo...'
                        : '🔊 Sonido',
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      mostrandoShiny =
                          !mostrandoShiny;
                    });
                  },
                  icon: const Icon(
                    Icons.auto_awesome,
                  ),
                  label: Text(
                    mostrandoShiny
                        ? '✨ Normal'
                        : '✨ Shiny',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ==================================================
            // NÚMERO
            // ==================================================

            Text(
              '#${widget.pokemonId.toString().padLeft(3, '0')}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            // ==================================================
            // NOMBRE
            // ==================================================

            Text(
              nombre
                  .replaceAll('-', ' ')
                  .split(' ')
                  .map(
                    (palabra) =>
                        palabra.isEmpty
                            ? palabra
                            : palabra[0]
                                    .toUpperCase() +
                                palabra.substring(1),
                  )
                  .join(' '),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 25),

            // ==================================================
            // TIPOS
            // ==================================================

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tipos',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 12),

            ...tipos.map((tipoData) {
              final tipo =
                  tipoData['type']['name'].toString();

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(
                  bottom: 10,
                ),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius:
                      BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Icon(
                      obtenerIconoTipo(tipo),
                      color: Colors.red,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            traducirTipo(tipo),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            obtenerExplicacionTipo(
                              tipo,
                            ),
                            style: TextStyle(
                              fontSize: 13,
                              color:
                                  Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 15),

            // ==================================================
            // DESCRIPCIÓN
            // ==================================================

            if (descripcion != null) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Descripción',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius:
                      BorderRadius.circular(15),
                ),
                child: Text(
                  descripcion
                      .toString()
                      .replaceAll('\n', ' '),
                  style: const TextStyle(
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ==================================================
            // CARACTERÍSTICAS
            // ==================================================

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Características',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius:
                          BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.height,
                          size: 28,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Altura',
                          style: TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${altura.toStringAsFixed(1)} m',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius:
                          BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.monitor_weight,
                          size: 28,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Peso',
                          style: TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${peso.toStringAsFixed(1)} kg',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // ==================================================
            // HABILIDADES
            // ==================================================

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Habilidades',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 10),

            ...habilidades.map((habilidadData) {
              final habilidadOriginal =
                  habilidadData['ability']['name']
                      .toString();

              final habilidadEspanol =
                  habilidadData['ability']['name_es']
                          ?.toString() ??
                      habilidadOriginal;

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(
                  bottom: 10,
                ),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius:
                      BorderRadius.circular(15),
                ),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            habilidadEspanol,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            obtenerExplicacionHabilidad(
                              habilidadOriginal,
                            ),
                            style: TextStyle(
                              fontSize: 13,
                              color:
                                  Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 15),

            // ==================================================
            // ESTADÍSTICAS
            // ==================================================

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Estadísticas',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 10),

            ...estadisticas.map((statData) {
              final stat =
                  statData['stat']['name'].toString();

              final valor =
                  statData['base_stat'] as int;

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(
                  bottom: 10,
                ),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius:
                      BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,
                      children: [
                        Text(
                          traducirEstadistica(stat),
                          style: const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        Text(
                          valor.toString(),
                          style: const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      obtenerExplicacionEstadistica(
                        stat,
                      ),
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: valor / 255,
                      minHeight: 7,
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}