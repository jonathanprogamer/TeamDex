import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDB('pokedex.db');

    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(
    Database db,
    int version,
  ) async {
    // EQUIPOS
    await db.execute('''
      CREATE TABLE equipos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL
      )
    ''');

    // FAVORITOS
    await db.execute('''
      CREATE TABLE favoritos (
        id INTEGER PRIMARY KEY,
        nombre TEXT NOT NULL,
        sprite TEXT NOT NULL
      )
    ''');

    // POKÉMON DE LOS EQUIPOS
    await db.execute('''
      CREATE TABLE equipo_pokemon (
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

  Future<void> _upgradeDB(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Versión 2:
    // Agregar tabla de favoritos.
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS favoritos (
          id INTEGER PRIMARY KEY,
          nombre TEXT NOT NULL,
          sprite TEXT NOT NULL
        )
      ''');
    }

    // Versión 3:
    // Agregar Pokémon a los equipos.
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
  }

  // ============================================================
  // EQUIPOS
  // ============================================================

  Future<int> insertarEquipo(String nombre) async {
    final db = await database;

    return await db.insert(
      'equipos',
      {
        'nombre': nombre,
      },
    );
  }

  Future<List<Map<String, dynamic>>> obtenerEquipos() async {
    final db = await database;

    return await db.query(
      'equipos',
      orderBy: 'id ASC',
    );
  }

  Future<int> actualizarEquipo(
    int id,
    String nombre,
  ) async {
    final db = await database;

    return await db.update(
      'equipos',
      {
        'nombre': nombre,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> eliminarEquipo(int id) async {
    final db = await database;

    return await db.delete(
      'equipos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================================
  // FAVORITOS
  // ============================================================

  Future<void> agregarFavorito(
    int id,
    String nombre,
    String sprite,
  ) async {
    final db = await database;

    await db.insert(
      'favoritos',
      {
        'id': id,
        'nombre': nombre,
        'sprite': sprite,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> eliminarFavorito(int id) async {
    final db = await database;

    await db.delete(
      'favoritos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

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

  Future<List<Map<String, dynamic>>> obtenerFavoritos() async {
    final db = await database;

    return await db.query(
      'favoritos',
      orderBy: 'id ASC',
    );
  }

  // ============================================================
  // POKÉMON DE LOS EQUIPOS
  // ============================================================

  Future<int> agregarPokemonAlEquipo(
    int equipoId,
    int pokemonId,
    String nombre,
    String sprite,
  ) async {
    final db = await database;

    return await db.insert(
      'equipo_pokemon',
      {
        'equipo_id': equipoId,
        'pokemon_id': pokemonId,
        'nombre': nombre,
        'sprite': sprite,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

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

  Future<int> eliminarPokemonDelEquipo(
    int equipoId,
    int pokemonId,
  ) async {
    final db = await database;

    return await db.delete(
      'equipo_pokemon',
      where: 'equipo_id = ? AND pokemon_id = ?',
      whereArgs: [
        equipoId,
        pokemonId,
      ],
    );
  }
}