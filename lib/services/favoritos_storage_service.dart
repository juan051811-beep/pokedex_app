
import 'package:shared_preferences/shared_preferences.dart';

// Servicio para almacenar los Pokémon favoritos
class FavoritosStorageService {

  // Almacenamiento local
  final SharedPreferencesAsync _prefs =
      SharedPreferencesAsync();

  // Clave utilizada para guardar los favoritos
  static const String _claveFavoritos =
      'mis_pokemon_favoritos';

  // ==========================================
  // 1. OBTENER TODOS LOS FAVORITOS
  // ==========================================

  Future<Set<int>> obtenerFavoritos() async {

    // Recuperar los identificadores guardados
    final lista = await _prefs.getStringList(
      _claveFavoritos,
    );

    // Si todavía no existen favoritos
    if (lista == null) {
      return <int>{};
    }

    // Convertir los identificadores a números
    return lista
        .map((id) => int.tryParse(id))
        .whereType<int>()
        .toSet();
  }

  // ==========================================
  // 2. GUARDAR TODOS LOS FAVORITOS
  // ==========================================

  Future<void> guardarFavoritos(
    Set<int> favoritos,
  ) async {

    // Convertir los IDs a texto
    final lista = favoritos
        .map((id) => id.toString())
        .toList();

    // Guardar permanentemente
    await _prefs.setStringList(
      _claveFavoritos,
      lista,
    );
  }

  // ==========================================
  // 3. AGREGAR UN POKÉMON A FAVORITOS
  // ==========================================

  Future<void> agregarFavorito(int pokemonId) async {

    // Recuperar favoritos actuales
    final favoritos = await obtenerFavoritos();

    // Agregar el nuevo Pokémon
    favoritos.add(pokemonId);

    // Guardar cambios
    await guardarFavoritos(favoritos);
  }

  // ==========================================
  // 4. ELIMINAR UN POKÉMON DE FAVORITOS
  // ==========================================

  Future<void> eliminarFavorito(int pokemonId) async {

    final favoritos = await obtenerFavoritos();

    // Quitar el Pokémon
    favoritos.remove(pokemonId);

    // Guardar cambios
    await guardarFavoritos(favoritos);
  }

  // ==========================================
  // 5. COMPROBAR SI ES FAVORITO
  // ==========================================

  Future<bool> esFavorito(int pokemonId) async {

    final favoritos = await obtenerFavoritos();

    return favoritos.contains(pokemonId);
  }

  // ==========================================
  // 6. ALTERNAR ESTADO DE FAVORITO
  // ==========================================

  Future<bool> alternarFavorito(int pokemonId) async {

    final favoritos = await obtenerFavoritos();

    if (favoritos.contains(pokemonId)) {

      // Si ya es favorito, eliminarlo
      favoritos.remove(pokemonId);

      await guardarFavoritos(favoritos);

      return false;

    } else {

      // Si no es favorito, agregarlo
      favoritos.add(pokemonId);

      await guardarFavoritos(favoritos);

      return true;
    }
  }
}
