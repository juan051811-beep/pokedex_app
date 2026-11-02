
import 'package:flutter/material.dart';
import '../services/pokemon_service.dart';

// Pantalla para seleccionar Pokémon para un equipo
class SeleccionarPokemonScreen extends StatefulWidget {
  // Pokémon que ya pertenecen al equipo
  final Set<int> idsOcupados;

  const SeleccionarPokemonScreen({
    super.key,
    this.idsOcupados = const <int>{},
  });

  @override
  State<SeleccionarPokemonScreen> createState() =>
      _SeleccionarPokemonScreenState();
}

class _SeleccionarPokemonScreenState
    extends State<SeleccionarPokemonScreen> {

  // Servicio de PokéAPI
  final PokemonService _servicio = PokemonService();

  // Controladores
  final TextEditingController _controlador =
      TextEditingController();

  final ScrollController _scrollController =
      ScrollController();

  // Catálogo de Pokémon
  final List<dynamic> _pokemones = [];

  // Configuración de paginación
  static const int _limite = 20;
  int _offset = 0;

  // Estados del catálogo
  bool _cargando = false;
  bool _hayMas = true;
  String? _error;

  // Estados de búsqueda
  bool _buscando = false;
  bool _modoBusqueda = false;
  Map<String, dynamic>? _resultadoBusqueda;
  String? _errorBusqueda;

  // Control de solicitudes de búsqueda
  int _versionBusqueda = 0;

  @override
  void initState() {
    super.initState();

    // Activar infinite scrolling
    _scrollController.addListener(_detectarScroll);

    // Cargar primeros 20 Pokémon
    _cargarPokemones();
  }

  // Detectar desplazamiento
  void _detectarScroll() {
    if (!_scrollController.hasClients || _modoBusqueda) {
      return;
    }

    final posicion = _scrollController.position;

    if (posicion.maxScrollExtent > 0 &&
        posicion.pixels >= posicion.maxScrollExtent * 0.75) {
      _cargarPokemones();
    }
  }

  // Cargar Pokémon progresivamente
  Future<void> _cargarPokemones() async {
    if (_cargando || !_hayMas || _error != null) return;

    setState(() {
      _cargando = true;
    });

    try {
      final nuevos = await _servicio.obtenerPokemones(
        limit: _limite,
        offset: _offset,
      );

      if (!mounted) return;

      setState(() {
        _pokemones.addAll(nuevos);

        _offset += nuevos.length;

        _hayMas = nuevos.length == _limite;

        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Error al cargar Pokémon';
        _cargando = false;
      });
    }
  }

  // Buscar por nombre o número
  Future<void> _buscarPokemon() async {
    final consulta = _controlador.text.trim();

    if (consulta.isEmpty) {
      _limpiarBusqueda();
      return;
    }

    final versionActual = ++_versionBusqueda;

    setState(() {
      _modoBusqueda = true;
      _buscando = true;
      _resultadoBusqueda = null;
      _errorBusqueda = null;
    });

    try {
      final resultado = await _servicio.buscarPokemon(
        consulta,
      );

      if (!mounted ||
          versionActual != _versionBusqueda) {
        return;
      }

      setState(() {
        _resultadoBusqueda = resultado;
        _buscando = false;
      });
    } catch (e) {
      if (!mounted ||
          versionActual != _versionBusqueda) {
        return;
      }

      setState(() {
        _errorBusqueda = e.toString().replaceFirst(
          'Exception: ',
          '',
        );

        _buscando = false;
      });
    }
  }

  // Limpiar búsqueda y regresar al catálogo
  void _limpiarBusqueda() {
    _versionBusqueda++;
    _controlador.clear();

    setState(() {
      _modoBusqueda = false;
      _buscando = false;
      _resultadoBusqueda = null;
      _errorBusqueda = null;
    });
  }

  // Seleccionar un Pokémon
  void _seleccionarPokemon(int id) {

    // Evitar Pokémon repetidos en el equipo
    if (widget.idsOcupados.contains(id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Este Pokémon ya pertenece al equipo',
          ),
        ),
      );
      return;
    }

    // Regresar el ID del Pokémon seleccionado
    Navigator.pop(context, id);
  }

  // Obtener ID de un Pokémon
  int _obtenerId(String url) {
    return int.parse(
      Uri.parse(url)
          .pathSegments
          .where((segmento) => segmento.isNotEmpty)
          .last,
    );
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

  @override
  void dispose() {
    _controlador.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      appBar: AppBar(
        title: const Text(
          'Seleccionar Pokémon',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),

      body: Column(
        children: [

          // PANEL SUPERIOR DE BÚSQUEDA
          Padding(
            padding: const EdgeInsets.all(16),

            child: Column(
              children: [
                const Text(
                  'Elige un integrante',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Explora el catálogo o busca '
                  'un Pokémon por nombre o número.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 18),

                // Barra de búsqueda
                TextField(
                  controller: _controlador,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _buscarPokemon(),

                  decoration: InputDecoration(
                    hintText: 'Ejemplo: Pikachu o 25',

                    prefixIcon: const Icon(
                      Icons.search,
                      color: Colors.red,
                    ),

                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _limpiarBusqueda,
                    ),

                    filled: true,
                    fillColor: Colors.white,

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Botón buscar
                SizedBox(
                  width: double.infinity,

                  child: ElevatedButton.icon(
                    onPressed: _buscando
                        ? null
                        : _buscarPokemon,

                    icon: const Icon(Icons.search),

                    label: const Text('Buscar Pokémon'),

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(14),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // RESULTADOS
          Expanded(
            child: _modoBusqueda
                ? _construirBusqueda()
                : _construirCatalogo(),
          ),
        ],
      ),
    );
  }

  // Mostrar resultado de búsqueda
  Widget _construirBusqueda() {
    if (_buscando) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.red,
        ),
      );
    }

    if (_errorBusqueda != null) {
      return Center(
        child: Text(
          _errorBusqueda!,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.red,
            fontSize: 16,
          ),
        ),
      );
    }

    if (_resultadoBusqueda == null) {
      return const Center(
        child: Text('No se encontraron resultados'),
      );
    }

    final pokemon = _resultadoBusqueda!;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _tarjetaPokemon(
          pokemon['id'] as int,
          pokemon['name'] as String,
        ),
      ],
    );
  }

  // Mostrar catálogo con infinite scrolling
  Widget _construirCatalogo() {
    if (_pokemones.isEmpty && _cargando) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.red,
        ),
      );
    }

    if (_pokemones.isEmpty && _error != null) {
      return Center(
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              _error = null;
            });

            _cargarPokemones();
          },
          child: const Text('Reintentar'),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,

      itemCount: _pokemones.length +
          ((_cargando || _error != null) ? 1 : 0),

      itemBuilder: (context, index) {

        // Indicador o reintento al final
        if (index == _pokemones.length) {
          if (_error != null) {
            return Center(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                  });

                  _cargarPokemones();
                },
                child: const Text('Reintentar'),
              ),
            );
          }

          return const Padding(
            padding: EdgeInsets.all(18),
            child: Center(
              child: CircularProgressIndicator(
                color: Colors.red,
              ),
            ),
          );
        }

        final pokemon = _pokemones[index];

        final id = _obtenerId(
          pokemon['url'] as String,
        );

        return _tarjetaPokemon(
          id,
          pokemon['name'] as String,
        );
      },
    );
  }

  // Tarjeta para seleccionar Pokémon
  Widget _tarjetaPokemon(int id, String nombre) {
    final ocupado = widget.idsOcupados.contains(id);

    final imagenUrl =
        'https://raw.githubusercontent.com/'
        'PokeAPI/sprites/master/sprites/'
        'pokemon/$id.png';

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      elevation: 2,

      child: ListTile(
        onTap: () => _seleccionarPokemon(id),

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),

        // Imagen
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: Colors.red.shade100,

          child: Image.network(
            imagenUrl,
            width: 55,
            height: 55,

            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.catching_pokemon,
                color: Colors.red,
              );
            },
          ),
        ),

        // Nombre
        title: Text(
          _formatearNombre(nombre),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),

        // Número
        subtitle: Text(
          ocupado
              ? '#$id - Ya está en el equipo'
              : '#${id.toString().padLeft(4, '0')}',
        ),

        // Indicador de selección
        trailing: Icon(
          ocupado
              ? Icons.check_circle
              : Icons.add_circle_outline,
          color: ocupado
              ? Colors.green
              : Colors.red,
          size: 28,
        ),
      ),
    );
  }
}
