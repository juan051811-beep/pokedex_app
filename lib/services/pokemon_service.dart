
import 'dart:convert';
import 'package:http/http.dart' as http;

class PokemonService {
  // Dirección principal de PokéAPI
  final String baseUrl = 'https://pokeapi.co/api/v2';

  // 1. Obtener Pokémon por bloques
  Future<List<dynamic>> obtenerPokemones({
    int limit = 20,
    int offset = 0,
  }) async {
    final url = Uri.parse(
      '$baseUrl/pokemon?limit=$limit&offset=$offset',
    );

    final respuesta = await http.get(url);

    if (respuesta.statusCode == 200) {
      final datos = jsonDecode(respuesta.body);
      return datos['results'];
    } else {
      throw Exception('Error al obtener los Pokémon');
    }
  }

  // 2. Obtener información detallada
  Future<Map<String, dynamic>> obtenerDetallePokemon(
    int id,
  ) async {
    final url = Uri.parse('$baseUrl/pokemon/$id/');

    final respuesta = await http.get(url);

    if (respuesta.statusCode == 200) {
      return jsonDecode(respuesta.body);
    } else {
      throw Exception('Error al obtener los detalles');
    }
  }

  // 3. Obtener cadena evolutiva
  Future<Map<String, dynamic>> obtenerCadenaEvolutiva(
    String urlEspecie,
  ) async {
    final respuestaEspecie = await http.get(
      Uri.parse(urlEspecie),
    );

    if (respuestaEspecie.statusCode != 200) {
      throw Exception('Error al obtener la especie');
    }

    final datosEspecie = jsonDecode(
      respuestaEspecie.body,
    );

    final String urlEvolucion =
        datosEspecie['evolution_chain']['url'];

    final respuestaEvolucion = await http.get(
      Uri.parse(urlEvolucion),
    );

    if (respuestaEvolucion.statusCode != 200) {
      throw Exception('Error al obtener las evoluciones');
    }

    return jsonDecode(respuestaEvolucion.body);
  }

  // 4. Buscar Pokémon por nombre o número
  Future<Map<String, dynamic>> buscarPokemon(
    String consulta,
  ) async {
    final busqueda = consulta
        .trim()
        .toLowerCase()
        .replaceFirst(RegExp(r'^#'), '');

    if (busqueda.isEmpty) {
      throw Exception('Ingresa un nombre o número');
    }

    final identificador =
        int.tryParse(busqueda)?.toString() ?? busqueda;

    final url = Uri.parse(
      '$baseUrl/pokemon/${Uri.encodeComponent(identificador)}/',
    );

    final respuesta = await http.get(url);

    if (respuesta.statusCode == 200) {
      return jsonDecode(respuesta.body);
    } else if (respuesta.statusCode == 404) {
      throw Exception('Pokémon no encontrado');
    } else {
      throw Exception('Error al buscar el Pokémon');
    }
  }

  // 5. NUEVO: Filtrar Pokémon por tipo
  Future<List<Map<String, dynamic>>> obtenerPokemonPorTipo(
    String tipo,
  ) async {
    final url = Uri.parse(
      '$baseUrl/type/${Uri.encodeComponent(tipo)}/',
    );

    final respuesta = await http.get(url);

    if (respuesta.statusCode != 200) {
      throw Exception('Error al filtrar por tipo');
    }

    final datos = jsonDecode(respuesta.body);

    final List<dynamic> registros = datos['pokemon'];

    // Convertir resultados al formato de nuestro catálogo
    final lista = registros.map((registro) {
      final pokemon = registro['pokemon'];

      return <String, dynamic>{
        'name': pokemon['name'],
        'url': pokemon['url'],
      };
    }).toList();

    return lista;
  }

  // 6. NUEVO: Filtrar Pokémon por generación
  Future<List<Map<String, dynamic>>>
      obtenerPokemonPorGeneracion(int generacion) async {

    final url = Uri.parse(
      '$baseUrl/generation/$generacion/',
    );

    final respuesta = await http.get(url);

    if (respuesta.statusCode != 200) {
      throw Exception('Error al filtrar por generación');
    }

    final datos = jsonDecode(respuesta.body);

    final List<dynamic> especies =
        datos['pokemon_species'];

    // Convertir las especies al formato del catálogo
    final lista = especies.map((especie) {
      final String urlEspecie = especie['url'];

      final id = Uri.parse(urlEspecie)
          .pathSegments
          .where((segmento) => segmento.isNotEmpty)
          .last;

      return <String, dynamic>{
        'name': especie['name'],
        'url': '$baseUrl/pokemon/$id/',
      };
    }).toList();

    return lista;
  }
}
