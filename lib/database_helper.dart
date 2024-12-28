import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'mood.dart';
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._instance();
  static Database? _database;
  DatabaseHelper._instance();

  Future<Database> get db async {
    _database ??= await initDb();
    return _database!;
  }

  // Initialize the database
  Future<Database> initDb() async {
    String databasesPath;
    if (Platform.isAndroid || Platform.isIOS) {
      final directory = await getApplicationDocumentsDirectory();
      databasesPath = directory.path;
    } else {
      databasesPath = Directory.current.path;
    }

    String path = join(databasesPath, 'moodsdata.db');

    // Open database with onUpgrade callback
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await _createMoodsTable(db);
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    await _createMoodsTable(db);
  }

  // Separate method for creating the moods table
  Future _createMoodsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS moods (
        rating INTEGER,
        date STRING PRIMARY KEY
      )
    ''');
  }

  Future<int> addMood(int rating, String date) async {
    Database db = await instance.db;

    // Check if a mood entry for the given date already exists
    List<Map<String, dynamic>> existingMoods = await db.query(
      'moods',
      where: 'date = ?',
      whereArgs: [date],
    );

    if (existingMoods.isNotEmpty) {
      // Update the existing mood entry with the new rating
      int date = existingMoods.first['date'];
      return await db.update(
        'moods',
        {'rating': rating},
        where: 'date = ?',
        whereArgs: [date],
      );
    } else {
      // Insert a new mood entry
      Mood mood = Mood(rating: rating, date: date);
      return await db.insert('moods', mood.toMap());
    }
  }

  Future<List<Map<String, dynamic>>> queryAllMoods() async {
    Database db = await instance.db;
    return await db.query('moods');
  }

  Future<int> clearDb() async {
    Database db = await instance.db;
    return await db.delete('moods');
  }

  Future<void> deleteAndRecreateTable() async {
    Database db = await instance.db;
    await db.execute('DROP TABLE IF EXISTS moods');
    await _createMoodsTable(db);
  }

  // Close the database
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
  
  Future<List<Map<String, dynamic>>> queryMoodsByDate(String date) async {
    Database db = await instance.db;

    // Query moods by date
    List<Map<String, dynamic>> moods = await db.query(
      'moods',
      where: 'date = ?',
      whereArgs: [date],
    );

    return moods;
  }

  Future<bool> hasMoodForToday(String date) async {
    final db = await instance.db;

    // Query the database for the given date
    final result = await db.query(
      'moods',
      where: 'date = ?',
      whereArgs: [date],
    );

    return result.isNotEmpty; // Returns true if there's a record for today
  }
}