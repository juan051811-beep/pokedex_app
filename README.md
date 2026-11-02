#Pokédex App

### Práctica 7 — Pokédex con PokéAPI

Aplicación multiplataforma desarrollada con **Flutter y Dart**, que permite explorar información de Pokémon mediante la API pública PokéAPI.

El proyecto incluye un catálogo interactivo, búsqueda avanzada, filtros, información detallada, administración de equipos, Pokémon favoritos y visualización de versiones Shiny.

##  Demostración en línea

**[Abrir Pokédex Web](https://tourmaline-tarsier-497d07.netlify.app/)**

La aplicación se encuentra publicada en Netlify y puede utilizarse directamente desde un navegador, sin necesidad de instalar Flutter.

##  Funcionalidades principales

###  1. Catálogo Pokémon
- Visualización de Pokémon mediante tarjetas con imágenes, nombres, números y tipos.
- Colores personalizados según el tipo de Pokémon.
- Cuadrícula adaptable a diferentes tamaños de pantalla.
- **Infinite scrolling:** descarga progresiva de Pokémon en bloques de 20 elementos.
- Indicadores de carga y manejo de errores de conexión.

###  2. Búsqueda y filtros
- Búsqueda de Pokémon por nombre o número.
- Filtrado por tipo elemental.
- Filtrado por generación.
- Combinación de filtros de tipo y generación.
- Navegación directa a los detalles de cada Pokémon.

###  3. Información detallada
- Ilustración oficial y sprite clásico.
- Número, nombre y tipos.
- Altura y peso.
- Habilidades.
- Estadísticas base representadas mediante barras de progreso.
- Reproducción del grito del Pokémon.
- Visualización de cadenas evolutivas, incluyendo sus ramificaciones.

###  4. Administración de equipos
- Crear equipos con nombres personalizados.
- Agregar hasta seis Pokémon por equipo.
- Reemplazar o eliminar integrantes.
- Evitar Pokémon duplicados dentro de un mismo equipo.
- Editar y eliminar equipos.
- Almacenamiento local persistente mediante `shared_preferences`.

###  5. Pokémon favoritos
- Marcar y desmarcar Pokémon como favoritos.
- Consultar la colección personal en una pantalla independiente.
- Eliminar favoritos directamente desde la colección.
- Contador de Pokémon favoritos.
- Persistencia local después de cerrar y volver a abrir la aplicación.

###  6. Modo Shiny
- Alternar entre la apariencia normal y Shiny.
- Mostrar ilustraciones y sprites especiales cuando estén disponibles.
- Transiciones animadas al cambiar de apariencia.
- Conservar las estadísticas, habilidades y demás información del Pokémon.

##  Tecnologías utilizadas

| Tecnología | Función |
|---|---|
| Flutter | Desarrollo multiplataforma e interfaces gráficas |
| Dart | Lenguaje de programación |
| PokéAPI | Obtención de información de Pokémon |
| http | Solicitudes HTTP a la API |
| shared_preferences | Almacenamiento local de equipos, favoritos y caché |
| audioplayers | Reproducción de sonidos de Pokémon |
| Git y GitHub | Control de versiones y alojamiento del código |
| Netlify | Publicación de la aplicación web |

##  Organización del proyecto

El código se encuentra organizado principalmente en los siguientes archivos:

| Archivo o carpeta | Descripción |
|---|---|
| `lib/main.dart` | Inicio de la aplicación y catálogo principal |
| `lib/models/equipo_pokemon.dart` | Modelo de datos de los equipos |
| `lib/screens/` | Pantallas de detalles, búsqueda, filtros, equipos y favoritos |
| `lib/services/pokemon_service.dart` | Comunicación con PokéAPI |
| `lib/services/pokemon_type_service.dart` | Consulta de tipos y caché local |
| `lib/services/equipo_storage_service.dart` | Persistencia de equipos |
| `lib/services/favoritos_storage_service.dart` | Persistencia de favoritos |
| `android/` | Configuración del proyecto Android |
| `ios/` | Configuración del proyecto iOS |
| `web/` | Configuración de la aplicación web |

##  Instalación y ejecución

**Requisitos:** Flutter SDK instalado, un navegador compatible o un dispositivo configurado y conexión a internet.

**1. Clonar el repositorio:**

`git clone https://github.com/juan051811-beep/pokedex_app.git`

**2. Entrar al proyecto:**

`cd pokedex_app`

**3. Instalar las dependencias:**

`flutter pub get`

**4. Ejecutar la aplicación en Chrome:**

`flutter run -d chrome`

También se puede utilizar un servidor web local con puerto fijo:

`flutter run -d web-server --web-port=5050`

En este caso, abrir `http://localhost:5050` en el navegador.

### Compilación para producción

Para generar los archivos de la versión web:

`flutter build web --release`

Los archivos compilados se generan en la carpeta `build/web/` y pueden publicarse en un servicio de alojamiento web.

##  Rendimiento y optimizaciones

Se implementaron las siguientes estrategias:

- **Carga progresiva:** el catálogo solicita solamente 20 Pokémon por página.
- **Infinite scrolling:** se solicitan nuevos elementos al aproximarse al final de la cuadrícula.
- **Prevención de peticiones duplicadas:** se controla el estado de carga antes de consultar nuevamente.
- **Caché de tipos:** los datos se almacenan localmente para evitar descargar repetidamente los 18 tipos.
- **Vigencia de caché:** los tipos almacenados se actualizan cuando la información supera siete días de antigüedad.
- **Componentes reutilizables:** las pantallas utilizan widgets para organizar su interfaz.

##  Persistencia de datos

Los equipos y Pokémon favoritos se almacenan localmente mediante `shared_preferences`.

Los datos permanecen disponibles después de cerrar y volver a abrir la aplicación, siempre que se utilice el mismo almacenamiento y no se borren los datos del sitio.

**Nota:** los equipos y favoritos no se sincronizan entre dispositivos ni entre dominios diferentes. Cada instalación o navegador administra su propia colección.

##  API utilizada

La información se obtiene de **[PokéAPI](https://pokeapi.co/)**, una API REST pública dedicada a los datos del universo Pokémon.

Se utilizan recursos relacionados con Pokémon, especies, tipos, generaciones y cadenas evolutivas.

Las imágenes y recursos gráficos se obtienen de los datos proporcionados por PokéAPI y sus recursos asociados.

##  Plataformas

- **Web:** versión publicada en Netlify.
- **Android:** proyecto Flutter configurado; compilación y validación en dispositivo pendientes.
- **iOS y escritorio:** estructura de proyecto disponible mediante Flutter, sin pruebas finales documentadas.

##  Contexto académico

Proyecto desarrollado como parte de la **Práctica 7: Pokédex App con PokéAPI**, para la asignatura de Programación de Dispositivos Móviles.

El objetivo es aplicar conceptos de consumo de APIs REST, programación asíncrona, manejo de estados, almacenamiento local, navegación, interfaces responsivas y optimización de rendimiento.

---

**Repositorio:** https://github.com/juan051811-beep/pokedex_app

**Aplicación web:** https://tourmaline-tarsier-497d07.netlify.app/
