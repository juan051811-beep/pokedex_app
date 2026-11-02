
import 'package:flutter/material.dart';
import '../services/pokemon_service.dart';
import 'pokemon_detail_screen.dart';

// Pantalla de búsqueda de Pokémon
class PokemonSearchScreen extends StatefulWidget {
  const PokemonSearchScreen({super.key});

  @override
  State<PokemonSearchScreen> createState() =>
      _PokemonSearchScreenState();
}

class _PokemonSearchScreenState extends State<PokemonSearchScreen> {
  // Servicio de PokéAPI
  final PokemonService _servicio = PokemonService();

  // Controlador de la barra de búsqueda
  final TextEditingController _controlador = TextEditingController();

  // Información del Pokémon encontrado
  Map<String, dynamic>? _pokemon;

  // Estados de búsqueda
  bool _buscando = false;
  String? _mensaje;

  // Identificador para evitar resultados de búsquedas anteriores
  int _versionBusqueda = 0;

  // Buscar Pokémon por nombre o número
  Future<void> _buscarPokemon() async {
    final consulta = _controlador.text.trim();

    if (consulta.isEmpty) {
      setState(() {
        _mensaje = 'Escribe un nombre o número';
        _pokemon = null;
      });
      return;
    }

    final versionActual = ++_versionBusqueda;

    setState(() {
      _buscando = true;
      _pokemon = null;
      _mensaje = null;
    });

    try {
      final resultado = await _servicio.buscarPokemon(consulta);

      if (!mounted || versionActual != _versionBusqueda) return;

      setState(() {
        _pokemon = resultado;
        _buscando = false;
      });
    } catch (e) {
      if (!mounted || versionActual != _versionBusqueda) return;

      setState(() {
        _mensaje = e.toString().replaceFirst('Exception: ', '');
        _buscando = false;
      });
    }
  }

  // Abrir los detalles del Pokémon encontrado
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

  // Formatear nombres de Pokémon
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      appBar: AppBar(
        title: const Text(
          'Buscar Pokémon',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            // Título de la búsqueda
            const Text(
              '¿Qué Pokémon estás buscando?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 10),

            const Text(
              'Escribe su nombre o número de Pokédex',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 25),

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
                  onPressed: () {
                    ++_versionBusqueda;
                    _controlador.clear();

                    setState(() {
                      _pokemon = null;
                      _mensaje = null;
                      _buscando = false;
                    });
                  },
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // Botón de búsqueda
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _buscando ? null : _buscarPokemon,
                icon: const Icon(Icons.search),
                label: const Text('Buscar Pokémon'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(15),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // Indicador de carga
            if (_buscando)
              const CircularProgressIndicator(
                color: Colors.red,
              ),

            // Mensaje de error o Pokémon no encontrado
            if (_mensaje != null)
              Padding(
                padding: const EdgeInsets.all(15),
                child: Text(
                  _mensaje!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                  ),
                ),
              ),

            // Resultado de la búsqueda
            if (_pokemon != null)
              Expanded(
                child: SingleChildScrollView(
                  child: _tarjetaPokemon(_pokemon!),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Tarjeta del Pokémon encontrado
  Widget _tarjetaPokemon(Map<String, dynamic> pokemon) {
    final int id = pokemon['id'];

    final String nombre = _formatearNombre(
      pokemon['name'],
    );

    final String? imagen =
        pokemon['sprites']?['other']
            ?['official-artwork']?['front_default'] ??
        pokemon['sprites']?['front_default'];

    final List<dynamic> tipos = pokemon['types'];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),

      child: InkWell(
        borderRadius: BorderRadius.circular(20),

        // Abrir detalles al tocar la tarjeta
        onTap: () => _abrirDetalle(id),

        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Número
              Text(
                '#${id.toString().padLeft(4, '0')}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 18,
                ),
              ),

              const SizedBox(height: 10),

              // Imagen oficial
              if (imagen != null)
                Image.network(
                  imagen,
                  height: 180,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.catching_pokemon,
                      size: 120,
                      color: Colors.red,
                    );
                  },
                ),

              const SizedBox(height: 15),

              // Nombre
              Text(
                nombre,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              // Tipos del Pokémon
              Wrap(
                spacing: 8,
                children: tipos.map<Widget>((tipo) {
                  return Chip(
                    label: Text(
                      _formatearNombre(tipo['type']['name']),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 15),

              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Ver información completa',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 5),
                  Icon(
                    Icons.arrow_forward,
                    color: Colors.red,
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
