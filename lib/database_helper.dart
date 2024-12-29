import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'mood.dart';
import 'dart:io';
import 'package:postgres/postgres.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._instance();
  static Database? _database;
  DatabaseHelper._instance();

// ONBOARD - SQLITE

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
      version: 5, // Increased version number for new table
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await _createMoodsTable(db);
    await _createUserDataTable(db);
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');
    }
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

  // New method for creating the user_data table
  Future _createUserDataTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_data (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_code TEXT,
        partner_code TEXT 
      )
    ''');
  }

  // Method to store user code
  Future<void> storeUserCode(String code) async {
    Database db = await instance.db;
    
    // Check if a code already exists
    List<Map<String, dynamic>> existing = await db.query('user_data');
    if (existing.isEmpty) {
      await db.insert('user_data', {'user_code': code});
    }
  }

  // Method to get user code
  Future<String?> getUserCode() async {
    Database db = await instance.db;
    List<Map<String, dynamic>> results = await db.query('user_data');
    if (results.isNotEmpty) {
      return results.first['user_code'] as String;
    }
    return null;
  }

  // Fixed storePartnerCode method
  Future<void> storePartnerCode(String code) async {
      Database db = await instance.db;
      
      List<Map<String, dynamic>> existing = await db.query('user_data');
      if (existing.isEmpty) {
          // If no record exists, create new one with partner code
          await db.insert('user_data', {'partner_code': code});
      } else {
          // If record exists, update it with partner code
          await db.update(
              'user_data',
              {'partner_code': code},
              where: 'id = ?',
              whereArgs: [existing.first['id']],
          );
      }
  }

  Future<String?> getPartnerCode() async {
      Database db = await instance.db;
      List<Map<String, dynamic>> results = await db.query('user_data');
      if (results.isNotEmpty && results.first['partner_code'] != null) {
          return results.first['partner_code'] as String;
      }
      return null;
  }

  Future<void> clearPartnerCode() async {
      Database db = await instance.db;
      List<Map<String, dynamic>> existing = await db.query('user_data');
      if (existing.isNotEmpty) {
          await db.update(
              'user_data',
              {'partner_code': null},
              where: 'id = ?',
              whereArgs: [existing.first['id']],
          );
      }
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
    await db.delete('user_data'); // Also clear user data when clearing DB
    return await db.delete('moods');
  }

  Future<void> deleteAndRecreateTable() async {
    Database db = await instance.db;
    await db.execute('DROP TABLE IF EXISTS moods');
    await db.execute('DROP TABLE IF EXISTS user_data');
    await _createMoodsTable(db);
    await _createUserDataTable(db);
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

    return result.isNotEmpty;
  }

  Future<void> storeColorPreference(bool isPink) async {
    final db = await instance.db;
    await db.insert(
      'settings',
      {'key': 'color_preference', 'value': isPink ? '1' : '0'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> getColorPreference() async {
    final db = await instance.db;
    final List<Map<String, dynamic>> maps = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['color_preference'],
    );
    return maps.isNotEmpty ? maps.first['value'] == '1' : false;
  }

// CLOUD - Neon Postgres
  Future<Connection> openConnection() async {
    final conn = await Connection.open(Endpoint(
          host: 'ep-yellow-truth-a5ebo559.us-east-2.aws.neon.tech',
          database: 'voyagersdb',
          username: 'voyageruser',
          password: 'Sk3l3ton!sk3l3ton',
        ));
    return conn;
  }
  
  Future<void> createPartnerTable(String partnerCode, String userCode) async {
    String? currentPartnerCode = await getPartnerCode();
    if (partnerCode != currentPartnerCode) {
      try {
        final conn = await Connection.open(Endpoint(
          host: 'ep-yellow-truth-a5ebo559.us-east-2.aws.neon.tech',
          database: 'voyagersdb',
          username: 'voyageruser',
          password: 'Sk3l3ton!sk3l3ton',
        ));

        // Generate both possible table name combinations
        String tableNameForward = '${partnerCode}_$userCode'.toLowerCase();
        String tableNameReverse = '${userCode}_$partnerCode'.toLowerCase();
        
        // Check if either table exists
        final existingTables = await conn.execute('''
          SELECT tablename 
          FROM pg_catalog.pg_tables 
          WHERE tablename IN ('$tableNameForward', '$tableNameReverse')
        ''');

        String finalTableName;
        if (existingTables.isNotEmpty) {
          // Use the existing table name if found
          finalTableName = existingTables[0][0] as String;
        } else {
          // If no table exists, use the forward arrangement
          finalTableName = tableNameForward;
          
          // Create the new table with proper column definitions
          await conn.execute('''
            CREATE TABLE IF NOT EXISTS "$finalTableName" (
              date TEXT,
              ${partnerCode}_mood TEXT,
              ${userCode}_mood TEXT
            )
          ''');
        }

        // Clean up any other tables with this user code (except the one we're using)
        await conn.execute('''
          DO \$\$
          DECLARE
            _table text;
          BEGIN
            FOR _table IN 
              SELECT tablename 
              FROM pg_catalog.pg_tables 
              WHERE tablename LIKE '%${userCode.toLowerCase()}%'
              AND tablename != '$finalTableName'
            LOOP
              EXECUTE 'DROP TABLE IF EXISTS ' || quote_ident(_table);
            END LOOP;
          END \$\$;
        ''');

        Database sqliteDb = await instance.db;
        List<Map<String, dynamic>> localMoods = await sqliteDb.query('moods');

        // For each mood in SQLite, sync with PostgreSQL
        for (var mood in localMoods) {
          String moodDate = mood['date'].toString();
          String moodRating = mood['rating'].toString();

          // Check if the date already exists in PostgreSQL
          final existingRow = await conn.execute(
            'SELECT * FROM "$finalTableName" WHERE date = \'$moodDate\''
          );

          if (existingRow.isEmpty) {
            // Insert new row if date doesn't exist
            await conn.execute(
              'INSERT INTO "$finalTableName" (date, ${userCode}_mood) VALUES (\'$moodDate\', \'$moodRating\')'
            );
          } else {
            // Update existing row with user's mood
            await conn.execute(
              'UPDATE "$finalTableName" SET ${userCode}_mood = \'$moodRating\' WHERE date = \'$moodDate\''
            );
          }
        }

        await conn.close();
      } catch (e) {
        print('Error in createPartnerTable: ${e.toString()}');
        rethrow;
      }
    }
  }

  Future<void> CloudAddMood(int rating, String date, String userCode) async {
    final conn = await Connection.open(Endpoint(
      host: 'ep-yellow-truth-a5ebo559.us-east-2.aws.neon.tech',
      database: 'voyagersdb',
      username: 'voyageruser',
      password: 'Sk3l3ton!sk3l3ton',
    ));

    try {
      // First, find tables matching the user code
      final tableResult = await conn.execute(
        'SELECT tablename FROM pg_catalog.pg_tables WHERE tablename LIKE \'%${userCode.toLowerCase()}%\''
      );

      if (tableResult.isNotEmpty) {
        final tableName = tableResult[0][0] as String;
        
        // Check if a row exists with the given date
        final existingRow = await conn.execute(
          'SELECT * FROM "$tableName" WHERE date = \'$date\''
        );

        String ratingStr = rating.toString();

        if (existingRow.isNotEmpty) {
          // Update existing row
          await conn.execute(
            'UPDATE "$tableName" SET ${userCode}_mood = \'$ratingStr\' WHERE date = \'$date\''
          );
        } else {
          // Insert new row if it doesn't exist
          await conn.execute(
            'INSERT INTO "$tableName" (date, ${userCode}_mood) VALUES (\'$date\', \'$ratingStr\')'
          );
        }
      }
      await conn.close();
    } catch (e) {
      print('Error in CloudAddMood: $e');
      rethrow;
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>> getAllMoodData() async {
    try {
      // Get local moods
      List<Map<String, dynamic>> userMoods = await queryAllMoods();
      List<Map<String, dynamic>> partnerMoods = [];
      
      // Get partner code
      String? partnerCode = await getPartnerCode();
      String? userCode = await getUserCode();
      
      // If both codes exist, fetch partner data from PostgreSQL
      if (partnerCode != null && userCode != null) {
        try {
          final conn = await openConnection();

          // Try both possible table name combinations
          String tableNameForward = '${partnerCode}_$userCode'.toLowerCase();
          String tableNameReverse = '${userCode}_$partnerCode'.toLowerCase();
          
          // Check which table exists
          final existingTables = await conn.execute('''
            SELECT tablename 
            FROM pg_catalog.pg_tables 
            WHERE tablename IN ('$tableNameForward', '$tableNameReverse')
          ''');

          if (existingTables.isNotEmpty) {
            String tableName = existingTables[0][0] as String;
            
            // Determine which column contains partner's mood based on table name
            String partnerMoodColumn = '${partnerCode.toLowerCase()}_mood';

            // Fetch partner's mood data
            final results = await conn.execute(
              'SELECT date, $partnerMoodColumn as rating FROM "$tableName" WHERE $partnerMoodColumn IS NOT NULL'
            );

            // Convert results to the same format as user moods
            for (final row in results) {
              partnerMoods.add({
                'date': row[0],
                'rating': int.parse(row[1] as String),
              });
            }
          }
          
          await conn.close();
        } catch (e) {
          print('Error fetching partner mood data: $e');
          // Don't rethrow - we'll just return empty partner moods
        }
      }

      return {
        'userMoods': userMoods,
        'partnerMoods': partnerMoods,
      };
    } catch (e) {
      print('Error in getAllMoodData: $e');
      rethrow;
    }
  }
}