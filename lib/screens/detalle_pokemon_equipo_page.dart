import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../services/poke_api_service.dart';

class DetallePokemonEquipoPage extends StatefulWidget {
  final int equipoId;
  final int pokemonId;
  final String nombrePokemon;
  final String sprite;

  /// Crea la pantalla de configuracion del Pokemon dentro de un equipo.
  /// Recibe los identificadores y datos basicos necesarios para cargar y
  /// guardar sus habilidades, objeto, movimientos y estado shiny.
  const DetallePokemonEquipoPage({
    super.key,
    required this.equipoId,
    required this.pokemonId,
    required this.nombrePokemon,
    required this.sprite,
  });

  /// Crea el estado que administra la configuracion editable del Pokemon.
  @override
  State<DetallePokemonEquipoPage> createState() =>
      _DetallePokemonEquipoPageState();
}

class _DetallePokemonEquipoPageState
    extends State<DetallePokemonEquipoPage> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final PokeApiService _api = PokeApiService();

  Map<String, dynamic>? pokemon;
  Map<String, dynamic>? configuracion;

  List<dynamic> habilidades = [];
  List<dynamic> movimientos = [];
  List<dynamic> objetos = [];

  Map<String, dynamic>? habilidadSeleccionada;
  Map<String, dynamic>? objetoSeleccionado;

  final List<Map<String, dynamic>?> movimientosSeleccionados = [
    null,
    null,
    null,
    null,
  ];

  final List<Map<String, dynamic>?> detallesMovimientos = [
    null,
    null,
    null,
    null,
  ];

  // Caché de detalles de movimientos.
  final Map<String, Future<Map<String, dynamic>>>
      _detallesMovimientosLista = {};

  bool cargando = true;
  bool guardando = false;
  bool esShiny = false;

  String nivelConocimiento = 'novato';

  // ==========================================================
  // ORDEN DE LOS TIPOS POKÉMON
  // ==========================================================

  static const List<String> ordenTipos = [
    'normal',
    'fire',
    'water',
    'electric',
    'grass',
    'ice',
    'fighting',
    'poison',
    'ground',
    'flying',
    'psychic',
    'bug',
    'rock',
    'ghost',
    'dragon',
    'dark',
    'steel',
    'fairy',
  ];

  /// Inicia la carga de los datos remotos y la configuracion guardada.
  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  // ==========================================================
  // CARGAR DATOS
  // ==========================================================

  /// Obtiene detalles del Pokemon, opciones disponibles y valores guardados.
  ///
  /// Restaura la habilidad, los cuatro movimientos, el objeto, el modo shiny y
  /// el nivel de conocimiento para que el formulario muestre la configuracion
  /// anterior del equipo.
  Future<void> cargarDatos() async {
    try {
      final datosPokemon =
          await _api.obtenerDetallesPokemon(widget.pokemonId);

      final datosConfiguracion =
          await _db.obtenerConfiguracionPokemon(
        widget.equipoId,
        widget.pokemonId,
      );

      final nivel =
          await _db.obtenerNivelConocimiento();

      if (!mounted) return;

      setState(() {
        pokemon = datosPokemon;
        configuracion = datosConfiguracion;

        habilidades =
            datosPokemon['abilities'] ?? [];

        movimientos =
            datosPokemon['moves'] ?? [];

        objetos =
            datosPokemon['held_items'] ?? [];

        nivelConocimiento =
            nivel;

        esShiny =
            datosConfiguracion?['es_shiny'] == 1;
      });

      // --------------------------------------------------------
      // RESTAURAR HABILIDAD
      // --------------------------------------------------------

      final habilidadGuardada =
          datosConfiguracion?['habilidad'];

      if (habilidadGuardada != null &&
          habilidadGuardada.toString().isNotEmpty) {
        for (final habilidad in habilidades) {
          final nombre =
              habilidad['ability']['name']
                  .toString();

          if (nombre ==
              habilidadGuardada.toString()) {
            habilidadSeleccionada =
                habilidad;
            break;
          }
        }
      }

      // --------------------------------------------------------
      // RESTAURAR MOVIMIENTOS
      // --------------------------------------------------------

      final movimientosGuardados = [
        datosConfiguracion?['movimiento_1'],
        datosConfiguracion?['movimiento_2'],
        datosConfiguracion?['movimiento_3'],
        datosConfiguracion?['movimiento_4'],
      ];

      for (int i = 0; i < 4; i++) {
        final movimientoGuardado =
            movimientosGuardados[i];

        if (movimientoGuardado != null &&
            movimientoGuardado
                .toString()
                .isNotEmpty) {
          for (final movimiento in movimientos) {
            final nombre =
                movimiento['move']['name']
                    .toString();

            if (nombre ==
                movimientoGuardado.toString()) {
              movimientosSeleccionados[i] =
                  movimiento;
              break;
            }
          }
        }
      }

      // --------------------------------------------------------
      // RESTAURAR OBJETO
      // --------------------------------------------------------

      final objetoGuardado =
          datosConfiguracion?['objeto'];

      if (objetoGuardado != null &&
          objetoGuardado.toString().isNotEmpty) {
        for (final objeto in objetos) {
          final nombre =
              objeto['item']['name']
                  .toString();

          if (nombre ==
              objetoGuardado.toString()) {
            objetoSeleccionado =
                objeto;
            break;
          }
        }
      }

      // --------------------------------------------------------
      // CARGAR DETALLES DE LOS MOVIMIENTOS GUARDADOS
      // --------------------------------------------------------

      for (int i = 0; i < 4; i++) {
        if (movimientosSeleccionados[i] != null) {
          await cargarDetalleMovimiento(i);
        }
      }

      if (!mounted) return;

      setState(() {
        cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        cargando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al cargar el Pokémon: $e',
          ),
        ),
      );
    }
  }

  // ==========================================================
  // DETALLE DE MOVIMIENTO SELECCIONADO
  // ==========================================================

  /// Carga los detalles del movimiento seleccionado en el slot [index].
  /// Guarda el resultado para mostrar tipo, categoria, potencia, precision y
  /// PP en la tarjeta correspondiente.
  Future<void> cargarDetalleMovimiento(
    int index,
  ) async {
    final movimiento =
        movimientosSeleccionados[index];

    if (movimiento == null) return;

    final nombre =
        movimiento['move']['name'].toString();

    try {
      final detalle =
          await _api.obtenerDetallesMovimiento(
        nombre,
      );

      if (!mounted) return;

      setState(() {
        detallesMovimientos[index] =
            detalle;
      });
    } catch (_) {}
  }

  // ==========================================================
  // DETALLES DE MOVIMIENTO PARA LA LISTA
  // ==========================================================

  /// Obtiene los detalles de un movimiento usando una cache de futuros.
  ///
  /// Si el nombre ya fue consultado, reutiliza la peticion almacenada para no
  /// repetir llamadas a PokeAPI desde distintos slots o reconstrucciones.
  Future<Map<String, dynamic>>
      obtenerDetalleMovimientoLista(
    String nombre,
  ) {
    if (_detallesMovimientosLista
        .containsKey(nombre)) {
      return _detallesMovimientosLista[nombre]!;
    }

    final future =
        _api.obtenerDetallesMovimiento(nombre);

    _detallesMovimientosLista[nombre] =
        future;

    return future;
  }

  // ==========================================================
  // OBTENER MOVIMIENTOS ORDENADOS POR TIPO
  // ==========================================================

  /// Consulta los movimientos disponibles y los ordena para el selector.
  ///
  /// El orden prioriza el tipo, la categoria de dano y finalmente el nombre
  /// traducido para facilitar la localizacion de cada movimiento.
  Future<List<Map<String, dynamic>>>
    obtenerMovimientosOrdenados() async {
  final List<Map<String, dynamic>>
      movimientosConDetalle = [];

  // Cargamos los detalles de los movimientos
  // que todavía no están en caché.
  final futures =
      movimientos.map((movimiento) async {
    final nombre =
        movimiento['move']['name']
            .toString();

    try {
      final detalle =
          await obtenerDetalleMovimientoLista(
        nombre,
      );

      return {
        'movimiento': movimiento,
        'detalle': detalle,
      };
    } catch (_) {
      return {
        'movimiento': movimiento,
        'detalle': <String, dynamic>{
          'tipo': 'normal',
          'categoria': 'status',
        },
      };
    }
  }).toList();

  final resultados =
      await Future.wait(futures);

  for (final resultado in resultados) {
    movimientosConDetalle.add(
      resultado as Map<String, dynamic>,
    );
  }

  // ==========================================================
  // ORDEN:
  //
  // 1. TIPO
  // 2. CATEGORÍA
  // 3. NOMBRE EN ESPAÑOL
  // ==========================================================

  movimientosConDetalle.sort(
    (a, b) {
      final detalleA =
          a['detalle']
              as Map<String, dynamic>;

      final detalleB =
          b['detalle']
              as Map<String, dynamic>;

      // ------------------------------------------------------
      // TIPO
      // ------------------------------------------------------

      final tipoA =
          detalleA['tipo']
                  ?.toString() ??
              'normal';

      final tipoB =
          detalleB['tipo']
                  ?.toString() ??
              'normal';

      final posicionTipoA =
          ordenTipos.indexOf(tipoA);

      final posicionTipoB =
          ordenTipos.indexOf(tipoB);

      final ordenTipoA =
          posicionTipoA == -1
              ? ordenTipos.length
              : posicionTipoA;

      final ordenTipoB =
          posicionTipoB == -1
              ? ordenTipos.length
              : posicionTipoB;

      if (ordenTipoA != ordenTipoB) {
        return ordenTipoA.compareTo(
          ordenTipoB,
        );
      }

      // ------------------------------------------------------
      // CATEGORÍA
      //
      // physical → special → status
      // ------------------------------------------------------

      final categoriaA =
          detalleA['categoria']
                  ?.toString() ??
              'status';

      final categoriaB =
          detalleB['categoria']
                  ?.toString() ??
              'status';

      int ordenCategoria(
        String categoria,
      ) {
        switch (categoria) {
          case 'physical':
            return 0;

          case 'special':
            return 1;

          case 'status':
            return 2;

          default:
            return 3;
        }
      }

      final ordenCategoriaA =
          ordenCategoria(categoriaA);

      final ordenCategoriaB =
          ordenCategoria(categoriaB);

      if (ordenCategoriaA !=
          ordenCategoriaB) {
        return ordenCategoriaA.compareTo(
          ordenCategoriaB,
        );
      }

      // ------------------------------------------------------
      // NOMBRE EN ESPAÑOL
      //
      // Si son del mismo tipo y categoría,
      // se ordenan alfabéticamente.
      // ------------------------------------------------------

      final nombreA =
          detalleA['name_es']
                  ?.toString() ??
              a['movimiento']['move']
                      ['name']
                  .toString();

      final nombreB =
          detalleB['name_es']
                  ?.toString() ??
              b['movimiento']['move']
                      ['name']
                  .toString();

      return nombreA
          .toLowerCase()
          .compareTo(
            nombreB.toLowerCase(),
          );
    },
  );

  return movimientosConDetalle;
}

  // ==========================================================
  // SELECCIONAR MOVIMIENTO
  // ==========================================================

  /// Abre un selector y guarda el movimiento elegido en el slot indicado.
  /// Impide repetir un movimiento en otro slot y actualiza sus detalles en la
  /// interfaz despues de cerrar el selector.
  Future<void> seleccionarMovimiento(
    int index,
  ) async {
    final resultado =
        await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
            height:
                MediaQuery.of(context).size.height *
                    0.82,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .scaffoldBackgroundColor,
              borderRadius:
                  const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // ------------------------------------------------
                // ENCABEZADO
                // ------------------------------------------------

                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(
                    16,
                    14,
                    16,
                    8,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 45,
                        height: 5,
                        decoration: BoxDecoration(
                          color:
                              Colors.grey.shade400,
                          borderRadius:
                              BorderRadius.circular(
                            10,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      const Text(
                        'Seleccionar movimiento',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Text(
                        'Movimiento ${index + 1}',
                        style: TextStyle(
                          color:
                              Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(),

                // ------------------------------------------------
                // LISTA ORDENADA
                // ------------------------------------------------

                Expanded(
                  child: FutureBuilder<
                      List<Map<String, dynamic>>>(
                    future:
                        obtenerMovimientosOrdenados(),
                    builder:
                        (context, snapshot) {
                      if (snapshot
                          .connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child:
                              Column(
                            mainAxisSize:
                                MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(
                                height: 15,
                              ),
                              Text(
                                'Organizando movimientos...',
                              ),
                            ],
                          ),
                        );
                      }

                      if (snapshot.hasError ||
                          !snapshot.hasData) {
                        return const Center(
                          child: Text(
                            'No se pudieron cargar los movimientos.',
                          ),
                        );
                      }

                      final movimientosOrdenados =
                          snapshot.data!;

                      return ListView.builder(
                        padding:
                            const EdgeInsets
                                .fromLTRB(
                          12,
                          8,
                          12,
                          20,
                        ),
                        itemCount:
                            movimientosOrdenados
                                .length,
                        itemBuilder:
                            (context, movimientoIndex) {
                          final elemento =
                              movimientosOrdenados[
                                  movimientoIndex];

                          final movimiento =
                              elemento[
                                  'movimiento'] as Map<
                                      String,
                                      dynamic>;

                          final detalle =
                              elemento[
                                  'detalle'] as Map<
                                      String,
                                      dynamic>;

                          final nombre =
                              movimiento[
                                      'move']
                                  ['name']
                              .toString();

                          final nombreEspanol =
                              detalle['name_es']
                                      ?.toString() ??
                                  nombreBonito(
                                    nombre,
                                  );

                          final tipo =
                              detalle['tipo']
                                      ?.toString() ??
                                  'normal';

                          final categoria =
                              detalle['categoria']
                                      ?.toString() ??
                                  'status';

                          final color =
                              colorTipo(tipo);

                          final estaSeleccionadoEnOtroSlot =
                              _movimientoEstaSeleccionadoEnOtroSlot(
                            nombre,
                            index,
                          );

                          final estaSeleccionadoEnEsteSlot =
                              _movimientoEstaSeleccionadoEnEsteSlot(
                            nombre,
                            index,
                          );

                          final bloqueado =
                              estaSeleccionadoEnOtroSlot;

                          return Card(
                            margin:
                                const EdgeInsets.only(
                              bottom: 10,
                            ),
                            elevation:
                                bloqueado ? 0 : 2,
                            clipBehavior:
                                Clip.antiAlias,
                            child: Opacity(
                              opacity:
                                  bloqueado
                                      ? 0.55
                                      : 1,
                              child: InkWell(
                                onTap: bloqueado
                                    ? null
                                    : () {
                                        Navigator.pop(
                                          context,
                                          movimiento,
                                        );
                                      },
                                child:
                                    Container(
                                  decoration:
                                      BoxDecoration(
                                    border:
                                        Border.all(
                                      color:
                                          bloqueado
                                              ? Colors
                                                  .grey
                                                  .shade300
                                              : color
                                                  .withOpacity(
                                                  0.45,
                                                ),
                                      width:
                                          1.2,
                                    ),
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      12,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      // --------------------------------
                                      // NOMBRE Y TIPO
                                      // --------------------------------

                                      Container(
                                        width:
                                            double.infinity,
                                        padding:
                                            const EdgeInsets
                                                .symmetric(
                                          horizontal:
                                              14,
                                          vertical:
                                              12,
                                        ),
                                        decoration:
                                            BoxDecoration(
                                          color:
                                              color.withOpacity(
                                            0.18,
                                          ),
                                        ),
                                        child:
                                            Row(
                                          children: [
                                            Container(
                                              width:
                                                  42,
                                              height:
                                                  42,
                                              decoration:
                                                  BoxDecoration(
                                                color:
                                                    color,
                                                shape:
                                                    BoxShape
                                                        .circle,
                                              ),
                                              child:
                                                  Center(
                                                child:
                                                    Text(
                                                  iconoTipo(
                                                    tipo,
                                                  ),
                                                  style:
                                                      const TextStyle(
                                                    fontSize:
                                                        20,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(
                                              width:
                                                  12,
                                            ),
                                            Expanded(
                                              child:
                                                  Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment
                                                        .start,
                                                children: [
                                                  Text(
                                                    nombreEspanol,
                                                    maxLines:
                                                        2,
                                                    overflow:
                                                        TextOverflow
                                                            .ellipsis,
                                                    style:
                                                        const TextStyle(
                                                      fontSize:
                                                          16,
                                                      fontWeight:
                                                          FontWeight
                                                              .bold,
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    height:
                                                        4,
                                                  ),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                      horizontal:
                                                          8,
                                                      vertical:
                                                          3,
                                                    ),
                                                    decoration:
                                                        BoxDecoration(
                                                      color:
                                                          color,
                                                      borderRadius:
                                                          BorderRadius
                                                              .circular(
                                                        20,
                                                      ),
                                                    ),
                                                    child:
                                                        Text(
                                                      nombreTipo(
                                                        tipo,
                                                      ),
                                                      style:
                                                          const TextStyle(
                                                        color:
                                                            Colors.white,
                                                        fontSize:
                                                            11,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // --------------------------------
                                      // CATEGORÍA Y ESTADO
                                      // --------------------------------

                                      Padding(
                                        padding:
                                            const EdgeInsets
                                                .fromLTRB(
                                          14,
                                          10,
                                          14,
                                          12,
                                        ),
                                        child:
                                            Row(
                                          children: [
                                            Text(
                                              iconoCategoriaMovimiento(
                                                categoria,
                                              ),
                                              style:
                                                  const TextStyle(
                                                fontSize:
                                                    17,
                                              ),
                                            ),
                                            const SizedBox(
                                              width:
                                                  7,
                                            ),
                                            Expanded(
                                              child:
                                                  Text(
                                                textoCategoriaMovimiento(
                                                  categoria,
                                                ),
                                                style:
                                                    TextStyle(
                                                  fontWeight:
                                                      FontWeight.w600,
                                                  color:
                                                      Colors.grey.shade700,
                                                ),
                                              ),
                                            ),

                                            if (estaSeleccionadoEnEsteSlot)
                                              Container(
                                                padding:
                                                    const EdgeInsets
                                                        .symmetric(
                                                  horizontal:
                                                      9,
                                                  vertical:
                                                      5,
                                                ),
                                                decoration:
                                                    BoxDecoration(
                                                  color: Colors
                                                      .green
                                                      .withOpacity(
                                                    0.15,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius
                                                          .circular(
                                                    20,
                                                  ),
                                                ),
                                                child:
                                                    const Row(
                                                  mainAxisSize:
                                                      MainAxisSize
                                                          .min,
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .check_circle,
                                                      color:
                                                          Colors.green,
                                                      size:
                                                          16,
                                                    ),
                                                    SizedBox(
                                                      width:
                                                          4,
                                                    ),
                                                    Text(
                                                      'Actual',
                                                      style:
                                                          TextStyle(
                                                        color:
                                                            Colors.green,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize:
                                                            12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            else if (bloqueado)
                                              Container(
                                                padding:
                                                    const EdgeInsets
                                                        .symmetric(
                                                  horizontal:
                                                      9,
                                                  vertical:
                                                      5,
                                                ),
                                                decoration:
                                                    BoxDecoration(
                                                  color: Colors
                                                      .grey
                                                      .withOpacity(
                                                    0.15,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius
                                                          .circular(
                                                    20,
                                                  ),
                                                ),
                                                child:
                                                    const Row(
                                                  mainAxisSize:
                                                      MainAxisSize
                                                          .min,
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .block,
                                                      size:
                                                          16,
                                                      color:
                                                          Colors.grey,
                                                    ),
                                                    SizedBox(
                                                      width:
                                                          4,
                                                    ),
                                                    Text(
                                                      'Ya usado',
                                                      style:
                                                          TextStyle(
                                                        color:
                                                            Colors.grey,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize:
                                                            12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (resultado != null) {
      setState(() {
        movimientosSeleccionados[index] =
            resultado;
        detallesMovimientos[index] = null;
      });

      await cargarDetalleMovimiento(index);
    }
  }

  // ==========================================================
  // COMPROBAR MOVIMIENTOS REPETIDOS
  // ==========================================================

  /// Comprueba si [nombre] ya esta ocupado por otro slot de movimiento.
  bool _movimientoEstaSeleccionadoEnOtroSlot(
    String nombre,
    int slotActual,
  ) {
    for (int i = 0;
        i < movimientosSeleccionados.length;
        i++) {
      if (i == slotActual) continue;

      final movimiento =
          movimientosSeleccionados[i];

      if (movimiento == null) continue;

      final nombreSeleccionado =
          movimiento['move']['name']
              .toString();

      if (nombreSeleccionado == nombre) {
        return true;
      }
    }

    return false;
  }

  /// Comprueba si [nombre] es el movimiento del slot que se esta mostrando.
  bool _movimientoEstaSeleccionadoEnEsteSlot(
    String nombre,
    int slotActual,
  ) {
    final movimiento =
        movimientosSeleccionados[slotActual];

    if (movimiento == null) {
      return false;
    }

    return movimiento['move']['name']
            .toString() ==
        nombre;
  }

  // ==========================================================
  // GUARDAR CONFIGURACIÓN
  // ==========================================================

  /// Persiste en SQLite toda la configuracion actual del Pokemon.
  /// Guarda habilidad, objeto, cuatro movimientos y el indicador shiny, y
  /// actualiza el estado de guardado para evitar envios simultaneos.
  Future<void> guardarConfiguracion() async {
    if (guardando) return;

    setState(() {
      guardando = true;
    });

    try {
      await _db.actualizarConfiguracionPokemon(
        equipoId: widget.equipoId,
        pokemonId: widget.pokemonId,
        habilidad:
            habilidadSeleccionada?['ability']
                ?['name']
                ?.toString(),
        objeto:
            objetoSeleccionado?['item']
                ?['name']
                ?.toString(),
        movimiento1:
            movimientosSeleccionados[0]?['move']
                ?['name']
                ?.toString(),
        movimiento2:
            movimientosSeleccionados[1]?['move']
                ?['name']
                ?.toString(),
        movimiento3:
            movimientosSeleccionados[2]?['move']
                ?['name']
                ?.toString(),
        movimiento4:
            movimientosSeleccionados[3]?['move']
                ?['name']
                ?.toString(),
        esShiny: esShiny,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Configuración guardada correctamente.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo guardar la configuración: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          guardando = false;
        });
      }
    }
  }

  // ==========================================================
  // SELECCIONAR HABILIDAD
  // ==========================================================

  /// Muestra las habilidades disponibles y conserva la elegida por el usuario.
  /// La opcion seleccionada se utiliza posteriormente al guardar el equipo.
  Future<void> seleccionarHabilidad() async {
    final resultado =
        await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height:
                MediaQuery.of(context).size.height *
                    0.65,
            child: ListView(
              padding:
                  const EdgeInsets.all(16),
              children: [
                const Text(
                  'Seleccionar habilidad',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 15,
                ),
                ...habilidades.map(
                  (habilidad) {
                    final datos =
                        habilidad['ability'];

                    final nombre =
                        datos['name']
                            .toString();

                    final nombreEspanol =
                        datos['name_es']
                                ?.toString() ??
                            nombreBonito(
                              nombre,
                            );

                    final seleccionada =
                        habilidadSeleccionada ==
                            habilidad;

                    return Card(
                      color: seleccionada
                          ? Colors.blue
                              .withOpacity(
                              0.12,
                            )
                          : null,
                      child: ListTile(
                        leading: Icon(
                          seleccionada
                              ? Icons
                                  .check_circle
                              : Icons
                                  .auto_awesome,
                          color: seleccionada
                              ? Colors.green
                              : null,
                        ),
                        title: Text(
                          nombreEspanol,
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(
                            context,
                            habilidad
                                as Map<
                                    String,
                                    dynamic>,
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (resultado != null) {
      setState(() {
        habilidadSeleccionada =
            resultado;
      });
    }
  }

  // ==========================================================
  // SELECCIONAR OBJETO
  // ==========================================================

  /// Muestra los objetos disponibles y conserva el objeto seleccionado.
  /// Si el Pokemon no tiene objetos disponibles, informa al usuario y no abre
  /// un selector vacio.
  Future<void> seleccionarObjeto() async {
    if (objetos.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Este Pokémon no tiene objetos disponibles.',
          ),
        ),
      );
      return;
    }

    final resultado =
        await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height:
                MediaQuery.of(context).size.height *
                    0.65,
            child: ListView(
              padding:
                  const EdgeInsets.all(16),
              children: [
                const Text(
                  'Seleccionar objeto',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 15,
                ),
                ...objetos.map(
                  (objeto) {
                    final datos =
                        objeto['item'];

                    final nombre =
                        datos['name']
                            .toString();

                    final nombreEspanol =
                        datos['name_es']
                                ?.toString() ??
                            nombreBonito(
                              nombre,
                            );

                    final seleccionado =
                        objetoSeleccionado ==
                            objeto;

                    return Card(
                      color: seleccionado
                          ? Colors.amber
                              .withOpacity(
                              0.15,
                            )
                          : null,
                      child: ListTile(
                        leading: Icon(
                          seleccionado
                              ? Icons
                                  .check_circle
                              : Icons
                                  .inventory_2,
                          color: seleccionado
                              ? Colors.green
                              : null,
                        ),
                        title: Text(
                          nombreEspanol,
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(
                            context,
                            objeto
                                as Map<
                                    String,
                                    dynamic>,
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (resultado != null) {
      setState(() {
        objetoSeleccionado =
            resultado;
      });
    }
  }

  // ==========================================================
  // NOMBRE BONITO
  // ==========================================================

  /// Convierte un nombre tecnico con guiones en texto capitalizado y legible.
  String nombreBonito(String nombre) {
    return nombre
        .replaceAll('-', ' ')
        .split(' ')
        .map(
          (palabra) {
            if (palabra.isEmpty) {
              return palabra;
            }

            return palabra[0].toUpperCase() +
                palabra.substring(1);
          },
        )
        .join(' ');
  }

  // ==========================================================
  // NOMBRES DE ESTADÍSTICAS
  // ==========================================================

  /// Traduce el identificador de una estadistica a su nombre visible.
  String nombreEstadistica(
    String nombre,
  ) {
    switch (nombre) {
      case 'hp':
        return 'PS';

      case 'attack':
        return 'Ataque';

      case 'defense':
        return 'Defensa';

      case 'special-attack':
        return 'At. Especial';

      case 'special-defense':
        return 'Def. Especial';

      case 'speed':
        return 'Velocidad';

      default:
        return nombreBonito(nombre);
    }
  }

  // ==========================================================
  // COLORES DE TIPOS
  // ==========================================================

  /// Devuelve el color usado para representar visualmente un tipo Pokemon.
  Color colorTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'normal':
        return Colors.grey;

      case 'fire':
        return Colors.red;

      case 'water':
        return Colors.blue;

      case 'electric':
        return Colors.amber.shade700;

      case 'grass':
        return Colors.green;

      case 'ice':
        return Colors.cyan;

      case 'fighting':
        return Colors.deepOrange;

      case 'poison':
        return Colors.purple;

      case 'ground':
        return Colors.brown;

      case 'flying':
        return Colors.indigo.shade300;

      case 'psychic':
        return Colors.pink;

      case 'bug':
        return Colors.lightGreen.shade700;

      case 'rock':
        return Colors.brown.shade700;

      case 'ghost':
        return Colors.deepPurple;

      case 'dragon':
        return Colors.indigo;

      case 'dark':
        return Colors.grey.shade800;

      case 'steel':
        return Colors.blueGrey;

      case 'fairy':
        return Colors.pink.shade300;

      default:
        return Colors.grey;
    }
  }

  // ==========================================================
  // ICONOS DE TIPOS
  // ==========================================================

  /// Devuelve el emoji asociado al tipo Pokemon recibido.
  String iconoTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'normal':
        return '⚪';

      case 'fire':
        return '🔥';

      case 'water':
        return '💧';

      case 'electric':
        return '⚡';

      case 'grass':
        return '🌿';

      case 'ice':
        return '❄️';

      case 'fighting':
        return '🥊';

      case 'poison':
        return '☠️';

      case 'ground':
        return '🌎';

      case 'flying':
        return '🪽';

      case 'psychic':
        return '🔮';

      case 'bug':
        return '🐛';

      case 'rock':
        return '🪨';

      case 'ghost':
        return '👻';

      case 'dragon':
        return '🐉';

      case 'dark':
        return '🌑';

      case 'steel':
        return '⚙️';

      case 'fairy':
        return '✨';

      default:
        return '❔';
    }
  }

  // ==========================================================
  // NOMBRE DE TIPO
  // ==========================================================

  /// Traduce el identificador ingles de un tipo Pokemon al espanol.
  String nombreTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'normal':
        return 'Normal';

      case 'fire':
        return 'Fuego';

      case 'water':
        return 'Agua';

      case 'electric':
        return 'Eléctrico';

      case 'grass':
        return 'Planta';

      case 'ice':
        return 'Hielo';

      case 'fighting':
        return 'Lucha';

      case 'poison':
        return 'Veneno';

      case 'ground':
        return 'Tierra';

      case 'flying':
        return 'Volador';

      case 'psychic':
        return 'Psíquico';

      case 'bug':
        return 'Bicho';

      case 'rock':
        return 'Roca';

      case 'ghost':
        return 'Fantasma';

      case 'dragon':
        return 'Dragón';

      case 'dark':
        return 'Siniestro';

      case 'steel':
        return 'Acero';

      case 'fairy':
        return 'Hada';

      default:
        return nombreBonito(tipo);
    }
  }

  // ==========================================================
  // CATEGORÍA DE MOVIMIENTO
  // ==========================================================

  /// Traduce la categoria tecnica de un movimiento a un texto visible.
  String textoCategoriaMovimiento(
    String categoria,
  ) {
    switch (categoria) {
      case 'physical':
        return 'Ataque físico';

      case 'special':
        return 'Ataque especial';

      case 'status':
        return 'Movimiento de estado';

      default:
        return nombreBonito(categoria);
    }
  }

  /// Devuelve el simbolo que representa una categoria de movimiento.
  String iconoCategoriaMovimiento(
    String categoria,
  ) {
    switch (categoria) {
      case 'physical':
        return '⚔️';

      case 'special':
        return '✨';

      case 'status':
        return '🔄';

      default:
        return '❔';
    }
  }

  // ==========================================================
  // CONSTRUIR MOVIMIENTO SELECCIONADO
  // ==========================================================

  /// Construye la tarjeta del slot de movimiento [index].
  /// Muestra un estado vacio, de carga o la informacion completa del ataque,
  /// y permite abrir nuevamente el selector al tocarla.
  Widget construirMovimiento(int index) {
    final movimiento =
        movimientosSeleccionados[index];

    if (movimiento == null) {
      return Card(
        margin:
            const EdgeInsets.only(
          bottom: 12,
        ),
        child: InkWell(
          borderRadius:
              BorderRadius.circular(16),
          onTap: () =>
              seleccionarMovimiento(index),
          child: Padding(
            padding:
                const EdgeInsets.all(18),
            child: Row(
              children: [
                CircleAvatar(
                  child: Text(
                    '${index + 1}',
                  ),
                ),
                const SizedBox(
                  width: 15,
                ),
                const Expanded(
                  child: Text(
                    'Seleccionar movimiento',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(
                  Icons
                      .add_circle_outline,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final detalle =
        detallesMovimientos[index];

    if (detalle == null) {
      return Card(
        margin:
            const EdgeInsets.only(
          bottom: 12,
        ),
        child: Padding(
          padding:
              const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                child: Text(
                  '${index + 1}',
                ),
              ),
              const SizedBox(
                width: 15,
              ),
              const Expanded(
                child: Text(
                  'Cargando movimiento...',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(
                width: 22,
                height: 22,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final nombre =
        detalle['name_es']
                ?.toString() ??
            nombreBonito(
              movimiento['move']
                  ['name']
                  .toString(),
            );

    final tipo =
        detalle['tipo']
                ?.toString() ??
            'normal';

    final categoria =
        detalle['categoria']
                ?.toString() ??
            'status';

    final color =
        colorTipo(tipo);

    final descripcion =
        nivelConocimiento == 'novato'
            ? detalle[
                'descripcion_novato']
            : detalle[
                'descripcion_experto'];

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      clipBehavior:
          Clip.antiAlias,
      child: InkWell(
        onTap: () =>
            seleccionarMovimiento(index),
        child: Column(
          children: [
            Container(
              width:
                  double.infinity,
              padding:
                  const EdgeInsets.all(
                14,
              ),
              decoration:
                  BoxDecoration(
                color:
                    color.withOpacity(
                  0.15,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        color,
                    child: Text(
                      iconoTipo(
                        tipo,
                      ),
                      style:
                          const TextStyle(
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          nombre,
                          style:
                              const TextStyle(
                            fontSize: 17,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Row(
                          children: [
                            Container(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal:
                                    8,
                                vertical:
                                    3,
                              ),
                              decoration:
                                  BoxDecoration(
                                color:
                                    color,
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  20,
                                ),
                              ),
                              child:
                                  Text(
                                nombreTipo(
                                  tipo,
                                ),
                                style:
                                    const TextStyle(
                                  color:
                                      Colors.white,
                                  fontSize:
                                      11,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 7,
                            ),
                            Text(
                              textoCategoriaMovimiento(
                                categoria,
                              ),
                              style:
                                  TextStyle(
                                color: Colors
                                    .grey
                                    .shade700,
                                fontSize:
                                    12,
                                fontWeight:
                                    FontWeight
                                        .w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons
                        .edit_outlined,
                  ),
                ],
              ),
            ),

            Padding(
              padding:
                  const EdgeInsets.all(
                14,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child:
                            _etiquetaMovimiento(
                          'Potencia',
                          detalle[
                              'potencia'],
                        ),
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Expanded(
                        child:
                            _etiquetaMovimiento(
                          'Precisión',
                          detalle[
                              'precision'],
                        ),
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Expanded(
                        child:
                            _etiquetaMovimiento(
                          'PP',
                          detalle['pp'],
                        ),
                      ),
                    ],
                  ),

                  if (descripcion !=
                          null &&
                      descripcion
                          .toString()
                          .trim()
                          .isNotEmpty) ...[
                    const SizedBox(
                      height: 12,
                    ),
                    Align(
                      alignment:
                          Alignment
                              .centerLeft,
                      child: Text(
                        descripcion
                            .toString(),
                        style:
                            const TextStyle(
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(
                    height: 8,
                  ),

                  Align(
                    alignment:
                        Alignment
                            .centerRight,
                    child: Text(
                      'Toca para cambiar',
                      style: TextStyle(
                        fontSize:
                            12,
                        color: Colors
                            .grey
                            .shade600,
                        fontStyle:
                            FontStyle
                                .italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // ETIQUETA DE ESTADÍSTICA DEL MOVIMIENTO
  // ==========================================================

  /// Construye una etiqueta compacta para una propiedad del movimiento.
  /// [titulo] identifica el dato y [valor] contiene su valor formateado.
  Widget _etiquetaMovimiento(
    String titulo,
    dynamic valor,
  ) {
    String texto;

    if (valor == null) {
      texto = '-';
    } else {
      texto = valor.toString();
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        vertical: 9,
        horizontal: 5,
      ),
      decoration:
          BoxDecoration(
        color:
            Colors.grey.shade100,
        borderRadius:
            BorderRadius.circular(
          10,
        ),
      ),
      child: Column(
        children: [
          Text(
            titulo,
            style: TextStyle(
              fontSize: 11,
              color:
                  Colors.grey.shade600,
            ),
          ),
          const SizedBox(
            height: 3,
          ),
          Text(
            texto,
            style:
                const TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  /// Construye la pantalla completa de configuracion del Pokemon del equipo.
  /// Incluye apariencia, habilidad, objeto, movimientos y datos estadisticos.
  @override
  Widget build(BuildContext context) {
    if (cargando ||
        pokemon == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Configurar Pokémon',
          ),
        ),
        body: const Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    final nombre =
        pokemon!['name']
                ?.toString() ??
            widget.nombrePokemon;

    final spriteNormal =
        pokemon!['sprites']
                    ?['front_default']
                ?.toString() ??
            widget.sprite;

    final spriteShiny =
        pokemon!['sprites']
                    ?['front_shiny']
                ?.toString() ??
            spriteNormal;

    final tipos =
        pokemon!['types']
                as List? ??
            [];

    final stats =
        pokemon!['stats']
                as List? ??
            [];

    final nombreHabilidad =
        habilidadSeleccionada?[
                    'ability']
                ?['name_es']
            ?.toString() ??
        habilidadSeleccionada?[
                    'ability']
                ?['name']
            ?.toString();

    final descripcionHabilidad =
        nivelConocimiento ==
                'novato'
            ? habilidadSeleccionada?[
                        'ability']
                    ?[
                    'descripcion_novato']
            : habilidadSeleccionada?[
                        'ability']
                    ?[
                    'descripcion_experto'];

    final nombreObjeto =
        objetoSeleccionado?['item']
                    ?['name_es']
                ?.toString() ??
            objetoSeleccionado?['item']
                    ?['name']
                ?.toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          nombreBonito(
            nombre,
          ),
          style:
              const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body:
          SingleChildScrollView(
        padding:
            const EdgeInsets.all(
          16,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .start,
          children: [
            // ==================================================
            // CABECERA DEL POKÉMON
            // ==================================================

            Card(
              clipBehavior:
                  Clip.antiAlias,
              child: Padding(
                padding:
                    const EdgeInsets
                        .all(18),
                child: Column(
                  children: [
                    // ------------------------------------------
                    // SPRITE CENTRADO
                    // ------------------------------------------

                    SizedBox(
                      width:
                          double.infinity,
                      height: 190,
                      child: Center(
                        child:
                            Image.network(
                          esShiny
                              ? spriteShiny
                              : spriteNormal,
                          width: 180,
                          height: 180,
                          fit: BoxFit
                              .contain,
                          alignment:
                              Alignment
                                  .center,
                          errorBuilder:
                              (
                            context,
                            error,
                            stackTrace,
                          ) {
                            return const Center(
                              child:
                                  Icon(
                                Icons
                                    .image_not_supported,
                                size:
                                    100,
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    Text(
                      nombreBonito(
                        nombre,
                      ),
                      style:
                          const TextStyle(
                        fontSize: 25,
                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment:
                          WrapAlignment
                              .center,
                      children:
                          tipos.map(
                        (tipo) {
                          final nombreTipoPokemon =
                              tipo['type']
                                      ['name']
                                  .toString();

                          final color =
                              colorTipo(
                            nombreTipoPokemon,
                          );

                          return Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal:
                                  12,
                              vertical:
                                  6,
                            ),
                            decoration:
                                BoxDecoration(
                              color:
                                  color,
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                20,
                              ),
                            ),
                            child:
                                Text(
                              '${iconoTipo(nombreTipoPokemon)} ${nombreTipo(nombreTipoPokemon)}',
                              style:
                                  const TextStyle(
                                color:
                                    Colors.white,
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                          );
                        },
                      ).toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            // ==================================================
            // APARIENCIA
            // ==================================================

            const Text(
              'Apariencia',
              style:
                  TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            Card(
              child:
                  Padding(
                padding:
                    const EdgeInsets
                        .all(14),
                child: Row(
                  children: [
                    Expanded(
                      child:
                          RadioListTile<
                              bool>(
                        value:
                            false,
                        groupValue:
                            esShiny,
                        onChanged:
                            (valor) {
                          if (valor ==
                              null) {
                            return;
                          }

                          setState(() {
                            esShiny =
                                valor;
                          });
                        },
                        title:
                            const Text(
                          'Normal',
                        ),
                        contentPadding:
                            EdgeInsets
                                .zero,
                      ),
                    ),
                    Expanded(
                      child:
                          RadioListTile<
                              bool>(
                        value:
                            true,
                        groupValue:
                            esShiny,
                        onChanged:
                            (valor) {
                          if (valor ==
                              null) {
                            return;
                          }

                          setState(() {
                            esShiny =
                                valor;
                          });
                        },
                        title:
                            const Text(
                          'Shiny ✨',
                        ),
                        contentPadding:
                            EdgeInsets
                                .zero,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: 22,
            ),

            // ==================================================
            // ESTADÍSTICAS
            // ==================================================

            const Text(
              'Estadísticas base',
              style:
                  TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            Card(
              child:
                  Padding(
                padding:
                    const EdgeInsets
                        .all(14),
                child: Column(
                  children:
                      stats.map(
                    (stat) {
                      final nombreStat =
                          stat['stat']
                                  ['name']
                              .toString();

                      final valor =
                          stat['base_stat']
                              .toString();

                      return Padding(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          vertical:
                              6,
                        ),
                        child:
                            Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child:
                                  Text(
                                nombreEstadistica(
                                  nombreStat,
                                ),
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 5,
                              child:
                                  LinearProgressIndicator(
                                value:
                                    ((stat['base_stat']
                                                    as num)
                                                .toDouble() /
                                            200)
                                        .clamp(
                                  0.0,
                                  1.0,
                                ),
                                minHeight:
                                    7,
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  10,
                                ),
                              ),
                            ),
                            const SizedBox(
                              width:
                                  10,
                            ),
                            SizedBox(
                              width:
                                  35,
                              child:
                                  Text(
                                valor,
                                textAlign:
                                    TextAlign
                                        .right,
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ).toList(),
                ),
              ),
            ),

            const SizedBox(
              height: 22,
            ),

            // ==================================================
            // HABILIDAD
            // ==================================================

            const Text(
              'Habilidad',
              style:
                  TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            Card(
              child:
                  InkWell(
                borderRadius:
                    BorderRadius
                        .circular(
                  16,
                ),
                onTap:
                    seleccionarHabilidad,
                child:
                    Padding(
                  padding:
                      const EdgeInsets
                          .all(16),
                  child:
                      Row(
                    children: [
                      const Icon(
                        Icons
                            .auto_awesome,
                        size:
                            30,
                      ),
                      const SizedBox(
                        width:
                            14,
                      ),
                      Expanded(
                        child:
                            Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              nombreHabilidad ??
                                  'Seleccionar habilidad',
                              style:
                                  const TextStyle(
                                fontSize:
                                    16,
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                            if (descripcionHabilidad !=
                                    null &&
                                descripcionHabilidad
                                    .toString()
                                    .isNotEmpty) ...[
                              const SizedBox(
                                height:
                                    6,
                              ),
                              Text(
                                descripcionHabilidad
                                    .toString(),
                                style:
                                    TextStyle(
                                  color: Colors
                                      .grey
                                      .shade700,
                                  height:
                                      1.3,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Icon(
                        Icons
                            .chevron_right,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 22,
            ),

            // ==================================================
            // MOVIMIENTOS
            // ==================================================

            const Text(
              'Movimientos',
              style:
                  TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            Text(
              'Puedes seleccionar hasta 4 movimientos diferentes.',
              style:
                  TextStyle(
                color:
                    Colors.grey
                        .shade600,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            construirMovimiento(
              0,
            ),
            construirMovimiento(
              1,
            ),
            construirMovimiento(
              2,
            ),
            construirMovimiento(
              3,
            ),

            const SizedBox(
              height: 10,
            ),

            // ==================================================
            // OBJETO
            // ==================================================

            const Text(
              'Objeto',
              style:
                  TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            Card(
              child:
                  InkWell(
                borderRadius:
                    BorderRadius
                        .circular(
                  16,
                ),
                onTap:
                    seleccionarObjeto,
                child:
                    Padding(
                  padding:
                      const EdgeInsets
                          .all(16),
                  child:
                      Row(
                    children: [
                      const Icon(
                        Icons
                            .inventory_2_outlined,
                        size:
                            30,
                      ),
                      const SizedBox(
                        width:
                            14,
                      ),
                      Expanded(
                        child:
                            Text(
                          nombreObjeto ??
                              'Seleccionar objeto',
                          style:
                              const TextStyle(
                            fontSize:
                                16,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons
                            .chevron_right,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 28,
            ),

            // ==================================================
            // GUARDAR
            // ==================================================

            SizedBox(
              width:
                  double.infinity,
              child:
                  ElevatedButton.icon(
                onPressed:
                    guardando
                        ? null
                        : guardarConfiguracion,
                icon: guardando
                    ? const SizedBox(
                        width:
                            20,
                        height:
                            20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth:
                              2,
                        ),
                      )
                    : const Icon(
                        Icons.save,
                      ),
                label:
                    Text(
                  guardando
                      ? 'Guardando...'
                      : 'Guardar configuración',
                  style:
                      const TextStyle(
                    fontSize:
                        16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                style:
                    ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    vertical:
                        15,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }
}