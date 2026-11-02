

import 'package:flutter/material.dart';

import '../models/equipo_pokemon.dart';
import '../services/equipo_storage_service.dart';
import 'seleccionar_pokemon_screen.dart';

// Pantalla para gestionar equipos Pokémon
class EquiposScreen extends StatefulWidget {
  const EquiposScreen({super.key});

  @override
  State<EquiposScreen> createState() => _EquiposScreenState();
}

class _EquiposScreenState extends State<EquiposScreen> {
  // Servicio de almacenamiento permanente
  final EquipoStorageService _storage = EquipoStorageService();

  // Equipos del usuario
  List<EquipoPokemon> _equipos = [];

  // Estados de la pantalla
  bool _cargando = true;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarEquipos();
  }

  // ==========================================
  // 1. CARGAR EQUIPOS GUARDADOS
  // ==========================================

  Future<void> _cargarEquipos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final equipos = await _storage.cargarEquipos();

      if (!mounted) return;

      setState(() {
        _equipos = equipos;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'No se pudieron cargar los equipos';
        _cargando = false;
      });
    }
  }

  // ==========================================
  // 2. GUARDAR CAMBIOS
  // ==========================================

  Future<bool> _guardarCambios(
    List<EquipoPokemon> nuevosEquipos,
  ) async {
    if (_guardando) return false;

    setState(() {
      _guardando = true;
    });

    try {
      // Guardar permanentemente
      await _storage.guardarEquipos(nuevosEquipos);

      if (!mounted) return false;

      // Actualizar la interfaz
      setState(() {
        _equipos = nuevosEquipos;
      });

      return true;
    } catch (e) {
      if (mounted) {
        _mostrarMensaje(
          'No se pudieron guardar los cambios',
        );
      }

      return false;
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  // Mostrar notificaciones
  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Buscar un equipo por su ID
  EquipoPokemon? _buscarEquipo(String id) {
    for (final equipo in _equipos) {
      if (equipo.id == id) {
        return equipo;
      }
    }

    return null;
  }

  // ==========================================
  // 3. PEDIR NOMBRE DEL EQUIPO
  // ==========================================

  Future<String?> _pedirNombre({
    String? nombreActual,
  }) async {
    final controlador = TextEditingController(
      text: nombreActual ?? '',
    );

    String nombre = controlador.text.trim();

    final resultado = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, actualizarDialogo) {
            return AlertDialog(
              title: Text(
                nombreActual == null
                    ? 'Crear equipo'
                    : 'Editar equipo',
              ),

              content: TextField(
                controller: controlador,
                autofocus: true,
                maxLength: 30,
                textCapitalization:
                    TextCapitalization.words,

                decoration: const InputDecoration(
                  labelText: 'Nombre del equipo',
                  hintText: 'Ejemplo: Los Legendarios',
                  prefixIcon: Icon(
                    Icons.groups,
                    color: Colors.red,
                  ),
                  border: OutlineInputBorder(),
                ),

                onChanged: (valor) {
                  actualizarDialogo(() {
                    nombre = valor.trim();
                  });
                },
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancelar'),
                ),

                FilledButton(
                  onPressed: nombre.isEmpty
                      ? null
                      : () {
                          Navigator.pop(
                            dialogContext,
                            nombre,
                          );
                        },

                  child: Text(
                    nombreActual == null
                        ? 'Crear'
                        : 'Guardar',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    // Liberar controlador después del diálogo
    // y su animación de cierre.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(
        const Duration(milliseconds: 300),
        controlador.dispose,
      );
    });

    return resultado;
  }

  // ==========================================
  // 4. CREAR EQUIPO
  // ==========================================

  Future<void> _crearEquipo() async {
    if (_guardando) return;

    final nombre = await _pedirNombre();

    if (!mounted || nombre == null) return;

    final nuevoEquipo = EquipoPokemon(
      id: DateTime.now()
          .microsecondsSinceEpoch
          .toString(),
      nombre: nombre,
      pokemonIds: [],
    );

    final guardado = await _guardarCambios([
      ..._equipos,
      nuevoEquipo,
    ]);

    if (guardado && mounted) {
      _mostrarMensaje('Equipo creado correctamente');
    }
  }

  // ==========================================
  // 5. EDITAR NOMBRE DEL EQUIPO
  // ==========================================

  Future<void> _editarEquipo(
    EquipoPokemon equipo,
  ) async {
    if (_guardando) return;

    final nombre = await _pedirNombre(
      nombreActual: equipo.nombre,
    );

    if (!mounted || nombre == null) return;

    final nuevosEquipos = _equipos.map((actual) {
      if (actual.id == equipo.id) {
        return actual.copiarCon(nombre: nombre);
      }

      return actual;
    }).toList();

    final guardado = await _guardarCambios(
      nuevosEquipos,
    );

    if (guardado && mounted) {
      _mostrarMensaje('Equipo actualizado');
    }
  }

  // ==========================================
  // 6. ELIMINAR EQUIPO
  // ==========================================

  Future<void> _eliminarEquipo(
    EquipoPokemon equipo,
  ) async {
    if (_guardando) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar equipo'),

          content: Text(
            '¿Deseas eliminar "${equipo.nombre}"?',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),

            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmar != true) return;

    final nuevosEquipos = _equipos.where((actual) {
      return actual.id != equipo.id;
    }).toList();

    final guardado = await _guardarCambios(
      nuevosEquipos,
    );

    if (guardado && mounted) {
      _mostrarMensaje('Equipo eliminado');
    }
  }

  // ==========================================
  // 7. NUEVO: INTERACTUAR CON UNA RANURA
  // ==========================================

  Future<void> _abrirRanura(
    EquipoPokemon equipo,
    int posicion,
  ) async {
    if (_guardando) return;

    final actual = _buscarEquipo(equipo.id);

    if (actual == null) return;

    // Si la ranura está vacía, seleccionar Pokémon
    if (posicion >= actual.pokemonIds.length) {
      await _seleccionarPokemon(equipo.id, posicion);
      return;
    }

    // Si está ocupada, mostrar opciones
    final accion = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,

      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Administrar Pokémon',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Reemplazar integrante
              ListTile(
                leading: const Icon(
                  Icons.swap_horiz,
                  color: Colors.blue,
                ),
                title: const Text('Cambiar Pokémon'),
                subtitle: const Text(
                  'Seleccionar otro integrante',
                ),
                onTap: () {
                  Navigator.pop(context, 'cambiar');
                },
              ),

              // Eliminar integrante
              ListTile(
                leading: const Icon(
                  Icons.remove_circle_outline,
                  color: Colors.red,
                ),
                title: const Text('Quitar del equipo'),
                subtitle: const Text(
                  'Liberar este espacio',
                ),
                onTap: () {
                  Navigator.pop(context, 'quitar');
                },
              ),

              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );

    if (!mounted) return;

    if (accion == 'cambiar') {
      await _seleccionarPokemon(equipo.id, posicion);
    } else if (accion == 'quitar') {
      await _quitarPokemon(equipo.id, posicion);
    }
  }

  // ==========================================
  // 8. NUEVO: SELECCIONAR UN POKÉMON
  // ==========================================

  Future<void> _seleccionarPokemon(
    String equipoId,
    int posicion,
  ) async {
    if (_guardando || posicion < 0 || posicion >= 6) {
      return;
    }

    final equipo = _buscarEquipo(equipoId);

    if (equipo == null) return;

    // Obtener los Pokémon ya utilizados
    final ocupados = Set<int>.from(
      equipo.pokemonIds,
    );

    // Al reemplazar, permitir seleccionar
    // el Pokémon que ya ocupa esta ranura.
    if (posicion < equipo.pokemonIds.length) {
      ocupados.remove(equipo.pokemonIds[posicion]);
    }

    // Abrir pantalla de selección
    final int? pokemonSeleccionado =
        await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (context) => SeleccionarPokemonScreen(
          idsOcupados: ocupados,
        ),
      ),
    );

    // Si cancelamos, no hacer nada
    if (!mounted || pokemonSeleccionado == null) {
      return;
    }

    final equipoActual = _buscarEquipo(equipoId);

    if (equipoActual == null || _guardando) {
      return;
    }

    // Crear copia de los integrantes actuales
    final nuevosIds = List<int>.from(
      equipoActual.pokemonIds,
    );

    // Evitar Pokémon repetidos en otras ranuras
    for (int i = 0; i < nuevosIds.length; i++) {
      if (i != posicion &&
          nuevosIds[i] == pokemonSeleccionado) {
        _mostrarMensaje(
          'Este Pokémon ya pertenece al equipo',
        );
        return;
      }
    }

    final bool reemplazo = posicion < nuevosIds.length;

    if (reemplazo) {
      // Reemplazar Pokémon existente
      nuevosIds[posicion] = pokemonSeleccionado;
    } else if (nuevosIds.length < 6) {
      // Agregar Pokémon nuevo
      nuevosIds.add(pokemonSeleccionado);
    } else {
      _mostrarMensaje('El equipo ya está completo');
      return;
    }

    // Crear equipo actualizado
    final equipoActualizado = equipoActual.copiarCon(
      pokemonIds: nuevosIds,
    );

    // Reemplazar el equipo en nuestra lista
    final nuevosEquipos = _equipos.map((actual) {
      if (actual.id == equipoId) {
        return equipoActualizado;
      }

      return actual;
    }).toList();

    // Guardar permanentemente
    final guardado = await _guardarCambios(
      nuevosEquipos,
    );

    if (guardado && mounted) {
      _mostrarMensaje(
        reemplazo
            ? 'Pokémon reemplazado correctamente'
            : 'Pokémon agregado al equipo',
      );
    }
  }

  // ==========================================
  // 9. NUEVO: QUITAR UN POKÉMON
  // ==========================================

  Future<void> _quitarPokemon(
    String equipoId,
    int posicion,
  ) async {
    if (_guardando) return;

    final equipo = _buscarEquipo(equipoId);

    if (equipo == null ||
        posicion < 0 ||
        posicion >= equipo.pokemonIds.length) {
      return;
    }

    // Copiar integrantes
    final nuevosIds = List<int>.from(
      equipo.pokemonIds,
    );

    // Quitar el Pokémon seleccionado
    nuevosIds.removeAt(posicion);

    // Actualizar equipo
    final equipoActualizado = equipo.copiarCon(
      pokemonIds: nuevosIds,
    );

    final nuevosEquipos = _equipos.map((actual) {
      if (actual.id == equipoId) {
        return equipoActualizado;
      }

      return actual;
    }).toList();

    final guardado = await _guardarCambios(
      nuevosEquipos,
    );

    if (guardado && mounted) {
      _mostrarMensaje('Pokémon eliminado del equipo');
    }
  }

  // ==========================================
  // 10. INTERFAZ PRINCIPAL
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      appBar: AppBar(
        title: const Text(
          'Mis Equipos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),

      body: _construirContenido(),

      // Botón para crear equipos
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: _guardando ? null : _crearEquipo,
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Crear equipo'),
      ),
    );
  }

  // ==========================================
  // 11. MOSTRAR LOS EQUIPOS
  // ==========================================

  Widget _construirContenido() {
    // Cargando información
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.red,
        ),
      );
    }

    // Error al recuperar equipos
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _cargarEquipos,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    // Sin equipos creados
    if (_equipos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(25),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.catching_pokemon,
                size: 90,
                color: Colors.red.shade300,
              ),

              const SizedBox(height: 18),

              const Text(
                'Todavía no tienes equipos',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Crea tu primer equipo y reúne '
                'hasta 6 Pokémon.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      );
    }

    // Mostrar lista de equipos
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        14, 18, 14, 100,
      ),

      itemCount: _equipos.length,

      itemBuilder: (context, index) {
        return _tarjetaEquipo(
          _equipos[index],
        );
      },
    );
  }

  // ==========================================
  // 12. TARJETA DE CADA EQUIPO
  // ==========================================

  Widget _tarjetaEquipo(
    EquipoPokemon equipo,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 18),
      elevation: 3,
      clipBehavior: Clip.antiAlias,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),

      child: Padding(
        padding: const EdgeInsets.all(18),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Encabezado del equipo
            Row(
              children: [
                const Icon(
                  Icons.shield,
                  color: Colors.red,
                  size: 30,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    equipo.nombre,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Editar nombre
                IconButton(
                  tooltip: 'Editar equipo',
                  onPressed: _guardando
                      ? null
                      : () => _editarEquipo(equipo),
                  icon: const Icon(
                    Icons.edit,
                    color: Colors.blue,
                  ),
                ),

                // Eliminar equipo
                IconButton(
                  tooltip: 'Eliminar equipo',
                  onPressed: _guardando
                      ? null
                      : () => _eliminarEquipo(equipo),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Contador de integrantes
            Text(
              '${equipo.cantidadPokemon}/6 Pokémon',
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 12),

            // Barra de progreso del equipo
            LinearProgressIndicator(
              value: equipo.cantidadPokemon / 6,
              minHeight: 8,
              borderRadius: BorderRadius.circular(10),
              backgroundColor: Colors.grey.shade200,
              color: Colors.red,
            ),

            const SizedBox(height: 18),

            // NUEVO: Seis ranuras interactivas
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 16,

                children: List.generate(6, (index) {
                  return _ranuraPokemon(
                    equipo,
                    index,
                  );
                }),
              ),
            ),

            const SizedBox(height: 16),

            Center(
              child: Text(
                equipo.estaCompleto
                    ? '¡Equipo completo!'
                    : 'Toca una ranura para agregar Pokémon',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: equipo.estaCompleto
                      ? Colors.green
                      : Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 13. RANURA INTERACTIVA DEL POKÉMON
  // ==========================================

  Widget _ranuraPokemon(
    EquipoPokemon equipo,
    int posicion,
  ) {
    // Comprobar si la ranura está ocupada
    final ocupado =
        posicion < equipo.pokemonIds.length;

    final int? pokemonId = ocupado
        ? equipo.pokemonIds[posicion]
        : null;

    return SizedBox(
      width: 82,

      child: InkWell(
        borderRadius: BorderRadius.circular(16),

        // NUEVO: Seleccionar, cambiar o quitar
        onTap: _guardando
            ? null
            : () => _abrirRanura(
                  equipo,
                  posicion,
                ),

        child: Padding(
          padding: const EdgeInsets.all(4),

          child: Column(
            children: [

              // Imagen o ranura vacía
              CircleAvatar(
                radius: 31,

                backgroundColor: ocupado
                    ? Colors.red.shade100
                    : Colors.grey.shade200,

                child: pokemonId != null
                    ? Image.network(
                        'https://raw.githubusercontent.com/'
                        'PokeAPI/sprites/master/sprites/'
                        'pokemon/$pokemonId.png',
                        width: 58,
                        height: 58,
                        fit: BoxFit.contain,

                        errorBuilder:
                            (context, error, stackTrace) {
                          return const Icon(
                            Icons.catching_pokemon,
                            color: Colors.red,
                          );
                        },
                      )

                    // Mostrar + cuando esté vacía
                    : const Icon(
                        Icons.add_circle_outline,
                        color: Colors.red,
                        size: 34,
                      ),
              ),

              const SizedBox(height: 7),

              // Número o estado
              Text(
                pokemonId == null
                    ? 'Agregar'
                    : '#${pokemonId.toString().padLeft(4, '0')}',

                textAlign: TextAlign.center,

                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: ocupado
                      ? Colors.black87
                      : Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
