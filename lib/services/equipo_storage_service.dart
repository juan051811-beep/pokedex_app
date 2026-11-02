
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/equipo_pokemon.dart';

// Servicio para guardar y recuperar equipos Pokémon
class EquipoStorageService {

  // Instancia del almacenamiento local
  final SharedPreferencesAsync _prefs =
      SharedPreferencesAsync();

  // Clave utilizada para almacenar los equipos
  static const String _claveEquipos = 'mis_equipos_pokemon';

  // 1. GUARDAR EQUIPOS
  Future<void> guardarEquipos(
    List<EquipoPokemon> equipos,
  ) async {

    // Convertir cada equipo a JSON
    final listaJson = equipos
        .map((equipo) => equipo.toJson())
        .toList();

    // Convertir toda la lista a texto JSON
    final String datos = jsonEncode(listaJson);

    // Guardar los equipos localmente
    await _prefs.setString(_claveEquipos, datos);
  }

  // 2. CARGAR EQUIPOS GUARDADOS
  Future<List<EquipoPokemon>> cargarEquipos() async {

    // Leer los equipos almacenados
    final String? datos =
        await _prefs.getString(_claveEquipos);

    // Si no hay equipos, devolver una lista vacía
    if (datos == null || datos.isEmpty) {
      return [];
    }

    // Convertir el texto JSON a una lista
    final List<dynamic> listaJson = jsonDecode(datos);

    // Reconstruir los objetos EquipoPokemon
    return listaJson.map((json) {
      return EquipoPokemon.fromJson(
        Map<String, dynamic>.from(json),
      );
    }).toList();
  }

  // 3. ELIMINAR TODOS LOS EQUIPOS GUARDADOS
  Future<void> eliminarTodosLosEquipos() async {

    // Eliminar únicamente los datos de equipos
    await _prefs.remove(_claveEquipos);
  }
}
