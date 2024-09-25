import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'chat.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Alter table to add the senderId column if it's missing
      await db.execute('ALTER TABLE messages ADD COLUMN senderId TEXT;');
    }
  }
  Future _onCreate(Database db, int version) async {
    await db.execute(
      '''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT,
        message TEXT,
        senderId TEXT,
        receiverId TEXT,
        isSentByUser INTEGER,
        timestamp TEXT,
        messageType TEXT,
        conversationId INTEGER,
        FOREIGN KEY (conversationId) REFERENCES rooms (conversationId)
      )
      '''
    );
    await db.execute(
      '''
      CREATE TABLE rooms (
        conversationId INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT
      )
      ''',
    );
  }

  Future<void> insertMessage(Map<String, dynamic> message) async {
    final db = await database;
    await db.insert('messages', message);
  }
  Future<List<Map<String, dynamic>>> getRooms() async {
    final db = await database;
    return await db.query('rooms');
  }

  Future<List<Map<String, dynamic>>> getMessages() async {
    final db = await database;
    return await db.query('messages');
  }
}
