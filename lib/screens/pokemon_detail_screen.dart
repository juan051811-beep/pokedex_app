
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

import '../services/pokemon_service.dart';
import '../services/favoritos_storage_service.dart';

// Pantalla de detalles de un Pokémon
class PokemonDetailScreen extends StatefulWidget {
  final int pokemonId;

  const PokemonDetailScreen({
    super.key,
    required this.pokemonId,
  });

  @override
  State<PokemonDetailScreen> createState() =>
      _PokemonDetailScreenState();
}

class _PokemonDetailScreenState
    extends State<PokemonDetailScreen> {

  // Servicios
  final PokemonService _servicio = PokemonService();
  final AudioPlayer _reproductor = AudioPlayer();

  final FavoritosStorageService _favoritosService =
      FavoritosStorageService();

  // Información del Pokémon
  late Future<Map<String, dynamic>> _detalle;
  late Future<Map<String, dynamic>> _evoluciones;

  // Estados de favoritos
  bool _esFavorito = false;
  bool _cargandoFavorito = true;

  // NUEVO: Estado del modo Shiny
  bool _mostrarShiny = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _cargarEstadoFavorito();
  }

  // ==========================================
  // 1. CARGAR INFORMACIÓN
  // ==========================================

  void _cargarDatos() {
    _detalle = _servicio.obtenerDetallePokemon(
      widget.pokemonId,
    );

    _evoluciones = _detalle.then((pokemon) {
      final urlEspecie =
          pokemon['species']['url'] as String;

      return _servicio.obtenerCadenaEvolutiva(
        urlEspecie,
      );
    });
  }

  // ==========================================
  // 2. CARGAR FAVORITOS
  // ==========================================

  Future<void> _cargarEstadoFavorito() async {
    try {
      final resultado = await _favoritosService.esFavorito(
        widget.pokemonId,
      );

      if (!mounted) return;

      setState(() {
        _esFavorito = resultado;
        _cargandoFavorito = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cargandoFavorito = false;
      });

      _mostrarMensaje(
        'No se pudo comprobar el favorito',
      );
    }
  }

  // ==========================================
  // 3. AGREGAR O QUITAR FAVORITOS
  // ==========================================

  Future<void> _alternarFavorito() async {
    if (_cargandoFavorito) return;

    setState(() {
      _cargandoFavorito = true;
    });

    try {
      final nuevoEstado =
          await _favoritosService.alternarFavorito(
        widget.pokemonId,
      );

      if (!mounted) return;

      setState(() {
        _esFavorito = nuevoEstado;
        _cargandoFavorito = false;
      });

      _mostrarMensaje(
        nuevoEstado
            ? 'Pokémon agregado a favoritos ❤️'
            : 'Pokémon eliminado de favoritos',
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cargandoFavorito = false;
      });

      _mostrarMensaje(
        'No se pudo guardar el favorito',
      );
    }
  }

  // ==========================================
  // 4. NUEVO: CAMBIAR ENTRE NORMAL Y SHINY
  // ==========================================

  void _alternarShiny() {
    setState(() {
      _mostrarShiny = !_mostrarShiny;
    });
  }

  // ==========================================
  // 5. MOSTRAR MENSAJES
  // ==========================================

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ==========================================
  // 6. REPRODUCIR SONIDO
  // ==========================================

  Future<void> _reproducirGrito(String? url) async {
    if (url == null || url.isEmpty) {
      _mostrarMensaje('Sonido no disponible');
      return;
    }

    try {
      await _reproductor.stop();
      await _reproductor.play(UrlSource(url));
    } catch (e) {
      if (!mounted) return;

      _mostrarMensaje(
        'Error al reproducir el sonido',
      );
    }
  }

  // ==========================================
  // 7. COLORES POR TIPO
  // ==========================================

  Color _colorTipo(String tipo) {
    const colores = {
      'normal': Colors.grey,
      'fire': Colors.orange,
      'water': Colors.blue,
      'grass': Colors.green,
      'electric': Colors.amber,
      'ice': Colors.cyan,
      'fighting': Colors.red,
      'poison': Colors.purple,
      'ground': Colors.brown,
      'flying': Colors.indigo,
      'psychic': Colors.pink,
      'bug': Colors.lightGreen,
      'rock': Colors.blueGrey,
      'ghost': Colors.deepPurple,
      'dragon': Colors.deepOrange,
      'dark': Colors.black87,
      'steel': Colors.blueGrey,
      'fairy': Colors.pinkAccent,
    };

    return colores[tipo] ?? Colors.red;
  }

  // Formatear nombres
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
  // 8. OBTENER RUTAS EVOLUTIVAS
  // ==========================================

  List<List<Map<String, dynamic>>> _obtenerRutasEvolutivas(
    Map<String, dynamic> datos,
  ) {
    final rutas = <List<Map<String, dynamic>>>[];

    void recorrer(
      Map<String, dynamic> nodo,
      List<Map<String, dynamic>> rutaActual,
    ) {
      final especie =
          nodo['species'] as Map<String, dynamic>;

      final nombre = especie['name'] as String;
      final url = especie['url'] as String;

      final id = int.parse(
        Uri.parse(url)
            .pathSegments
            .where((segmento) => segmento.isNotEmpty)
            .last,
      );

      final nuevaRuta = [
        ...rutaActual,
        {
          'id': id,
          'nombre': nombre,
        },
      ];

      final siguientes =
          nodo['evolves_to'] as List<dynamic>? ?? [];

      if (siguientes.isEmpty) {
        rutas.add(nuevaRuta);
      } else {
        for (final siguiente in siguientes) {
          recorrer(
            Map<String, dynamic>.from(siguiente),
            nuevaRuta,
          );
        }
      }
    }

    recorrer(
      Map<String, dynamic>.from(datos['chain']),
      [],
    );

    return rutas;
  }

  // ==========================================
  // 9. MOSTRAR EVOLUCIONES
  // ==========================================

  Widget _construirEvoluciones() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _evoluciones,
      builder: (context, snapshot) {

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(
                color: Colors.red,
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Text(
            'No se pudieron cargar las evoluciones',
          );
        }

        final rutas = _obtenerRutasEvolutivas(
          snapshot.data!,
        );

        if (rutas.isEmpty) {
          return const Text(
            'No hay evoluciones disponibles',
          );
        }

        if (rutas.length == 1 &&
            rutas.first.length == 1) {
          return const Text(
            'Este Pokémon no tiene evoluciones registradas.',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              'Cadena evolutiva',
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 15),

            for (final ruta in rutas)
              Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (int i = 0; i < ruta.length; i++) ...[

                        if (i > 0)
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                            child: Icon(
                              Icons.arrow_forward,
                              color: Colors.red,
                              size: 26,
                            ),
                          ),

                        _tarjetaEvolucion(
                          ruta[i]['id'] as int,
                          ruta[i]['nombre'] as String,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // Tarjeta de una evolución
  Widget _tarjetaEvolucion(int id, String nombre) {
    final imagenUrl =
        'https://raw.githubusercontent.com/PokeAPI/sprites/'
        'master/sprites/pokemon/other/official-artwork/$id.png';

    return Container(
      width: 110,
      padding: const EdgeInsets.all(10),

      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.red.shade100,
        ),
      ),

      child: Column(
        children: [
          Image.network(
            imagenUrl,
            width: 85,
            height: 85,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.catching_pokemon,
                size: 70,
                color: Colors.red,
              );
            },
          ),

          const SizedBox(height: 8),

          Text(
            _formatearNombre(nombre),
            maxLines: 2,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            '#${id.toString().padLeft(4, '0')}',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _reproductor.dispose();
    super.dispose();
  }

  // ==========================================
  // 10. INTERFAZ PRINCIPAL
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      appBar: AppBar(
        title: const Text('Información Pokémon'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        centerTitle: true,

        // Botón de favoritos
        actions: [
          IconButton(
            tooltip: _esFavorito
                ? 'Quitar de favoritos'
                : 'Agregar a favoritos',

            onPressed: _cargandoFavorito
                ? null
                : _alternarFavorito,

            icon: Icon(
              _esFavorito
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: _esFavorito
                  ? Colors.white
                  : Colors.white70,
              size: 30,
            ),
          ),

          const SizedBox(width: 8),
        ],
      ),

      body: FutureBuilder<Map<String, dynamic>>(
        future: _detalle,

        builder: (context, snapshot) {

          // Cargando información
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.red,
              ),
            );
          }

          // Error de conexión
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Error al cargar el Pokémon'),

                  const SizedBox(height: 12),

                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _cargarDatos();
                      });
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text('Información no disponible'),
            );
          }

          final pokemon = snapshot.data!;

          final String nombre =
              _formatearNombre(pokemon['name']);

          final int id = pokemon['id'];

          final List<dynamic> tipos = pokemon['types'];
          final List<dynamic> habilidades =
              pokemon['abilities'];
          final List<dynamic> estadisticas =
              pokemon['stats'];

          final double altura =
              (pokemon['height'] as num) / 10;

          final double peso =
              (pokemon['weight'] as num) / 10;

          // ==================================
          // NUEVO: IMÁGENES NORMALES Y SHINY
          // ==================================

          final sprites = pokemon['sprites'];

          // Artwork normal
          final String? artworkNormal =
              sprites?['other']
                  ?['official-artwork']?['front_default'];

          // Artwork Shiny
          final String? artworkShiny =
              sprites?['other']
                  ?['official-artwork']?['front_shiny'];

          // Sprite normal
          final String? spriteNormal =
              sprites?['front_default'];

          // Sprite Shiny
          final String? spriteShiny =
              sprites?['front_shiny'];

          // Comprobar disponibilidad de Shiny
          final bool shinyDisponible =
              artworkShiny != null ||
              spriteShiny != null;

          // Seleccionar imagen según el modo
          final String? imagenPrincipal = _mostrarShiny
              ? (artworkShiny ??
                  spriteShiny ??
                  artworkNormal ??
                  spriteNormal)
              : (artworkNormal ?? spriteNormal);

          // Seleccionar sprite según el modo
          final String? spriteSeleccionado = _mostrarShiny
              ? (spriteShiny ??
                  artworkShiny ??
                  spriteNormal)
              : spriteNormal;

          // Sonido
          final String? grito =
              pokemon['cries']?['latest'] ??
              pokemon['cries']?['legacy'];

          // Color principal
          final String tipoPrincipal =
              tipos.first['type']['name'];

          final Color colorPrincipal =
              _colorTipo(tipoPrincipal);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,

              children: [

                // ==================================
                // CABECERA DEL POKÉMON
                // ==================================

                Container(
                  padding: const EdgeInsets.all(20),

                  decoration: BoxDecoration(
                    color: colorPrincipal,
                    borderRadius:
                        const BorderRadius.vertical(
                      bottom: Radius.circular(30),
                    ),
                  ),

                  child: Column(
                    children: [

                      // Número
                      Text(
                        '#${id.toString().padLeft(4, '0')}',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Nombre
                      Text(
                        nombre,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // NUEVO: Indicador del modo Shiny
                      if (_mostrarShiny && shinyDisponible)
                        const Chip(
                          avatar: Icon(
                            Icons.auto_awesome,
                            color: Colors.amber,
                          ),
                          label: Text(
                            'VERSIÓN SHINY',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: Colors.white,
                        ),

                      const SizedBox(height: 12),

                      // ==================================
                      // NUEVO: IMAGEN CON ANIMACIÓN
                      // ==================================

                      AnimatedSwitcher(
                        duration: const Duration(
                          milliseconds: 350,
                        ),

                        child: imagenPrincipal != null
                            ? Image.network(
                                imagenPrincipal,

                                key: ValueKey(
                                  imagenPrincipal,
                                ),

                                height: 220,
                                fit: BoxFit.contain,

                                errorBuilder:
                                    (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.catching_pokemon,
                                    size: 150,
                                    color: Colors.white,
                                  );
                                },
                              )
                            : const Icon(
                                Icons.catching_pokemon,
                                key: ValueKey('sin-imagen'),
                                size: 150,
                                color: Colors.white,
                              ),
                      ),

                      const SizedBox(height: 20),

                      // ==================================
                      // NUEVO: BOTÓN SHINY
                      // ==================================

                      ElevatedButton.icon(
                        onPressed: shinyDisponible
                            ? _alternarShiny
                            : null,

                        icon: Icon(
                          _mostrarShiny
                              ? Icons.refresh
                              : Icons.auto_awesome,
                        ),

                        label: Text(
                          !shinyDisponible
                              ? 'Shiny no disponible'
                              : _mostrarShiny
                                  ? 'Ver versión normal'
                                  : 'Activar modo Shiny ✨',
                        ),

                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: colorPrincipal,

                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 14,
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // Tipos Pokémon
                      Wrap(
                        spacing: 10,
                        runSpacing: 5,

                        children: tipos.map<Widget>((tipo) {
                          final nombreTipo =
                              tipo['type']['name']
                                  as String;

                          return Chip(
                            label: Text(
                              _formatearNombre(nombreTipo),
                            ),

                            backgroundColor: Colors.white,

                            labelStyle: TextStyle(
                              color: _colorTipo(nombreTipo),
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 18),

                      // Sonido
                      ElevatedButton.icon(
                        onPressed: () {
                          _reproducirGrito(grito);
                        },

                        icon: const Icon(Icons.volume_up),

                        label: const Text(
                          'Escuchar grito',
                        ),

                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: colorPrincipal,

                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ==================================
                // INFORMACIÓN GENERAL
                // ==================================

                _seccion(
                  'Información general',
                  Column(
                    children: [
                      _dato(
                        'Altura',
                        '${altura.toStringAsFixed(1)} m',
                      ),

                      _dato(
                        'Peso',
                        '${peso.toStringAsFixed(1)} kg',
                      ),
                    ],
                  ),
                ),

                // ==================================
                // HABILIDADES
                // ==================================

                _seccion(
                  'Habilidades',
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,

                    children: habilidades.map<Widget>(
                      (habilidad) {
                        final nombreHabilidad =
                            habilidad['ability']['name']
                                as String;

                        return Chip(
                          avatar: const Icon(
                            Icons.auto_awesome,
                            size: 18,
                          ),

                          label: Text(
                            _formatearNombre(nombreHabilidad),
                          ),
                        );
                      },
                    ).toList(),
                  ),
                ),

                // ==================================
                // ESTADÍSTICAS BASE
                // ==================================

                _seccion(
                  'Estadísticas base',
                  Column(
                    children: estadisticas.map<Widget>(
                      (estadistica) {

                        final String nombreStat =
                            estadistica['stat']['name'];

                        final int valor =
                            estadistica['base_stat'];

                        return Padding(
                          padding:
                              const EdgeInsets.symmetric(
                            vertical: 8,
                          ),

                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,

                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,

                                children: [
                                  Text(
                                    _formatearNombre(nombreStat),
                                  ),

                                  Text(
                                    '$valor',
                                    style: const TextStyle(
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 6),

                              LinearProgressIndicator(
                                value: (valor / 255).clamp(
                                  0.0,
                                  1.0,
                                ),

                                minHeight: 9,

                                borderRadius:
                                    BorderRadius.circular(10),

                                backgroundColor:
                                    Colors.grey.shade200,

                                color: colorPrincipal,
                              ),
                            ],
                          ),
                        );
                      },
                    ).toList(),
                  ),
                ),

                // ==================================
                // EVOLUCIONES
                // ==================================

                _seccion(
                  'Evoluciones',
                  _construirEvoluciones(),
                ),

                // ==================================
                // SPRITE CLÁSICO / SHINY
                // ==================================

                _seccion(
                  _mostrarShiny
                      ? 'Sprite Shiny'
                      : 'Sprite clásico',

                  Center(
                    child: spriteSeleccionado != null
                        ? AnimatedSwitcher(
                            duration: const Duration(
                              milliseconds: 300,
                            ),

                            child: Image.network(
                              spriteSeleccionado,

                              key: ValueKey(
                                spriteSeleccionado,
                              ),

                              width: 110,
                              height: 110,

                              errorBuilder:
                                  (context, error, stackTrace) {
                                return const Icon(
                                  Icons.catching_pokemon,
                                  size: 70,
                                );
                              },
                            ),
                          )
                        : const Icon(
                            Icons.catching_pokemon,
                            size: 70,
                          ),
                  ),
                ),

                const SizedBox(height: 25),
              ],
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // 11. SECCIONES REUTILIZABLES
  // ==========================================

  Widget _seccion(
    String titulo,
    Widget contenido,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 9,
      ),

      elevation: 2,

      child: Padding(
        padding: const EdgeInsets.all(18),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),

            const SizedBox(height: 15),

            contenido,
          ],
        ),
      ),
    );
  }

  // Mostrar datos básicos
  Widget _dato(
    String etiqueta,
    String valor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 7,
      ),

      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,

        children: [
          Text(
            etiqueta,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),

          Text(
            valor,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
