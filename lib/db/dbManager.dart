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
        await db.execute(
            "CREATE TABLE IF NOT EXISTS directories_with_images_or_videos ("
            "ID INTEGER PRIMARY KEY AUTOINCREMENT,"
            "DirectoryPath TEXT,"
            "Modified NUMERIC"
            ")");

        await db.execute("CREATE TABLE IF NOT EXISTS presentations_lists ("
            "ID INTEGER PRIMARY KEY AUTOINCREMENT,"
            "ListName TEXT,"
            "Created NUMERIC"
            ")");

        await db.execute("CREATE TABLE IF NOT EXISTS presentation_files ("
            "ID INTEGER PRIMARY KEY AUTOINCREMENT,"
            "ListName TEXT,"
            "FileName TEXT,"
            "FileType TEXT,"
            "FilePath TEXT,"
            "ThumbPath TEXT,"
            "FileOrientation TEXT,"
            "VideoDuration TEXT,"
            "SpecialIMG TEXT,"
            "Created NUMERIC"
            ")");

        await db.execute("CREATE TABLE IF NOT EXISTS device_files ("
            "ID INTEGER PRIMARY KEY AUTOINCREMENT,"
            "FileName TEXT,"
            "FileType TEXT,"
            "FilePath TEXT,"
            "ThumbPath TEXT,"
            "FileOrientation TEXT,"
            "VideoDuration TEXT,"
            "SpecialIMG TEXT,"
            "Created NUMERIC"
            ")");
      },
      version: _dbVersion,
    );

    Database finalDB = await database;
    return finalDB;
  }

  /// ############ START PRESENTATIONS MANAGEMENT ############

  createNewPresentation(String listName, Database db, int created) async {
    Map<String, dynamic> _newList = {
      "ListName": listName,
      "Created": created,
    };

    await db.insert('presentations_lists', _newList,
        conflictAlgorithm: ConflictAlgorithm.abort);

    return true;
  }

  insertIntoPresentationFiles(
      String listName,
      String fileName,
      String fileType,
      String filePath,
      String thumbPath,
      String fileOrientation,
      String videoDuration,
      String specialIMG,
      int created,
      Database db) async {
    print('File $filePath inserted into presentation $listName');

    Map<String, dynamic> fileIntoList = {
      "ListName": listName,
      "FileType": fileType,
      "FileName": fileName,
      "FilePath": filePath,
      "ThumbPath": thumbPath,
      "FileOrientation": fileOrientation,
      "VideoDuration": videoDuration,
      "SpecialIMG": specialIMG,
      "Created": created,
    };

    await db.insert('presentation_files', fileIntoList,
        conflictAlgorithm: ConflictAlgorithm.abort);

    return true;
  }

  readFromPresentation(String presentationName, Database db) async {
    List<Map> result = await db.query('presentation_files',
        where: "ListName=?", whereArgs: [presentationName]);
    return result;
  }

  /// ############ EDN PRESENTATIONS MANAGEMENT ############

  /// ############ START FILES MANAGEMENT ############

  insertIntoAllFiles(
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

    print('Inserting file $fileName into table device_files');
    await openDB.insert('device_files', fileToList,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  readFileFromDB(String filePath, Database db) async {
    List<Map> result = await db
        .query('device_files', where: "FilePath=?", whereArgs: [filePath]);
    return result;
  }

  readAllFromAllFiles(Database openDB) async {
    List<Map> result = await openDB.query('device_files');
    return result;
  }

  readDirectoryFromAllFiles(String path, Database openDB) async {
    print('Reading from device_files where dir = $path');

    List<Map> result = await openDB.query(
      'device_files',
      where: 'FilePath LIKE ?',
      whereArgs: ['%$path%'],
    );

    return result;
  }

  /// ############ END FILES MANAGEMENT ############

  /// ############ START DIRECTORIES LIST MANAGEMENT ############

  addDirectoryToDB(String path, Database db, int modified) async {
    print('Adding DIR to DB: $path');
    Map<String, dynamic> _mapToDB = {
      "DirectoryPath": path,
      "Modified": modified
    };

    await db.insert('directories_with_images_or_videos', _mapToDB,
        conflictAlgorithm: ConflictAlgorithm.abort);

    return true;
  }

  readListOfDirectories(Database db) async {
    List<Map> result =
        await db.rawQuery('SELECT * FROM directories_with_images_or_videos');

    return result;
  }

  readDirectoryOfFiles(String path, Database openDB) async {
    String actualTableName = await _getTableName(path);

    print('Reading table $actualTableName');

    List<Map> result = await openDB.rawQuery('SELECT * FROM $actualTableName');

    return result;
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

  /// ############ END DIRECTORIES LIST MANAGEMENT ############

}
