
import 'package:flutter/material.dart';

// Servicios
import 'services/pokemon_service.dart';
import 'services/pokemon_type_service.dart';

// Pantallas
import 'screens/pokemon_detail_screen.dart';
import 'screens/pokemon_search_screen.dart';
import 'screens/pokemon_filter_screen.dart';
import 'screens/equipos_screen.dart';
import 'screens/favoritos_screen.dart';

void main() {
  runApp(const PokedexApp());
}

// ==========================================
// APLICACIÓN PRINCIPAL
// ==========================================

class PokedexApp extends StatelessWidget {
  const PokedexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mi Pokédex',

      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFDC0A2D),
        ),
      ),

      home: const PantallaPrincipal(),
    );
  }
}

// ==========================================
// PANTALLA PRINCIPAL
// ==========================================

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() =>
      _PantallaPrincipalState();
}

class _PantallaPrincipalState
    extends State<PantallaPrincipal> {

  // Servicios
  final PokemonService _pokemonService = PokemonService();

  final PokemonTypeService _typeService =
      PokemonTypeService();

  // Controlador de desplazamiento
  final ScrollController _scrollController =
      ScrollController();

  // Lista de Pokémon
  final List<dynamic> _pokemones = [];

  // NUEVO: Mapa de tipos por Pokémon
  Map<int, List<String>> _tiposPorPokemon = {};

  // Configuración de infinite scrolling
  static const int _limite = 20;
  int _offset = 0;

  // Estados del catálogo
  bool _cargando = false;
  bool _hayMas = true;
  String? _error;

  // NUEVO: Estados de carga de tipos
  bool _cargandoTipos = false;
  String? _errorTipos;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_detectarScroll);

    // Cargar catálogo y tipos de forma independiente
    _cargarPokemones();
    _cargarTipos();
  }

  // ==========================================
  // 1. INFINITE SCROLLING
  // ==========================================

  void _detectarScroll() {
    if (!_scrollController.hasClients) return;

    final posicion = _scrollController.position;

    if (posicion.maxScrollExtent > 0 &&
        posicion.pixels >=
            posicion.maxScrollExtent * 0.75) {
      _cargarPokemones();
    }
  }

  Future<void> _cargarPokemones() async {
    // Evitar peticiones duplicadas
    if (_cargando || !_hayMas || _error != null) {
      return;
    }

    setState(() {
      _cargando = true;
    });

    try {
      final nuevos =
          await _pokemonService.obtenerPokemones(
        limit: _limite,
        offset: _offset,
      );

      if (!mounted) return;

      setState(() {
        // Conservar los Pokémon anteriores
        _pokemones.addAll(nuevos);

        // Preparar siguiente página
        _offset += nuevos.length;

        // Detectar el final del catálogo
        _hayMas = nuevos.length == _limite;

        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'No se pudieron cargar los Pokémon';
        _cargando = false;
      });
    }
  }

  void _reintentar() {
    setState(() {
      _error = null;
    });

    _cargarPokemones();
  }

  // ==========================================
  // 2. NUEVO: CARGAR TIPOS POKÉMON
  // ==========================================

  Future<void> _cargarTipos() async {
    if (_cargandoTipos) return;

    setState(() {
      _cargandoTipos = true;
      _errorTipos = null;
    });

    try {
      // Obtener tipos desde nuestro servicio
      final mapa = await _typeService.obtenerTiposCatalogo();

      if (!mounted) return;

      setState(() {
        _tiposPorPokemon = mapa;
        _cargandoTipos = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cargandoTipos = false;
        _errorTipos = 'No se pudieron cargar los tipos';
      });
    }
  }

  // ==========================================
  // 3. NUEVO: COLORES POR TIPO
  // ==========================================

  Color _colorTipo(String tipo) {
    const colores = {
      'normal': Color(0xFF9299A1),
      'fire': Color(0xFFEE8130),
      'water': Color(0xFF3989D8),
      'grass': Color(0xFF4CAF50),
      'electric': Color(0xFFE5AC08),
      'ice': Color(0xFF45B8C5),
      'fighting': Color(0xFFC22E28),
      'poison': Color(0xFFA33EA1),
      'ground': Color(0xFFC99B39),
      'flying': Color(0xFF8A77CC),
      'psychic': Color(0xFFF95587),
      'bug': Color(0xFF7B9E20),
      'rock': Color(0xFFA38D36),
      'ghost': Color(0xFF735797),
      'dragon': Color(0xFF6F35FC),
      'dark': Color(0xFF705746),
      'steel': Color(0xFF72869D),
      'fairy': Color(0xFFD65B9D),
    };

    return colores[tipo] ?? Colors.grey;
  }

  // ==========================================
  // 4. NUEVO: TRADUCIR TIPOS AL ESPAÑOL
  // ==========================================

  String _nombreTipo(String tipo) {
    const nombres = {
      'normal': 'Normal',
      'fire': 'Fuego',
      'water': 'Agua',
      'grass': 'Planta',
      'electric': 'Eléctrico',
      'ice': 'Hielo',
      'fighting': 'Lucha',
      'poison': 'Veneno',
      'ground': 'Tierra',
      'flying': 'Volador',
      'psychic': 'Psíquico',
      'bug': 'Bicho',
      'rock': 'Roca',
      'ghost': 'Fantasma',
      'dragon': 'Dragón',
      'dark': 'Siniestro',
      'steel': 'Acero',
      'fairy': 'Hada',
    };

    return nombres[tipo] ?? tipo;
  }

  // ==========================================
  // 5. NAVEGACIÓN
  // ==========================================

  void _abrirDetalle(int id) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PokemonDetailScreen(
          pokemonId: id,
        ),
      ),
    );
  }

  void _abrirBusqueda() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PokemonSearchScreen(),
      ),
    );
  }

  void _abrirFiltros() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PokemonFilterScreen(),
      ),
    );
  }

  void _abrirEquipos() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EquiposScreen(),
      ),
    );
  }

  void _abrirFavoritos() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FavoritosScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ==========================================
  // 6. INTERFAZ PRINCIPAL
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFDC0A2D),
        foregroundColor: Colors.white,
        centerTitle: true,

        title: const Text(
          'Mi Pokédex',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Buscar Pokémon',
            onPressed: _abrirBusqueda,
          ),

          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtrar Pokémon',
            onPressed: _abrirFiltros,
          ),

          IconButton(
            icon: const Icon(Icons.groups),
            tooltip: 'Mis Equipos',
            onPressed: _abrirEquipos,
          ),

          IconButton(
            icon: const Icon(Icons.favorite),
            tooltip: 'Mis Favoritos',
            onPressed: _abrirFavoritos,
          ),

          const SizedBox(width: 5),
        ],
      ),

      body: _construirContenido(),
    );
  }

  // ==========================================
  // 7. CONSTRUIR EL CATÁLOGO
  // ==========================================

  Widget _construirContenido() {
    if (_pokemones.isEmpty && _cargando) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFDC0A2D),
        ),
      );
    }

    if (_pokemones.isEmpty && _error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: _reintentar,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_pokemones.isEmpty) {
      return const Center(
        child: Text('No hay Pokémon disponibles'),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 1200,
        ),

        child: Column(
          children: [
            // ENCABEZADO
            Padding(
              padding: const EdgeInsets.fromLTRB(
                18, 18, 18, 10,
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.catching_pokemon,
                        color: Color(0xFFDC0A2D),
                        size: 30,
                      ),

                      SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          'Explora los Pokémon',
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(
                    '${_pokemones.length} Pokémon cargados',
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),

                  // Error de tipos sin bloquear el catálogo
                  if (_errorTipos != null)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _errorTipos!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                          ),
                        ),

                        TextButton(
                          onPressed: _cargarTipos,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // CUADRÍCULA RESPONSIVA
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  int columnas = 2;

                  if (constraints.maxWidth >= 900) {
                    columnas = 4;
                  } else if (constraints.maxWidth >= 600) {
                    columnas = 3;
                  }

                  return GridView.builder(
                    controller: _scrollController,

                    padding: const EdgeInsets.all(12),

                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columnas,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      mainAxisExtent: 300,
                    ),

                    itemCount: _pokemones.length +
                        ((_cargando || _error != null)
                            ? 1
                            : 0),

                    itemBuilder: (context, index) {
                      // Carga o error al final de la lista
                      if (index == _pokemones.length) {
                        if (_error != null) {
                          return Center(
                            child: ElevatedButton(
                              onPressed: _reintentar,
                              child: const Text('Reintentar'),
                            ),
                          );
                        }

                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final pokemon = _pokemones[index];

                      final id = int.parse(
                        Uri.parse(pokemon['url'])
                            .pathSegments
                            .where(
                              (segmento) => segmento.isNotEmpty,
                            )
                            .last,
                      );

                      return _tarjetaPokemon(
                        id,
                        pokemon['name'] as String,
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
  }

  // ==========================================
  // 8. NUEVO: ETIQUETA DE TIPO
  // ==========================================

  Widget _etiquetaTipo(String tipo) {
    final color = _colorTipo(tipo);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),

      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
        ),
      ),

      child: Text(
        _nombreTipo(tipo),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ==========================================
  // 9. TARJETA POKÉMON CON TIPOS
  // ==========================================

  Widget _tarjetaPokemon(
    int id,
    String nombre,
  ) {
    final imagenUrl =
        'https://raw.githubusercontent.com/'
        'PokeAPI/sprites/master/sprites/'
        'pokemon/$id.png';

    final nombreFormateado = nombre
        .replaceAll('-', ' ')
        .toUpperCase();

    // Obtener tipos previamente descargados
    final tipos = _tiposPorPokemon[id] ??
        const <String>[];

    // Color del tipo principal
    final colorPrincipal = tipos.isNotEmpty
        ? _colorTipo(tipos.first)
        : const Color(0xFFDC0A2D);

    return Card(
      elevation: 3,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: Colors.white,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),

      child: InkWell(
        onTap: () => _abrirDetalle(id),

        child: Padding(
          padding: const EdgeInsets.all(12),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // NÚMERO
              Align(
                alignment: Alignment.topRight,
                child: Text(
                  '#${id.toString().padLeft(4, '0')}',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // IMAGEN CON FONDO POR TIPO
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),

                  decoration: BoxDecoration(
                    color: colorPrincipal.withValues(
                      alpha: 0.13,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),

                  child: Hero(
                    tag: 'catalogo-pokemon-$id',

                    child: Image.network(
                      imagenUrl,
                      fit: BoxFit.contain,

                      errorBuilder:
                          (context, error, stackTrace) {
                        return const Icon(
                          Icons.catching_pokemon,
                          size: 65,
                          color: Colors.red,
                        );
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // NOMBRE
              Text(
                nombreFormateado,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,

                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 9),

              // NUEVO: TIPOS DEL POKÉMON
              SizedBox(
                height: 54,

                child: Center(
                  child: tipos.isNotEmpty
                      ? Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 5,
                          runSpacing: 5,

                          children: tipos.map((tipo) {
                            return _etiquetaTipo(tipo);
                          }).toList(),
                        )
                      : Text(
                          _cargandoTipos
                              ? 'Cargando tipos...'
                              : 'Tipos no disponibles',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 6),

              // ABRIR DETALLES
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Ver detalles',
                    style: TextStyle(
                      color: Color(0xFFDC0A2D),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  SizedBox(width: 4),

                  Icon(
                    Icons.arrow_forward_ios,
                    color: Color(0xFFDC0A2D),
                    size: 11,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
