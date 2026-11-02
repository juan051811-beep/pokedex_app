
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Servicio para obtener y guardar tipos Pokémon
class PokemonTypeService {

  static const String _baseUrl =
      'https://pokeapi.co/api/v2';

  // Claves del almacenamiento local
  static const String _claveTipos =
      'pokemon_tipos_cache_v1';

  static const String _claveFecha =
      'pokemon_tipos_fecha_v1';

  // Actualizar la caché después de 7 días
  static const Duration _duracionCache =
      Duration(days: 7);

  // Almacenamiento permanente
  final SharedPreferencesAsync _prefs =
      SharedPreferencesAsync();

  // Caché temporal en memoria
  Future<Map<int, List<String>>>? _cache;

  // Tipos Pokémon
  static const List<String> _tipos = [
    'normal',
    'fire',
    'water',
    'grass',
    'electric',
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

  // ==========================================
  // 1. OBTENER TIPOS
  // ==========================================

  Future<Map<int, List<String>>> obtenerTiposCatalogo() {

    // Si ya se consultaron durante esta sesión,
    // reutilizar la información.
    return _cache ??= _obtenerTiposConCache().catchError(
      (Object error) {
        // Permitir otro intento si ocurre un error
        _cache = null;
        throw error;
      },
    );
  }

  // ==========================================
  // 2. CONSULTAR ALMACENAMIENTO LOCAL
  // ==========================================

  Future<Map<int, List<String>>>
      _obtenerTiposConCache() async {

    final ahora =
        DateTime.now().millisecondsSinceEpoch;

    try {
      // Recuperar información guardada
      final jsonGuardado =
          await _prefs.getString(_claveTipos);

      final fechaGuardada =
          await _prefs.getInt(_claveFecha);

      if (jsonGuardado != null &&
          fechaGuardada != null) {

        final antiguedad = ahora - fechaGuardada;

        // Comprobar si la caché sigue vigente
        if (antiguedad >= 0 &&
            antiguedad < _duracionCache.inMilliseconds) {

          final datos = jsonDecode(jsonGuardado)
              as Map<String, dynamic>;

          // Reconstruir el mapa de tipos
          final mapa = datos.map((id, tipos) {
            return MapEntry(
              int.parse(id),
              (tipos as List<dynamic>)
                  .map((tipo) => tipo as String)
                  .toList(),
            );
          });

          // Utilizar información almacenada
          return mapa;
        }
      }
    } catch (e) {
      // Si la caché está dañada o no se puede leer,
      // continuamos con la descarga.
    }

    // ==========================================
    // 3. DESCARGAR DATOS ACTUALIZADOS
    // ==========================================

    final mapa = await _descargarTipos();

    // Guardar los resultados para próximas sesiones
    try {
      final datosParaGuardar = mapa.map(
        (id, tipos) => MapEntry(
          id.toString(),
          tipos,
        ),
      );

      await _prefs.setString(
        _claveTipos,
        jsonEncode(datosParaGuardar),
      );

      await _prefs.setInt(
        _claveFecha,
        ahora,
      );
    } catch (e) {
      // Si el almacenamiento falla, los datos
      // descargados seguirán funcionando.
    }

    return mapa;
  }

  // ==========================================
  // 4. DESCARGAR TIPOS DESDE POKÉAPI
  // ==========================================

  Future<Map<int, List<String>>> _descargarTipos() async {

    final Map<int, Set<String>> mapa = {};

    // Consultar grupos de 6 tipos en paralelo
    for (int inicio = 0;
        inicio < _tipos.length;
        inicio += 6) {

      final grupo = _tipos
          .skip(inicio)
          .take(6)
          .toList();

      final respuestas = await Future.wait(
        grupo.map((tipo) async {

          final url = Uri.parse(
            '$_baseUrl/type/$tipo/',
          );

          final respuesta = await http.get(url);

          if (respuesta.statusCode != 200) {
            throw Exception(
              'Error al obtener el tipo $tipo',
            );
          }

          return jsonDecode(respuesta.body)
              as Map<String, dynamic>;
        }),
      );

      // Procesar la información descargada
      for (int i = 0; i < grupo.length; i++) {

        final tipo = grupo[i];

        final registros =
            respuestas[i]['pokemon'] as List<dynamic>;

        for (final registro in registros) {

          final pokemon = registro['pokemon'];

          // Obtener identificador del Pokémon
          final id = int.parse(
            Uri.parse(pokemon['url'] as String)
                .pathSegments
                .where((segmento) => segmento.isNotEmpty)
                .last,
          );

          // Agregar el tipo a su identificador
          mapa.putIfAbsent(
            id,
            () => <String>{},
          ).add(tipo);
        }
      }
    }

    // Convertir conjuntos a listas
    return mapa.map(
      (id, tipos) => MapEntry(
        id,
        tipos.toList(),
      ),
    );
  }
}
