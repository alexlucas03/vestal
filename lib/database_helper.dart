import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'mood.dart';
import 'dart:io';
import 'package:postgres/postgres.dart';
import '/widgets/models/moment.dart';

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
      version: 12, // Increased version number for new table
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
    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE moments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT,
          date STRING,
          status STRING,
          description STRING,
          feelings STRING,
          ideal STRING,
          intensity INTEGER
        )
      ''');
    }

    if (oldVersion < 9) {
      await db.execute('''
        DROP TABLE moments 
      ''');
      await db.execute('''
        CREATE TABLE moments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT,
          date TEXT,
          status TEXT,
          description TEXT,
          feelings TEXT,
          ideal TEXT,
          intensity TEXT
        )
      ''');
    }

    if (oldVersion < 10) {
      await db.execute('''
        ALTER TABLE moments
        ADD COLUMN type TEXT
      ''');
    }

    if (oldVersion < 11) {
      // We need to recreate the table to modify column constraints
      await db.execute('ALTER TABLE moments RENAME TO moments_old');
      
      await db.execute('''
        CREATE TABLE moments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          date TEXT NOT NULL,
          status TEXT NOT NULL,
          description TEXT DEFAULT NULL,
          feelings TEXT DEFAULT NULL,
          ideal TEXT DEFAULT NULL,
          intensity TEXT DEFAULT NULL,
          type TEXT NOT NULL DEFAULT 'good'
        )
      ''');

      // Copy data from old table to new table
      await db.execute('''
        INSERT INTO moments (id, title, date, status, description, feelings, ideal, intensity, type)
        SELECT id, title, date, status, description, feelings, ideal, intensity, type
        FROM moments_old
      ''');

      // Drop the old table
      await db.execute('DROP TABLE moments_old');
    }

    if (oldVersion < 12) {
      await db.execute('''
        ALTER TABLE moments
        ADD COLUMN owner TEXT
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
    await db.delete('user_data');
    return await db.delete('moods');
  }

  Future<void> deleteAndRecreateTable() async {
    Database db = await instance.db;
    await db.execute('DROP TABLE IF EXISTS moods');
    await db.execute('DROP TABLE IF EXISTS user_data');
    await _createMoodsTable(db);
    await _createUserDataTable(db);
  }

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

  Future<List<Map<String, dynamic>>> queryAllMoments() async {
  Database db = await instance.db;
  try {
    return await db.query('moments', orderBy: 'date DESC');
  } catch (e) {
    print('Error in queryAllMoments: $e');
    throw e;
  }
}

  Future<int> addMoment(String title, String date, String status, String description, 
      String feelings, String ideal, String intensity, String type) async {
    Database db = await instance.db;
    String? userCode = await getUserCode();  // Add await here
    
    return await db.insert('moments', {
      'title': title,
      'date': date,
      'status': status,
      'description': description.isEmpty ? null : description,
      'feelings': feelings.isEmpty ? null : feelings,
      'ideal': ideal.isEmpty ? null : ideal,
      'intensity': intensity.isEmpty ? null : intensity,
      'type': type,
      'owner': userCode  // Use the awaited userCode
    });
  }

  Future<int> updateMoment(
    int id,
    String title, 
    String status,
    String description,
    String feelings,
    String ideal,
    String intensity
  ) async {
    Database db = await instance.db;
    
    return await db.update(
      'moments',
      {
        'title': title,
        'status': status,
        'description': description.isEmpty ? null : description,
        'feelings': feelings.isEmpty ? null : feelings,
        'ideal': ideal.isEmpty ? null : ideal,
        'intensity': intensity.isEmpty ? null : intensity,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> removeMoment(int id) async {
    Database db = await instance.db;
    await db.execute('''
      DELETE FROM moments 
      WHERE id = $id
    ''');
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
  
  Future<void> createPartnerTable(String partnerCode, String userCode, bool shareAll) async {
    try {
      final conn = await openConnection();
    // Moods
      // Generate both possible table name combinations
      String moodTableNameForward = '${partnerCode}_${userCode}_moods'.toLowerCase();
      String moodTableNameReverse = '${userCode}_${partnerCode}_moods'.toLowerCase();
      
      // Check if either table exists
      final existingTables = await conn.execute('''
        SELECT tablename 
        FROM pg_catalog.pg_tables 
        WHERE tablename IN ('$moodTableNameForward', '$moodTableNameReverse')
      ''');

      String finalMoodTableName;
      if (existingTables.isNotEmpty) {
        // Use the existing table name if found
        finalMoodTableName = existingTables[0][0] as String;
      } else {
        // If no table exists, use the forward arrangement
        finalMoodTableName = moodTableNameForward;
        
        // Create the new table with proper column definitions
        await conn.execute('''
          CREATE TABLE IF NOT EXISTS "$finalMoodTableName" (
            date TEXT,
            "${partnerCode.toLowerCase()}_mood" TEXT,
            "${userCode.toLowerCase()}_mood" TEXT
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
            AND tablename LIKE '%moods%'
            AND tablename != '$finalMoodTableName'
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
          'SELECT * FROM "$finalMoodTableName" WHERE date = \'$moodDate\''
        );

        final today = DateTime.now();
        final todayInt = int.parse('${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}');
        final moodDateInt = int.parse(moodDate);

        // Your condition
        if (shareAll || moodDateInt >= todayInt) {
          if (existingRow.isEmpty) {
            // Insert new row if date doesn't exist
            await conn.execute(
              'INSERT INTO "$finalMoodTableName" (date, "${userCode.toLowerCase()}_mood") VALUES (\'$moodDate\', \'$moodRating\')'
            );
          } else {
            // Update existing row with user's mood
            await conn.execute(
              'UPDATE "$finalMoodTableName" SET "${userCode.toLowerCase()}_mood" = \'$moodRating\' WHERE date = \'$moodDate\''
            );
          }
        }
      }
    // Moments
      // Generate both possible table name combinations
      String momentTableNameForward = '${partnerCode}_${userCode}_moments'.toLowerCase();
      String momentTableNameReverse = '${userCode}_${partnerCode}_moments'.toLowerCase();
      
      // Check if either table exists
      final existingMomentTables = await conn.execute('''
        SELECT tablename 
        FROM pg_catalog.pg_tables 
        WHERE tablename IN ('$momentTableNameForward', '$momentTableNameReverse')
      ''');

      String finalMomentTableName;
      if (existingMomentTables.isNotEmpty) {
        // Use the existing table name if found
        finalMomentTableName = existingMomentTables[0][0] as String;
      } else {
        // If no table exists, use the forward arrangement
        finalMomentTableName = momentTableNameForward;
        
        // Create the new table with proper column definitions
        await conn.execute('''
          CREATE TABLE IF NOT EXISTS "$finalMomentTableName" (
            id SERIAL PRIMARY KEY,
            title TEXT,
            date TEXT,
            status TEXT,
            description TEXT,
            feelings TEXT,
            ideal TEXT,
            intensity TEXT,
            type TEXT,
            owner TEXT
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
            AND tablename LIKE '%moments%'
            AND tablename != '$finalMomentTableName'
          LOOP
            EXECUTE 'DROP TABLE IF EXISTS ' || quote_ident(_table);
          END LOOP;
        END \$\$;
      ''');

      await conn.close();
    } catch (e) {
      print('Error in createPartnerTable: ${e.toString()}');
      rethrow;
    }
  }

  Future<void> CloudAddMood(int rating, String date, String userCode) async {
    final conn = await openConnection();

    try {
      // First, find tables matching the user code
      final moodTableResult = await conn.execute(
        'SELECT tablename FROM pg_catalog.pg_tables WHERE tablename LIKE \'%${userCode.toLowerCase()}%\' AND \'moods\''
      );

      if (moodTableResult.isNotEmpty) {
        final moodTableName = moodTableResult[0][0] as String;
        
        // Check if a row exists with the given date
        final existingRow = await conn.execute(
          'SELECT * FROM "$moodTableName" WHERE date = \'$date\''
        );

        String ratingStr = rating.toString();

        if (existingRow.isNotEmpty) {
          // Update existing row
          await conn.execute(
            'UPDATE "$moodTableName" SET ${userCode}_mood = \'$ratingStr\' WHERE date = \'$date\''
          );
        } else {
          // Insert new row if it doesn't exist
          await conn.execute(
            'INSERT INTO "$moodTableName" (date, ${userCode}_mood) VALUES (\'$date\', \'$ratingStr\')'
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
          String moodTableNameForward = '${partnerCode}_${userCode}_moods'.toLowerCase();
          String moodTableNameReverse = '${userCode}_${partnerCode}_moods'.toLowerCase();
          
          // Check which table exists
          final existingTables = await conn.execute('''
            SELECT tablename 
            FROM pg_catalog.pg_tables 
            WHERE tablename IN ('$moodTableNameForward', '$moodTableNameReverse')
          ''');

          if (existingTables.isNotEmpty) {
            String moodTableName = existingTables[0][0] as String;
            
            // Determine which column contains partner's mood based on table name
            String partnerMoodColumn = '${partnerCode.toLowerCase()}_mood';

            // Fetch partner's mood data
            final results = await conn.execute(
              'SELECT date, $partnerMoodColumn as rating FROM "$moodTableName" WHERE $partnerMoodColumn IS NOT NULL'
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

  Future<List<Map<String, dynamic>>> getAllMomentData() async {
    try {
      List<Map<String, dynamic>> userMoments = await queryAllMoments();
      List<Map<String, dynamic>> partnerMoments = [];
      
      String? partnerCode = await getPartnerCode();
      String? userCode = await getUserCode();
      
      if (partnerCode != null) {
        try {
          final conn = await openConnection();

          // Try both possible table name combinations
          String momentTableNameForward = '${partnerCode}_${userCode}_moments'.toLowerCase();
          String momentTableNameReverse = '${userCode}_${partnerCode}_moments'.toLowerCase();
          
          final existingTables = await conn.execute('''
            SELECT tablename 
            FROM pg_catalog.pg_tables 
            WHERE tablename IN ('$momentTableNameForward', '$momentTableNameReverse')
          ''');

          if (existingTables.isNotEmpty) {
            String momentTableName = existingTables[0][0] as String;

            // Fetch partner's moments with proper table quoting
            final results = await conn.execute('''
              SELECT * FROM "$momentTableName" 
              WHERE owner = '${partnerCode.toUpperCase()}'
            ''');

            // Convert results to maps
            for (final row in results) {
              partnerMoments.add({
                'id': row[0],
                'title': row[1],
                'date': row[2],
                'status': row[3],
                'description': row[4],
                'feelings': row[5],
                'ideal': row[6],
                'intensity': row[7],
                'type': row[8],
                'owner': row[9],
              });
            }
          }
          
          await conn.close();
        } catch (e) {
          print('Error fetching partner moment data: $e');
        }
      } else {
        return queryAllMoments();
      }

      // Return sorted combined list
      return [...userMoments, ...partnerMoments]..sort((a, b) {
        int dateA = int.parse(a['date'].toString());
        int dateB = int.parse(b['date'].toString());
        return dateB.compareTo(dateA);
      });
    } catch (e) {
      print('Error in getAllMomentData: $e');
      rethrow;
    }
  }

  Future<void> cloudAddMoment(Moment moment, String userCode) async {
    final conn = await openConnection();

    try {
      // Find tables matching the user code
      final momentTableResult = await conn.execute(
        'SELECT tablename FROM pg_catalog.pg_tables WHERE tablename LIKE \'%${userCode.toLowerCase()}%\' AND tablename LIKE \'%moments%\''
      );

      if (momentTableResult.isNotEmpty) {
        final momentTableName = momentTableResult[0][0] as String;

        // Properly escape strings and handle potential null values
        final results = await conn.execute(
          'SELECT * FROM "$momentTableName"'
        );

        int? existing;
        for (final row in results) {
          if (row[1] == moment.title && row[9] == moment.owner && row[2] == moment.date) {
            existing = int.parse(row[0].toString());
            break;
          }
        }

        if (existing == null) {
          await conn.execute('''
            INSERT INTO "$momentTableName" 
            (title, date, status, description, feelings, ideal, intensity, type, owner) 
            VALUES ('${moment.title}', '${moment.date}', '${moment.status}', '${moment.description}', '${moment.feelings}', '${moment.ideal}', '${moment.intensity}', '${moment.type}', '${moment.owner}')
          ''');
        } else {
          await conn.execute('''
            UPDATE "$momentTableName" 
            SET title = '${moment.title}', 
                status = '${moment.status}', 
                description = '${moment.description}', 
                feelings = '${moment.feelings}', 
                ideal = '${moment.ideal}', 
                intensity = '${moment.intensity}' 
            WHERE id = \$7
          ''');
        }
      }
      await conn.close();
    } catch (e) {
      print('Error in cloudAddMoment: $e');
      await conn.close();
      rethrow;
    }
  }
}