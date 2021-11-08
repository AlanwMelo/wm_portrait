import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:portrait/classes/checkDir.dart';

//import 'package:photo_manager/photo_manager.dart';
import 'package:sqflite/sqflite.dart';

class MyDbManager {
  static final _databaseName = "portrait.db";
  static final _dbVersion = 1;

  Future<Database> dbManagerStartDB() async {
    final Future<Database> database = openDatabase(
      // Set the path to the database. Note: Using the `join` function from the
      // `path` package is best practice to ensure the path is correctly
      // constructed for each platform.
      join(await getDatabasesPath(), _databaseName),
      onCreate: (db, version) async {
        await db.execute("CREATE TABLE IF NOT EXISTS List_of_Lists ("
            "ID INTEGER PRIMARY KEY AUTOINCREMENT,"
            "list_name TEXT,"
            "list_path TEXT,"
            "created TEXT"
            ")");

        await db.execute(
            "CREATE TABLE IF NOT EXISTS directories_with_images_or_videos ("
            "ID INTEGER PRIMARY KEY AUTOINCREMENT,"
            "directory_path TEXT,"
            "modified NUMERIC"
            ")");
      },
      version: _dbVersion,
    );

    Database finalDB = await database;
    return finalDB;
  }

  /// ############ START TB - LISTS ############

  createNewList(String listName, String listPath, String created) async {
    // table = List_of_Lists
    Database db = await dbManagerStartDB();

    Map<String, dynamic> _newList = {
      "list_name": listName,
      "list_path": listName,
      "created": created,
    };

    await db.insert('List_of_Lists', _newList,
        conflictAlgorithm: ConflictAlgorithm.abort);
  }

  createListOfFiles(String listName) async {
    Database db = await dbManagerStartDB();
    await db.execute("CREATE TABLE IF NOT EXISTS $listName ("
        "ID INTEGER PRIMARY KEY AUTOINCREMENT,"
        "FileName TEXT,"
        "FileType TEXT,"
        "FilePath TEXT,"
        "FileOrientation TEXT,"
        "VideoDuration TEXT,"
        "OriginDevice TEXT,"
        "SpecialIMG TEXT,"
        "Created NUMERIC"
        ")");
  }

  updateList(String listName, String listPath, String created) async {
    // table = List_of_Lists
    Database db = await dbManagerStartDB();

    Map<String, dynamic> _updatedList = {
      "list_name": listName,
      "list_path": listPath,
      "created": created,
    };

    await db.update('List_of_Lists', _updatedList,
        where: 'list_name=?', whereArgs: [listName]);
  }

  readListOfLists() async {
    Database db = await dbManagerStartDB();

    List<Map> result = await db.rawQuery('SELECT * FROM List_of_Lists');

    return result;
  }

  deleteList(String listName) async {
    Database db = await dbManagerStartDB();

    await db
        .rawQuery('DELETE FROM List_of_Lists WHERE listName=?', ['$listName']);
    await db.execute("DROP TABLE IF EXISTS $listName");
  }

  /// ############ END TB - LISTS ############

  /// ############ START LIST MANAGEMENT ############

  insertFileIntoList(
      String listName,
      String fileName,
      String fileType,
      String filePath,
      String fileOrientation,
      String videoDuration,
      String originDevice,
      String specialIMG,
      int created) async {
    Database db = await dbManagerStartDB();

    Map<String, dynamic> fileIntoList = {
      "FileName": fileName,
      "FileType": fileType,
      "FilePath": filePath,
      "FileOrientation": fileOrientation,
      "VideoDuration": videoDuration,
      "OriginDevice": originDevice,
      "SpecialIMG": specialIMG,
      "Created": created,
    };

    await db.insert(listName, fileIntoList,
        conflictAlgorithm: ConflictAlgorithm.abort);
  }

  readFilesOfList(String listName) async {
    Database db = await dbManagerStartDB();

    List<Map> result = await db.rawQuery('SELECT * FROM $listName');

    return result;
  }

  deleteFileOfList(String listName, String fileName) async {
    Database db = await dbManagerStartDB();
    await db.rawQuery('DELETE FROM $listName WHERE FileName=?', [fileName]);
  }

  selectFileOfList(String listName, String fileName) async {
    Database db = await dbManagerStartDB();
    List<Map> result = await db
        .rawQuery('SELECT * FROM $listName WHERE FileName=?', [fileName]);

    return result;
  }

  /// ############ END LIST MANAGEMENT ############

  /// ############ START DIRECTORIES LIST MANAGEMENT ############

  addDirectoryToDB(String path, Database db, int modified) async {
    print('Adding DIR to DB: $path');
    Map<String, dynamic> _mapToDB = {
      "directory_path": path,
      "modified": modified
    };

    await db.insert('directories_with_images_or_videos', _mapToDB,
        conflictAlgorithm: ConflictAlgorithm.abort);

    await createDirectoryOfFiles(path, db);
  }

  readListOfDirectories(Database db) async {
    List<Map> result =
        await db.rawQuery('SELECT * FROM directories_with_images_or_videos');

    return result;
  }

  readDirectoryOfFiles(String path, Database db) async {
    String actualTableName = await _getTableName(path);

    print('Reading table $actualTableName');

    List<Map> result = await db.query(actualTableName);

    return result;
  }

  createDirectoryOfFiles(String path, Database db) async {
    String actualTableName = await _getTableName(path);

    print('Creating table $actualTableName');

    await db.execute("CREATE TABLE IF NOT EXISTS $actualTableName ("
        "FileName TEXT PRIMARY KEY,"
        "FileType TEXT,"
        "FilePath TEXT,"
        "ThumbPath TEXT,"
        "FileOrientation TEXT,"
        "VideoDuration TEXT,"
        "SpecialIMG TEXT,"
        "Created NUMERIC"
        ")");

    return true;
  }

  insertDirectoryOfFiles(
      {required String path,
      required String fileName,
      required String fileType,
      required String filePath,
      required String thumbPath,
      required String fileOrientation,
      required String videoDuration,
      required String specialIMG,
      required int created,
      required Database openDB}) async {
    String actualTableName = await _getTableName(path);

    Map<String, dynamic> fileToList = {
      "FileName": fileName,
      "FileType": fileType,
      "FilePath": filePath,
      "ThumbPath": thumbPath,
      "FileOrientation": fileOrientation,
      "VideoDuration": videoDuration,
      "SpecialIMG": specialIMG,
      "Created": created,
    };

    print('Inserting file $fileName into table $actualTableName');
    await openDB.insert(actualTableName, fileToList,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// ############ START DIRECTORIES LIST MANAGEMENT ############

  _transformDirInTableName(String dirName) {
    dirName = dirName.replaceAll(RegExp('[^A-Za-z0-9]'), '_');

    print(dirName);
    return dirName;
  }

  _getTableName(String path) async {
    String thumbPath = await CheckDir().getThumbPath(path);
    thumbPath = _transformDirInTableName(thumbPath);
    return thumbPath;
  }
}
