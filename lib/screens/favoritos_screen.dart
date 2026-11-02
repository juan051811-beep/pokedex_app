
import 'package:flutter/material.dart';

import '../services/favoritos_storage_service.dart';
import '../services/pokemon_service.dart';
import 'pokemon_detail_screen.dart';

// Pantalla para administrar Pokémon favoritos
class FavoritosScreen extends StatefulWidget {
  const FavoritosScreen({super.key});

  @override
  State<FavoritosScreen> createState() =>
      _FavoritosScreenState();
}

class _FavoritosScreenState extends State<FavoritosScreen> {

  // Servicios de almacenamiento y PokéAPI
  final FavoritosStorageService _storage =
      FavoritosStorageService();

  final PokemonService _pokemonService =
      PokemonService();

  // Identificadores de los Pokémon favoritos
  List<int> _favoritos = [];

  // Cache temporal de los detalles consultados
  final Map<int, Future<Map<String, dynamic>>>
      _detallesCache = {};

  // Estados de la pantalla
  bool _cargando = true;
  bool _eliminando = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    // Recuperar favoritos guardados
    _cargarFavoritos();
  }

  // ==========================================
  // 1. CARGAR FAVORITOS
  // ==========================================

  Future<void> _cargarFavoritos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      // Obtener los identificadores guardados
      final favoritos = await _storage.obtenerFavoritos();

      // Ordenar de menor a mayor
      final lista = favoritos.toList()..sort();

      if (!mounted) return;

      setState(() {
        _favoritos = lista;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'No se pudieron cargar los favoritos';
        _cargando = false;
      });
    }
  }

  // ==========================================
  // 2. OBTENER DETALLES DE UN POKÉMON
  // ==========================================

  Future<Map<String, dynamic>> _obtenerDetalle(
    int id,
  ) {
    // Evitar consultar repetidamente el mismo Pokémon
    return _detallesCache.putIfAbsent(
      id,
      () => _pokemonService.obtenerDetallePokemon(id),
    );
  }

  // ==========================================
  // 3. ELIMINAR UN FAVORITO
  // ==========================================

  Future<void> _eliminarFavorito(int id) async {
    if (_eliminando) return;

    setState(() {
      _eliminando = true;
    });

    try {
      // Eliminar del almacenamiento permanente
      await _storage.eliminarFavorito(id);

      if (!mounted) return;

      // Actualizar la lista visible
      setState(() {
        _favoritos.remove(id);
        _eliminando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pokémon eliminado de favoritos',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _eliminando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo eliminar el favorito',
          ),
        ),
      );
    }
  }

  // ==========================================
  // 4. ABRIR DETALLES
  // ==========================================

  Future<void> _abrirDetalle(int id) async {

    // Abrir la pantalla del Pokémon
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PokemonDetailScreen(
          pokemonId: id,
        ),
      ),
    );

    // Al regresar, actualizar los favoritos
    if (mounted) {
      await _cargarFavoritos();
    }
  }

  // ==========================================
  // 5. FORMATEAR NOMBRES
  // ==========================================

  String _formatearNombre(String nombre) {
    return nombre
        .replaceAll('-', ' ')
        .split(' ')
        .map((palabra) {
          if (palabra.isEmpty) return palabra;

          return palabra[0].toUpperCase() +
              palabra.substring(1);
        })
        .join(' ');
  }

  // ==========================================
  // 6. INTERFAZ PRINCIPAL
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      appBar: AppBar(
        title: const Text(
          'Mis Favoritos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        centerTitle: true,

        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar favoritos',
            onPressed: _cargando
                ? null
                : _cargarFavoritos,
          ),

          const SizedBox(width: 8),
        ],
      ),

      body: _construirContenido(),
    );
  }

  // ==========================================
  // 7. CONSTRUIR CONTENIDO
  // ==========================================

  Widget _construirContenido() {

    // Mostrar indicador de carga
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.red,
        ),
      );
    }

    // Manejar errores
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),

            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: _cargarFavoritos,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    // Sin Pokémon favoritos
    if (_favoritos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(25),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.favorite_border,
                color: Colors.red.shade300,
                size: 90,
              ),

              const SizedBox(height: 18),

              const Text(
                'Todavía no tienes favoritos',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Explora la Pokédex y presiona '
                'el corazón de tus Pokémon preferidos.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Mostrar favoritos guardados
    return Column(
      children: [

        // Encabezado con contador
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(18),

          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(18),
          ),

          child: Row(
            children: [
              const Icon(
                Icons.favorite,
                color: Colors.red,
                size: 35,
              ),

              const SizedBox(width: 15),

              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  const Text(
                    'Mi colección de favoritos',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),

                  Text(
                    '${_favoritos.length} Pokémon guardados',
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Lista de favoritos
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
            ),

            itemCount: _favoritos.length,

            itemBuilder: (context, index) {
              return _tarjetaFavorito(
                _favoritos[index],
              );
            },
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 8. TARJETA DE POKÉMON FAVORITO
  // ==========================================

  Widget _tarjetaFavorito(int id) {

    final imagenUrl =
        'https://raw.githubusercontent.com/'
        'PokeAPI/sprites/master/sprites/'
        'pokemon/$id.png';

    return FutureBuilder<Map<String, dynamic>>(
      future: _obtenerDetalle(id),

      builder: (context, snapshot) {

        // Nombre obtenido de la API
        final String nombre = snapshot.hasData
            ? _formatearNombre(
                snapshot.data!['name'] as String,
              )
            : 'Pokémon #$id';

        return Card(
          margin: const EdgeInsets.symmetric(
            vertical: 6,
          ),
          elevation: 2,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),

          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),

            // Abrir detalles al tocar la tarjeta
            onTap: () => _abrirDetalle(id),

            // Imagen del Pokémon
            leading: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.red.shade100,

              child: Image.network(
                imagenUrl,
                width: 55,
                height: 55,
                fit: BoxFit.contain,

                errorBuilder:
                    (context, error, stackTrace) {
                  return const Icon(
                    Icons.catching_pokemon,
                    color: Colors.red,
                  );
                },
              ),
            ),

            // Nombre
            title: Text(
              nombre,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            // Número y estado de carga
            subtitle: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  '#${id.toString().padLeft(4, '0')}',
                ),

                if (snapshot.connectionState ==
                    ConnectionState.waiting)
                  const Text(
                    'Cargando información...',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),

            // Corazón para eliminar favorito
            trailing: IconButton(
              tooltip: 'Quitar de favoritos',

              onPressed: _eliminando
                  ? null
                  : () => _eliminarFavorito(id),

              icon: const Icon(
                Icons.favorite,
                color: Colors.red,
                size: 29,
              ),
            ),
          ),
        );
      },
    );
  }
}
