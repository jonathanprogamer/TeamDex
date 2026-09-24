import 'dart:convert';
import 'package:http/http.dart' as http;

class PokeApiService {
  // ======================================================
  // POKÉMON POR REGIÓN
  // ======================================================

  /// Consulta una pagina de Pokemon y devuelve sus IDs, nombres y sprites.
  ///
  /// [inicio] indica el primer numero de la pagina y [cantidad] la cantidad de
  /// resultados solicitados. Lanza una excepcion si PokeAPI responde con error.
  Future<List<Map<String, dynamic>>> obtenerPokemonsPorRegion(
    int inicio,
    int cantidad,
  ) async {
    final url = Uri.parse(
      'https://pokeapi.co/api/v2/pokemon?offset=${inicio - 1}&limit=$cantidad',
    );

    final respuesta = await http.get(url);

    if (respuesta.statusCode != 200) {
      throw Exception(
        'No se pudieron obtener los Pokémon',
      );
    }

    final datos = jsonDecode(respuesta.body);

    final resultados = datos['results'] as List;

    return resultados.asMap().entries.map((entry) {
      final index = entry.key;
      final pokemon = entry.value;

      final numero = inicio + index;

      return {
        'id': numero,
        'nombre': pokemon['name'],
        'sprite':
            'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$numero.png',
      };
    }).toList();
  }

  // ======================================================
  // DETALLES DE POKÉMON
  // ======================================================

  /// Obtiene los datos completos de un Pokemon desde PokeAPI.
  ///
  /// Ademas de la respuesta principal, agrega sprite shiny, grito, descripcion
  /// en espanol y nombres y explicaciones traducidas de sus habilidades.
  Future<Map<String, dynamic>> obtenerDetallesPokemon(
    int id,
  ) async {
    final url = Uri.parse(
      'https://pokeapi.co/api/v2/pokemon/$id',
    );

    final respuesta = await http.get(url);

    if (respuesta.statusCode != 200) {
      throw Exception(
        'No se pudo obtener el Pokémon',
      );
    }

    final datos = jsonDecode(respuesta.body);

    // ====================================================
    // SPRITE SHINY
    // ====================================================

    datos['sprite_shiny'] =
        datos['sprites']['front_shiny'];

    // ====================================================
    // GRITO DEL POKÉMON
    // ====================================================

    datos['cry'] =
        datos['cries']['latest'];

    // ====================================================
    // DESCRIPCIÓN DEL POKÉMON
    // ====================================================

    final especieUrl =
        datos['species']['url'];

    final respuestaEspecie = await http.get(
      Uri.parse(especieUrl),
    );

    if (respuestaEspecie.statusCode == 200) {
      final especie =
          jsonDecode(respuestaEspecie.body);

      String? descripcion;

      final entries =
          especie['flavor_text_entries'] as List;

      for (final entry in entries) {
        if (entry['language']['name'] == 'es') {
          descripcion =
              entry['flavor_text'];
          break;
        }
      }

      datos['descripcion'] =
          descripcion;
    }

    // ====================================================
    // INFORMACIÓN DE LAS HABILIDADES
    // ====================================================

    final habilidades =
        datos['abilities'] as List;

    for (final habilidad in habilidades) {
      final habilidadUrl =
          habilidad['ability']['url'];

      try {
        final respuestaHabilidad =
            await http.get(
          Uri.parse(habilidadUrl),
        );

        if (respuestaHabilidad.statusCode == 200) {
          final datosHabilidad =
              jsonDecode(
            respuestaHabilidad.body,
          );

          // ----------------------------------------------
          // NOMBRE EN ESPAÑOL
          // ----------------------------------------------

          final nombres =
              datosHabilidad['names'] as List;

          String? nombreEspanol;

          for (final nombre in nombres) {
            if (nombre['language']['name'] ==
                'es') {
              nombreEspanol =
                  nombre['name'];
              break;
            }
          }

          if (nombreEspanol != null) {
            habilidad['ability']
                ['name_es'] = nombreEspanol;
          }

          // ----------------------------------------------
          // DESCRIPCIÓN EN ESPAÑOL
          // ----------------------------------------------

          final descripcion =
              obtenerEfectoEspanol(
            datosHabilidad['effect_entries'],
          );

          if (descripcion != null) {
            habilidad['ability']
                ['descripcion_es'] =
                descripcion;

            habilidad['ability']
                ['descripcion_experto'] =
                descripcion;

            habilidad['ability']
                ['descripcion_novato'] =
                convertirANovato(
              descripcion,
            );
          }
        }
      } catch (e) {
        // Si falla una habilidad,
        // continuamos con las demás.
      }
    }

    return datos;
  }

  // ======================================================
  // DETALLES DE UN MOVIMIENTO
  // ======================================================

  /// Obtiene y normaliza la informacion de un movimiento Pokemon.
  ///
  /// Incluye nombre, descripcion, tipo, categoria, potencia, precision y PP,
  /// junto con versiones de la explicacion para los modos experto y novato.
  Future<Map<String, dynamic>> obtenerDetallesMovimiento(
    String nombreMovimiento,
  ) async {
    final url = Uri.parse(
      'https://pokeapi.co/api/v2/move/$nombreMovimiento',
    );

    final respuesta = await http.get(url);

    if (respuesta.statusCode != 200) {
      throw Exception(
        'No se pudo obtener el movimiento',
      );
    }

    final datos = jsonDecode(respuesta.body);

    // ====================================================
    // NOMBRE EN ESPAÑOL
    // ====================================================

    final nombres =
        datos['names'] as List;

    String nombreEspanol =
        datos['name'].toString();

    for (final nombre in nombres) {
      if (nombre['language']['name'] == 'es') {
        nombreEspanol =
            nombre['name'].toString();
        break;
      }
    }

    datos['name_es'] =
        nombreEspanol;

    // ====================================================
    // DESCRIPCIÓN
    // ====================================================

    String? descripcion;

    final efectos =
        datos['effect_entries'] as List;

    descripcion =
        obtenerEfectoEspanol(
      efectos,
    );

    // Si no encontramos una descripción
    // en effect_entries, intentamos usar
    // flavor_text_entries.
    if (descripcion == null) {
      final textos =
          datos['flavor_text_entries'] as List;

      for (final texto in textos) {
        if (texto['language']['name'] == 'es') {
          descripcion =
              texto['flavor_text']
                  .toString()
                  .replaceAll(
                    '\n',
                    ' ',
                  )
                  .replaceAll(
                    '\f',
                    ' ',
                  );
          break;
        }
      }
    }

    datos['descripcion_es'] =
        descripcion;

    datos['descripcion_experto'] =
        descripcion;

    datos['descripcion_novato'] =
        descripcion == null
            ? null
            : convertirANovato(
                descripcion,
              );

    // ====================================================
    // INFORMACIÓN DEL MOVIMIENTO
    // ====================================================

    datos['tipo'] =
        datos['type']['name'];

    datos['categoria'] =
        datos['damage_class']['name'];

    datos['potencia'] =
        datos['power'];

    datos['precision'] =
        datos['accuracy'];

    datos['pp'] =
        datos['pp'];

    return datos;
  }

  // ======================================================
  // DETALLES DE UN OBJETO
  // ======================================================

  /// Obtiene el nombre y la descripcion traducidos de un objeto Pokemon.
  ///
  /// Usa el efecto en espanol y, si no existe, intenta recuperar el texto
  /// descriptivo alternativo. Tambien prepara una explicacion simplificada.
  Future<Map<String, dynamic>> obtenerDetallesObjeto(
    String nombreObjeto,
  ) async {
    final url = Uri.parse(
      'https://pokeapi.co/api/v2/item/$nombreObjeto',
    );

    final respuesta = await http.get(url);

    if (respuesta.statusCode != 200) {
      throw Exception(
        'No se pudo obtener el objeto',
      );
    }

    final datos = jsonDecode(respuesta.body);

    // ====================================================
    // NOMBRE EN ESPAÑOL
    // ====================================================

    final nombres =
        datos['names'] as List;

    String nombreEspanol =
        datos['name'].toString();

    for (final nombre in nombres) {
      if (nombre['language']['name'] == 'es') {
        nombreEspanol =
            nombre['name'].toString();
        break;
      }
    }

    datos['name_es'] =
        nombreEspanol;

    // ====================================================
    // DESCRIPCIÓN
    // ====================================================

    String? descripcion;

    final efectos =
        datos['effect_entries'] as List;

    descripcion =
        obtenerEfectoEspanol(
      efectos,
    );

    // Si no encontramos efecto en español,
    // buscamos el texto descriptivo.
    if (descripcion == null) {
      final textos =
          datos['flavor_text_entries'] as List;

      for (final texto in textos) {
        if (texto['language']['name'] == 'es') {
          descripcion =
              texto['flavor_text']
                  .toString()
                  .replaceAll(
                    '\n',
                    ' ',
                  )
                  .replaceAll(
                    '\f',
                    ' ',
                  );
          break;
        }
      }
    }

    datos['descripcion_es'] =
        descripcion;

    datos['descripcion_experto'] =
        descripcion;

    datos['descripcion_novato'] =
        descripcion == null
            ? null
            : convertirANovato(
                descripcion,
              );

    return datos;
  }

  // ======================================================
  // DETALLES DE UN TIPO
  // ======================================================

  /// Solicita a PokeAPI la informacion completa del tipo [nombreTipo].
  ///
  /// Devuelve el JSON decodificado o lanza una excepcion si la peticion falla.
  Future<Map<String, dynamic>> obtenerDetallesTipo(
    String nombreTipo,
  ) async {
    final url = Uri.parse(
      'https://pokeapi.co/api/v2/type/$nombreTipo',
    );

    final respuesta = await http.get(url);

    if (respuesta.statusCode != 200) {
      throw Exception(
        'No se pudo obtener el tipo',
      );
    }

    return jsonDecode(respuesta.body);
  }

  // ======================================================
  // OBTENER EFECTO EN ESPAÑOL
  // ======================================================

  /// Busca el efecto en espanol dentro de una lista de respuestas de la API.
  ///
  /// Prefiere el campo `effect` y usa `short_effect` como alternativa. Limpia
  /// el texto encontrado y devuelve `null` si la entrada no es una lista o no
  /// contiene un efecto utilizable en espanol.
  String? obtenerEfectoEspanol(
    dynamic efectos,
  ) {
    if (efectos is! List) {
      return null;
    }

    for (final efecto in efectos) {
      if (efecto['language']['name'] == 'es') {
        final texto =
            efecto['effect']?.toString();

        if (texto != null &&
            texto.trim().isNotEmpty) {
          return limpiarTexto(
            texto,
          );
        }

        final textoCorto =
            efecto['short_effect']
                ?.toString();

        if (textoCorto != null &&
            textoCorto.trim().isNotEmpty) {
          return limpiarTexto(
            textoCorto,
          );
        }
      }
    }

    return null;
  }

  // ======================================================
  // LIMPIAR TEXTOS DE POKÉAPI
  // ======================================================

  /// Normaliza un texto de PokeAPI para mostrarlo correctamente en pantalla.
  ///
  /// Sustituye saltos de linea y caracteres de formulario por espacios,
  /// elimina espacios duplicados y recorta los extremos del texto.
  String limpiarTexto(String texto) {
    return texto
        .replaceAll(
          '\n',
          ' ',
        )
        .replaceAll(
          '\f',
          ' ',
        )
        .replaceAll(
          '  ',
          ' ',
        )
        .trim();
  }

  // ======================================================
  // CONVERTIR EXPLICACIÓN A MODO NOVATO
  // ======================================================

  /// Simplifica terminos tecnicos para el modo de explicacion novato.
  ///
  /// Aplica sustituciones sobre [texto] para hacerlo mas comprensible sin
  /// cambiar el contenido principal de la explicacion.
  String convertirANovato(String texto) {
    String resultado = texto;

    final reemplazos = <String, String>{
      'este Pokémon':
          'este Pokémon',
      'Pokémon':
          'Pokémon',
      'usuario':
          'Pokémon que usa el movimiento',
      'objetivo':
          'Pokémon rival',
      'rival':
          'Pokémon rival',
      'daño':
          'daño',
      'inflige':
          'hace',
      'reduce':
          'baja',
      'aumenta':
          'sube',
      'aumentar':
          'subir',
      'reducir':
          'bajar',
      'estadística':
          'estadística',
      'estadísticas':
          'estadísticas',
      'probabilidad':
          'posibilidad',
      'afecta':
          'afecta',
      'efecto secundario':
          'efecto adicional',
      'inmune':
          'no recibe daño',
      'inmunidad':
          'protección contra ese efecto',
      'potencia':
          'fuerza',
      'precisión':
          'posibilidad de acertar',
      'PP':
          'usos disponibles',
    };

    reemplazos.forEach(
      (original, sencillo) {
        resultado = resultado.replaceAll(
          original,
          sencillo,
        );
      },
    );

    return resultado;
  }
}