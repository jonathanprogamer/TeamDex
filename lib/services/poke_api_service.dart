import 'dart:convert';
import 'package:http/http.dart' as http;

class PokeApiService {
  Future<List<Map<String, dynamic>>> obtenerPokemonsPorRegion(
    int inicio,
    int cantidad,
  ) async {
    final url = Uri.parse(
      'https://pokeapi.co/api/v2/pokemon?offset=${inicio - 1}&limit=$cantidad',
    );

    final respuesta = await http.get(url);

    if (respuesta.statusCode != 200) {
      throw Exception('No se pudieron obtener los Pokémon');
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

  Future<Map<String, dynamic>> obtenerDetallesPokemon(
    int id,
  ) async {
    final url = Uri.parse(
      'https://pokeapi.co/api/v2/pokemon/$id',
    );

    final respuesta = await http.get(url);

    if (respuesta.statusCode != 200) {
      throw Exception('No se pudo obtener el Pokémon');
    }

    final datos = jsonDecode(respuesta.body);

    // Obtener información de la especie
    final especieUrl = datos['species']['url'];

    final respuestaEspecie = await http.get(
      Uri.parse(especieUrl),
    );

    if (respuestaEspecie.statusCode == 200) {
      final especie = jsonDecode(respuestaEspecie.body);

      String? descripcion;

      final entries = especie['flavor_text_entries'] as List;

      for (final entry in entries) {
        if (entry['language']['name'] == 'es') {
          descripcion = entry['flavor_text'];
          break;
        }
      }

      datos['descripcion'] = descripcion;
    }

    return datos;
  }
}