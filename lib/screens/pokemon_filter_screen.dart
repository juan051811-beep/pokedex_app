
import 'package:flutter/material.dart';
import '../services/pokemon_service.dart';
import 'pokemon_detail_screen.dart';

// Pantalla para filtrar Pokémon
class PokemonFilterScreen extends StatefulWidget {
  const PokemonFilterScreen({super.key});

  @override
  State<PokemonFilterScreen> createState() =>
      _PokemonFilterScreenState();
}

class _PokemonFilterScreenState
    extends State<PokemonFilterScreen> {

  // Servicio de PokéAPI
  final PokemonService _servicio = PokemonService();

  // Filtros seleccionados
  String? _tipoSeleccionado;
  int? _generacionSeleccionada;

  // Resultados obtenidos
  List<Map<String, dynamic>> _resultados = [];

  // Estados de la pantalla
  bool _cargando = false;
  bool _busquedaRealizada = false;
  String? _error;

  // Evita mostrar respuestas de búsquedas anteriores
  int _versionPeticion = 0;

  // Tipos Pokémon disponibles
  static const Map<String, String> _tipos = {
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

  // Obtener ID del Pokémon desde su URL
  int _obtenerId(String url) {
    return int.parse(
      Uri.parse(url)
          .pathSegments
          .where((segmento) => segmento.isNotEmpty)
          .last,
    );
  }

  // Cambiar el tipo seleccionado
  void _cambiarTipo(String? tipo) {
    _versionPeticion++;

    setState(() {
      _tipoSeleccionado = tipo;
      _resultados = [];
      _busquedaRealizada = false;
      _cargando = false;
      _error = null;
    });
  }

  // Cambiar la generación seleccionada
  void _cambiarGeneracion(int? generacion) {
    _versionPeticion++;

    setState(() {
      _generacionSeleccionada = generacion;
      _resultados = [];
      _busquedaRealizada = false;
      _cargando = false;
      _error = null;
    });
  }

  // Aplicar filtros
  Future<void> _aplicarFiltros() async {

    final tipo = _tipoSeleccionado;
    final generacion = _generacionSeleccionada;

    // Comprobar que exista al menos un filtro
    if (tipo == null && generacion == null) {
      setState(() {
        _error = 'Selecciona al menos un filtro';
        _resultados = [];
        _busquedaRealizada = false;
      });
      return;
    }

    final versionActual = ++_versionPeticion;

    setState(() {
      _cargando = true;
      _error = null;
      _resultados = [];
      _busquedaRealizada = false;
    });

    try {
      List<Map<String, dynamic>> resultados;

      // CASO 1: Filtrar por tipo y generación
      if (tipo != null && generacion != null) {

        // Realizar ambas consultas en paralelo
        final listas = await Future.wait([
          _servicio.obtenerPokemonPorTipo(tipo),
          _servicio.obtenerPokemonPorGeneracion(
            generacion,
          ),
        ]);

        final listaTipo = listas[0];
        final listaGeneracion = listas[1];

        // Identificar Pokémon de la generación
        final idsGeneracion = listaGeneracion
            .map((pokemon) {
              return _obtenerId(
                pokemon['url'] as String,
              );
            })
            .toSet();

        // Conservar los que cumplen ambos filtros
        resultados = listaTipo.where((pokemon) {
          final id = _obtenerId(
            pokemon['url'] as String,
          );

          return idsGeneracion.contains(id);
        }).toList();

      // CASO 2: Filtrar solamente por tipo
      } else if (tipo != null) {
        resultados = await _servicio
            .obtenerPokemonPorTipo(tipo);

      // CASO 3: Filtrar solamente por generación
      } else {
        resultados = await _servicio
            .obtenerPokemonPorGeneracion(generacion!);
      }

      // Ordenar los Pokémon por número
      resultados.sort((a, b) {
        final idA = _obtenerId(a['url'] as String);
        final idB = _obtenerId(b['url'] as String);

        return idA.compareTo(idB);
      });

      if (!mounted ||
          versionActual != _versionPeticion) {
        return;
      }

      setState(() {
        _resultados = resultados;
        _busquedaRealizada = true;
        _cargando = false;
      });

    } catch (e) {
      if (!mounted ||
          versionActual != _versionPeticion) {
        return;
      }

      setState(() {
        _error = 'No se pudieron cargar los filtros. '
            'Comprueba tu conexión e inténtalo de nuevo.';
        _cargando = false;
      });
    }
  }

  // Limpiar filtros y resultados
  void _limpiarFiltros() {
    _versionPeticion++;

    setState(() {
      _tipoSeleccionado = null;
      _generacionSeleccionada = null;
      _resultados = [];
      _cargando = false;
      _busquedaRealizada = false;
      _error = null;
    });
  }

  // Abrir información completa
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

  // Dar formato al nombre
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      appBar: AppBar(
        title: const Text(
          'Filtros Pokémon',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1000,
          ),

          child: Padding(
            padding: const EdgeInsets.all(14),

            child: Column(
              children: [

                // PANEL DE FILTROS
                Card(
                  elevation: 2,

                  child: Padding(
                    padding: const EdgeInsets.all(16),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,

                      children: [

                        const Text(
                          'Explorar Pokémon',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 6),

                        const Text(
                          'Selecciona un tipo, una generación '
                          'o combina ambos filtros.',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),

                        const SizedBox(height: 18),

                        // FILTRO POR TIPO
                        DropdownButtonFormField<String>(
                          key: ValueKey(
                            'tipo-$_tipoSeleccionado',
                          ),
                          initialValue: _tipoSeleccionado,
                          isExpanded: true,

                          decoration: InputDecoration(
                            labelText: 'Tipo Pokémon',
                            prefixIcon: const Icon(
                              Icons.category,
                              color: Colors.red,
                            ),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                          ),

                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('Todos los tipos'),
                            ),

                            ..._tipos.entries.map((entrada) {
                              return DropdownMenuItem<String>(
                                value: entrada.key,
                                child: Text(entrada.value),
                              );
                            }),
                          ],

                          onChanged: _cambiarTipo,
                        ),

                        const SizedBox(height: 14),

                        // FILTRO POR GENERACIÓN
                        DropdownButtonFormField<int>(
                          key: ValueKey(
                            'generacion-$_generacionSeleccionada',
                          ),
                          initialValue:
                              _generacionSeleccionada,
                          isExpanded: true,

                          decoration: InputDecoration(
                            labelText: 'Generación',
                            prefixIcon: const Icon(
                              Icons.layers,
                              color: Colors.red,
                            ),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                          ),

                          items: [
                            const DropdownMenuItem<int>(
                              value: null,
                              child: Text(
                                'Todas las generaciones',
                              ),
                            ),

                            ...List.generate(9, (index) {
                              final generacion = index + 1;

                              return DropdownMenuItem<int>(
                                value: generacion,
                                child: Text(
                                  'Generación $generacion',
                                ),
                              );
                            }),
                          ],

                          onChanged: _cambiarGeneracion,
                        ),

                        const SizedBox(height: 18),

                        // BOTONES
                        Row(
                          children: [

                            // Aplicar filtros
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: _cargando
                                    ? null
                                    : _aplicarFiltros,

                                icon: const Icon(
                                  Icons.filter_list,
                                ),

                                label: const Text('Filtrar'),

                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 10),

                            // Limpiar filtros
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _limpiarFiltros,

                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),

                                child: const Text('Limpiar'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // RESULTADOS
                Expanded(
                  child: _construirResultados(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Construir resultados de los filtros
  Widget _construirResultados() {

    // Cargando información
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.red,
        ),
      );
    }

    // Error de conexión o selección
    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.red,
            fontSize: 16,
          ),
        ),
      );
    }

    // Pantalla inicial
    if (!_busquedaRealizada) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.catching_pokemon,
              size: 70,
              color: Colors.red,
            ),

            SizedBox(height: 12),

            Text(
              'Selecciona tus filtros para comenzar',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    // Sin resultados
    if (_resultados.isEmpty) {
      return const Center(
        child: Text(
          'No se encontraron Pokémon '
          'con estos filtros.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
          ),
        ),
      );
    }

    // Mostrar resultados encontrados
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            '${_resultados.length} Pokémon encontrados',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Grid optimizado que solo construye
        // las tarjetas necesarias
        Expanded(
          child: GridView.builder(
            itemCount: _resultados.length,

            gridDelegate:
                const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 260,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.9,
            ),

            itemBuilder: (context, index) {
              return _tarjetaPokemon(
                _resultados[index],
              );
            },
          ),
        ),
      ],
    );
  }

  // Tarjeta de Pokémon filtrado
  Widget _tarjetaPokemon(
    Map<String, dynamic> pokemon,
  ) {

    final int id = _obtenerId(
      pokemon['url'] as String,
    );

    final String nombre = _formatearNombre(
      pokemon['name'] as String,
    );

    final String imagenUrl =
        'https://raw.githubusercontent.com/PokeAPI/sprites/'
        'master/sprites/pokemon/$id.png';

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),

      child: InkWell(
        onTap: () => _abrirDetalle(id),

        child: Padding(
          padding: const EdgeInsets.all(10),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              // Número
              Text(
                '#${id.toString().padLeft(4, '0')}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 8),

              // Imagen
              Expanded(
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

              const SizedBox(height: 8),

              // Nombre
              Text(
                nombre,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,

                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 5),

              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.red,
                size: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
