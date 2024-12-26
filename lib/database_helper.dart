import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'mood.dart';
import 'dart:io'; // For platform-specific paths

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
    // Get the correct database path based on platform
    String databasesPath;
    
    if (Platform.isAndroid || Platform.isIOS) {
      // For mobile platforms (Android/iOS), use path_provider to get the directory
      final directory = await getApplicationDocumentsDirectory();
      databasesPath = directory.path;
    } else {
      // For desktop platforms (Windows, Mac, Linux), use the current working directory
      databasesPath = Directory.current.path;
    }

    // Create the full path for the database
    String path = join(databasesPath, 'moodsdata.db');

    // Initialize the SQLite database using sqflite_common_ffi
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE moods (
        rating INTEGER PRIMARY KEY
      )
    ''');
  }

  // Modified addMood method to take an int rating, convert it to a Mood object, and insert it
  Future<int> addMood(int rating) async {
    Database db = await instance.db;
    
    // Convert the integer rating to a Mood object
    Mood mood = Mood(rating: rating);
    
    // Insert the mood into the database
    return await db.insert('moods', mood.toMap());
  }

  Future<List<Map<String, dynamic>>> queryAllMoods() async {
    Database db = await instance.db;
    return await db.query('moods');
  }
  
  Future<int> clearDb() async {
  Database db = await instance.db;
  
  // Deletes all rows from the moods table
  return await db.delete('moods');
}
}
