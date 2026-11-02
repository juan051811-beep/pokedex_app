
class EquipoPokemon {

  // Identificador único del equipo
  final String id;

  // Nombre personalizado del equipo
  final String nombre;

  // Lista de IDs de Pokémon (máximo 6)
  final List<int> pokemonIds;

  // Constructor del equipo
  EquipoPokemon({
    required this.id,
    required this.nombre,
    List<int> pokemonIds = const [],
  }) : pokemonIds = List.unmodifiable(pokemonIds) {

    // Verificar que no tenga más de 6 integrantes
    if (pokemonIds.length > 6) {
      throw ArgumentError(
        'Un equipo no puede tener más de 6 Pokémon',
      );
    }
  }

  // Convertir el equipo a formato JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'pokemonIds': pokemonIds,
    };
  }

  // Reconstruir un equipo desde JSON
  factory EquipoPokemon.fromJson(
    Map<String, dynamic> json,
  ) {
    return EquipoPokemon(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      pokemonIds: (json['pokemonIds'] as List<dynamic>)
          .map((id) => (id as num).toInt())
          .toList(),
    );
  }

  // Crear una copia modificada del equipo
  EquipoPokemon copiarCon({
    String? nombre,
    List<int>? pokemonIds,
  }) {
    return EquipoPokemon(
      id: id,
      nombre: nombre ?? this.nombre,
      pokemonIds: pokemonIds ?? this.pokemonIds,
    );
  }

  // Número actual de integrantes
  int get cantidadPokemon => pokemonIds.length;

  // Comprobar si el equipo está completo
  bool get estaCompleto => pokemonIds.length == 6;
}
