// Importing necessary packages for database operations and the 'Category' class.
import 'package:money_kos/pages/category.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// A class responsible for handling database operations related to categories.
class DatabaseHelper {
  // Static variable to hold the instance of the database.
  static Database? _database;

  // A getter method to access the database instance asynchronously.
  Future<Database> get database async {
    // If the database instance already exists, return it.
    if (_database != null) return _database!;

    // If the database instance doesn't exist, initialize and return it.
    _database = await initDatabase();
    return _database!;
  }

  // Method to initialize the database.
  Future<Database> initDatabase() async {
    // Define the path for the database file using the 'getDatabasesPath' method.
    final path = join(await getDatabasesPath(), 'categories.db');

    // Open the database or create a new one if it doesn't exist.
    return openDatabase(
      path,
      version:
          1, // Specify the database version number. Update if schema changes.
      onCreate: (db, version) {
        // Define the schema for the 'category' table if the database is created.
        return db.execute(
          'CREATE TABLE category(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, type INTEGER, created_at)',
        );
      },
    );
  }

  // Method to update a category in the 'category' table.
  Future<int> updateCategory(Category category) async {
    final db = await database;
    return await db.update(
      'category',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  // Method to insert a new category into the 'category' table.
  Future<int> insertCategory(Category category) async {
    final db = await database;
    return db.insert('category', category.toMap());
  }

  // Method to retrieve all categories from the 'category' table.
  Future<List<Category>> getAllCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('category');

    // Convert the result into a list of 'Category' objects.
    return List.generate(maps.length, (i) {
      return Category(
        id: maps[i]['id'],
        name: maps[i]['name'],
        type: maps[i]['type'],
      );
    });
  }

  // Method to delete a category from the 'category' table.
  Future<void> deleteCategory(int categoryId) async {
    final db = await database;
    await db.delete(
      'category',
      where: 'id = ?',
      whereArgs: [categoryId],
    );
  }
}
