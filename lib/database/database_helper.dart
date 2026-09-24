import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  /// Constructor privado que evita crear instancias externas de esta clase.
  /// La aplicacion utiliza la instancia estatica [instance] para compartir
  /// una unica conexion y centralizar todas las operaciones de SQLite.
  DatabaseHelper._init();

  /// Devuelve la conexion reutilizable de SQLite.
  ///
  /// Si la conexion aun no existe, abre `pokedex.db` mediante [_initDB], la
  /// guarda en memoria y la devuelve. Las siguientes llamadas reutilizan esa
  /// misma instancia en lugar de abrir el archivo otra vez.
  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDB('pokedex.db');

    return _database!;
  }

  /// Construye la ruta completa de la base de datos y abre su version actual.
  ///
  /// [filePath] contiene el nombre del archivo. La funcion combina ese nombre
  /// con la carpeta de bases de datos del dispositivo y registra [_createDB]
  /// para instalaciones nuevas y [_upgradeDB] para cambios de esquema.
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 7,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  /// Crea las tablas iniciales cuando la aplicacion se ejecuta por primera vez.
  ///
  /// Se crean las tablas de equipos, favoritos, relaciones entre equipos y
  /// Pokemon, y preferencias del usuario. Tambien se inserta una configuracion
  /// inicial con nivel `novato` y estado de configuracion incompleto.
  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE equipos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE favoritos (
        id INTEGER PRIMARY KEY,
        nombre TEXT NOT NULL,
        sprite TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE equipo_pokemon (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        equipo_id INTEGER NOT NULL,
        pokemon_id INTEGER NOT NULL,
        nombre TEXT NOT NULL,
        sprite TEXT NOT NULL,
        habilidad TEXT,
        objeto TEXT,
        movimiento_1 TEXT,
        movimiento_2 TEXT,
        movimiento_3 TEXT,
        movimiento_4 TEXT,
        es_shiny INTEGER NOT NULL DEFAULT 0,
        UNIQUE(equipo_id, pokemon_id),
        FOREIGN KEY (equipo_id)
          REFERENCES equipos(id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE configuracion (
        id INTEGER PRIMARY KEY,
        nivel_conocimiento TEXT NOT NULL,
        configurado INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.insert('configuracion', {
      'id': 1,
      'nivel_conocimiento': 'novato',
      'configurado': 0,
    });
  }

  /// Actualiza una base de datos existente entre versiones del esquema.
  ///
  /// Cada bloque comprueba [oldVersion] antes de aplicar su cambio, por lo que
  /// un usuario puede actualizar desde una version antigua sin perder sus
  /// datos. Las versiones agregan favoritos, Pokemon de equipos, configuracion,
  /// datos de movimientos y el indicador de Pokemon shiny.
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // ======================================================
    // VERSIÓN 2
    // FAVORITOS
    // ======================================================

    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS favoritos (
          id INTEGER PRIMARY KEY,
          nombre TEXT NOT NULL,
          sprite TEXT NOT NULL
        )
      ''');
    }

    // ======================================================
    // VERSIÓN 3
    // POKÉMON DE EQUIPO
    // ======================================================

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS equipo_pokemon (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          equipo_id INTEGER NOT NULL,
          pokemon_id INTEGER NOT NULL,
          nombre TEXT NOT NULL,
          sprite TEXT NOT NULL,
          UNIQUE(equipo_id, pokemon_id),
          FOREIGN KEY (equipo_id)
            REFERENCES equipos(id)
            ON DELETE CASCADE
        )
      ''');
    }

    // ======================================================
    // VERSIÓN 4
    // CONFIGURACIÓN
    // ======================================================

    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS configuracion (
          id INTEGER PRIMARY KEY,
          nivel_conocimiento TEXT NOT NULL
        )
      ''');

      await db.insert('configuracion', {
        'id': 1,
        'nivel_conocimiento': 'novato',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    // ======================================================
    // VERSIÓN 5
    // CONFIGURACIÓN REALIZADA
    // ======================================================

    if (oldVersion < 5) {
      await db.execute('''
        ALTER TABLE configuracion
        ADD COLUMN configurado INTEGER NOT NULL DEFAULT 0
      ''');
    }

    // ======================================================
    // VERSIÓN 6
    // INFORMACIÓN DE LOS POKÉMON DEL EQUIPO
    // ======================================================

    if (oldVersion < 6) {
      await db.execute('''
        ALTER TABLE equipo_pokemon
        ADD COLUMN habilidad TEXT
      ''');

      await db.execute('''
        ALTER TABLE equipo_pokemon
        ADD COLUMN objeto TEXT
      ''');

      await db.execute('''
        ALTER TABLE equipo_pokemon
        ADD COLUMN movimiento_1 TEXT
      ''');

      await db.execute('''
        ALTER TABLE equipo_pokemon
        ADD COLUMN movimiento_2 TEXT
      ''');

      await db.execute('''
        ALTER TABLE equipo_pokemon
        ADD COLUMN movimiento_3 TEXT
      ''');

      await db.execute('''
        ALTER TABLE equipo_pokemon
        ADD COLUMN movimiento_4 TEXT
      ''');
    }

    // ======================================================
    // VERSIÓN 7
    // POKÉMON SHINY
    // ======================================================

    if (oldVersion < 7) {
      await db.execute('''
        ALTER TABLE equipo_pokemon
        ADD COLUMN es_shiny INTEGER NOT NULL DEFAULT 0
      ''');
    }
  }

  // ======================================================
  // EQUIPOS
  // ======================================================

  /// Inserta un equipo nuevo en la tabla `equipos`.
  ///
  /// [nombre] es el texto que se mostrara al usuario. Devuelve el identificador
  /// autogenerado por SQLite para poder abrir y relacionar ese equipo.
  Future<int> insertarEquipo(String nombre) async {
    final db = await database;

    return await db.insert('equipos', {'nombre': nombre});
  }

  /// Consulta todos los registros de la tabla `equipos`.
  ///
  /// Devuelve una lista de mapas ordenada ascendentemente por `id`, conservando
  /// el orden en que normalmente fueron creados.
  Future<List<Map<String, dynamic>>> obtenerEquipos() async {
    final db = await database;

    return await db.query('equipos', orderBy: 'id ASC');
  }

  /// Cambia el nombre de un equipo existente en la tabla `equipos`.
  ///
  /// [id] identifica el registro que se actualiza y [nombre] reemplaza su
  /// nombre. Devuelve la cantidad de filas modificadas.
  Future<int> actualizarEquipo(int id, String nombre) async {
    final db = await database;

    return await db.update(
      'equipos',
      {'nombre': nombre},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Elimina un equipo de la tabla `equipos` usando su identificador.
  ///
  /// Las relaciones de sus Pokemon pueden eliminarse automaticamente gracias
  /// a la clave foranea configurada con `ON DELETE CASCADE`. Devuelve la
  /// cantidad de filas eliminadas.
  Future<int> eliminarEquipo(int id) async {
    final db = await database;

    return await db.delete('equipos', where: 'id = ?', whereArgs: [id]);
  }

  // ======================================================
  // FAVORITOS
  // ======================================================

  /// Guarda un Pokemon en la tabla `favoritos`.
  ///
  /// [id], [nombre] y [sprite] contienen la informacion minima que la lista de
  /// favoritos necesita. Si el ID ya existe, `ConflictAlgorithm.replace`
  /// actualiza sus datos en lugar de crear un duplicado.
  Future<void> agregarFavorito(int id, String nombre, String sprite) async {
    final db = await database;

    await db.insert('favoritos', {
      'id': id,
      'nombre': nombre,
      'sprite': sprite,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Elimina de `favoritos` el Pokemon cuyo ID coincide con [id].
  ///
  /// No modifica los detalles obtenidos desde la API ni los Pokemon guardados
  /// dentro de los equipos; solo quita la marca de favorito.
  Future<void> eliminarFavorito(int id) async {
    final db = await database;

    await db.delete('favoritos', where: 'id = ?', whereArgs: [id]);
  }

  /// Comprueba si la tabla `favoritos` contiene el Pokemon [id].
  ///
  /// La consulta se limita a un registro porque solo se necesita saber si
  /// existe. Devuelve `true` cuando esta guardado y `false` cuando no aparece.
  Future<bool> esFavorito(int id) async {
    final db = await database;

    final resultado = await db.query(
      'favoritos',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    return resultado.isNotEmpty;
  }

  /// Obtiene todos los Pokemon de la tabla `favoritos`.
  ///
  /// Devuelve sus IDs, nombres y sprites en una lista ordenada por ID para que
  /// la pantalla pueda reconstruir la cuadricula de favoritos.
  Future<List<Map<String, dynamic>>> obtenerFavoritos() async {
    final db = await database;

    return await db.query('favoritos', orderBy: 'id ASC');
  }

  // ======================================================
  // POKÉMON DE EQUIPO
  // ======================================================

  /// Relaciona un Pokemon con un equipo en la tabla `equipo_pokemon`.
  ///
  /// Guarda sus datos basicos y establece `es_shiny` en cero inicialmente.
  /// La restriccion unica y `ConflictAlgorithm.ignore` impiden que el mismo
  /// Pokemon se agregue dos veces al mismo equipo.
  Future<int> agregarPokemonAlEquipo(
    int equipoId,
    int pokemonId,
    String nombre,
    String sprite,
  ) async {
    final db = await database;

    return await db.insert('equipo_pokemon', {
      'equipo_id': equipoId,
      'pokemon_id': pokemonId,
      'nombre': nombre,
      'sprite': sprite,
      'es_shiny': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  /// Obtiene todos los Pokemon relacionados con [equipoId].
  ///
  /// La consulta devuelve tambien los datos de configuracion guardados y ordena
  /// los resultados por el ID interno de insercion para conservar su posicion.
  Future<List<Map<String, dynamic>>> obtenerPokemonsDelEquipo(
    int equipoId,
  ) async {
    final db = await database;

    return await db.query(
      'equipo_pokemon',
      where: 'equipo_id = ?',
      whereArgs: [equipoId],
      orderBy: 'id ASC',
    );
  }

  /// Elimina exclusivamente la relacion entre [equipoId] y [pokemonId].
  ///
  /// El Pokemon continua existiendo en la API y en favoritos si esta guardado
  /// alli. Devuelve la cantidad de relaciones eliminadas.
  Future<int> eliminarPokemonDelEquipo(int equipoId, int pokemonId) async {
    final db = await database;

    return await db.delete(
      'equipo_pokemon',
      where: 'equipo_id = ? AND pokemon_id = ?',
      whereArgs: [equipoId, pokemonId],
    );
  }

  // ======================================================
  // CONFIGURACIÓN DEL POKÉMON DEL EQUIPO
  // ======================================================

  /// Busca la configuracion del Pokemon [pokemonId] dentro de [equipoId].
  ///
  /// Devuelve el mapa completo del registro, incluyendo habilidad, objeto,
  /// movimientos y estado shiny. Si la relacion no existe, devuelve `null`.
  Future<Map<String, dynamic>?> obtenerConfiguracionPokemon(
    int equipoId,
    int pokemonId,
  ) async {
    final db = await database;

    final resultado = await db.query(
      'equipo_pokemon',
      where: 'equipo_id = ? AND pokemon_id = ?',
      whereArgs: [equipoId, pokemonId],
      limit: 1,
    );

    if (resultado.isEmpty) {
      return null;
    }

    return resultado.first;
  }

  /// Actualiza la configuracion de un Pokemon que ya pertenece a un equipo.
  ///
  /// Guarda los valores opcionales de habilidad, objeto y hasta cuatro
  /// movimientos. Convierte [esShiny] al formato entero que usa SQLite: `1`
  /// para shiny y `0` para la apariencia normal. Devuelve la cantidad de filas
  /// actualizadas.
  Future<int> actualizarConfiguracionPokemon({
    required int equipoId,
    required int pokemonId,
    String? habilidad,
    String? objeto,
    String? movimiento1,
    String? movimiento2,
    String? movimiento3,
    String? movimiento4,
    bool esShiny = false,
  }) async {
    final db = await database;

    return await db.update(
      'equipo_pokemon',
      {
        'habilidad': habilidad,
        'objeto': objeto,
        'movimiento_1': movimiento1,
        'movimiento_2': movimiento2,
        'movimiento_3': movimiento3,
        'movimiento_4': movimiento4,
        'es_shiny': esShiny ? 1 : 0,
      },
      where: 'equipo_id = ? AND pokemon_id = ?',
      whereArgs: [equipoId, pokemonId],
    );
  }

  // ======================================================
  // SHINY
  // ======================================================

  /// Consulta el indicador `es_shiny` de un Pokemon dentro de un equipo.
  ///
  /// Traduce el entero almacenado en SQLite a un booleano de Dart. Si no existe
  /// el registro solicitado, devuelve `false` como valor seguro por defecto.
  Future<bool> esPokemonShiny(int equipoId, int pokemonId) async {
    final db = await database;

    final resultado = await db.query(
      'equipo_pokemon',
      columns: ['es_shiny'],
      where: 'equipo_id = ? AND pokemon_id = ?',
      whereArgs: [equipoId, pokemonId],
      limit: 1,
    );

    if (resultado.isEmpty) {
      return false;
    }

    return resultado.first['es_shiny'] == 1;
  }

  /// Cambia solo la apariencia shiny de un Pokemon del equipo.
  ///
  /// Convierte [esShiny] en `1` o `0` antes de actualizar la columna de SQLite,
  /// sin sobrescribir la habilidad, el objeto ni los movimientos guardados.
  /// Devuelve la cantidad de filas modificadas.
  Future<int> actualizarShinyPokemon(
    int equipoId,
    int pokemonId,
    bool esShiny,
  ) async {
    final db = await database;

    return await db.update(
      'equipo_pokemon',
      {'es_shiny': esShiny ? 1 : 0},
      where: 'equipo_id = ? AND pokemon_id = ?',
      whereArgs: [equipoId, pokemonId],
    );
  }

  // ======================================================
  // NIVEL DE CONOCIMIENTO
  // ======================================================

  /// Obtiene el nivel de conocimiento de la configuracion global.
  ///
  /// Consulta el registro fijo con ID `1` y devuelve el texto guardado, como
  /// `novato` o `experto`. Si la fila aun no existe, utiliza `novato` como
  /// valor predeterminado para que la interfaz pueda continuar funcionando.
  Future<String> obtenerNivelConocimiento() async {
    final db = await database;

    final resultado = await db.query(
      'configuracion',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (resultado.isEmpty) {
      return 'novato';
    }

    return resultado.first['nivel_conocimiento'].toString();
  }

  /// Comprueba si el usuario termino la configuracion inicial.
  ///
  /// Lee la columna `configurado` del registro global y convierte `1` en
  /// `true`. Si no hay registro o el valor es distinto de `1`, devuelve
  /// `false` para mostrar nuevamente la pantalla de seleccion.
  Future<bool> configuracionRealizada() async {
    final db = await database;

    final resultado = await db.query(
      'configuracion',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (resultado.isEmpty) {
      return false;
    }

    final configurado = resultado.first['configurado'];

    return configurado == 1;
  }

  /// Guarda el nivel de conocimiento elegido por el usuario.
  ///
  /// Utiliza siempre el ID `1` para mantener una unica configuracion global,
  /// almacena [nivel] y marca `configurado` con `1`. Si ya existia una fila,
  /// `ConflictAlgorithm.replace` la reemplaza con los valores nuevos.
  Future<void> guardarNivelConocimiento(String nivel) async {
    final db = await database;

    await db.insert('configuracion', {
      'id': 1,
      'nivel_conocimiento': nivel,
      'configurado': 1,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
 