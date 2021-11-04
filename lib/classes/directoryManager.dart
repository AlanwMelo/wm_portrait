import 'dart:async';
import 'dart:io';

import 'package:file_manager/file_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mime/mime.dart';

class DirectoryManager {
  getInternalStoragePath() async {
    Directory? internal;
    List directoryLists = await FileManager.getStorageList();
    internal = directoryLists[0];
    return internal;
  }

  getExternalStoragePath() async {
    Directory? external;
    List directoryLists = await FileManager.getStorageList();
    directoryLists.length > 1 ? external = directoryLists[1] : external = null;
    return external;
  }

  getDirectoriesWithImagesAndVideos(Function(List<String>) answer) async {
    List<String> foundDirectories = [];
    Timer? debounce;
    Directory internalStorage = await getInternalStoragePath();
    Directory? externalStorage = await getExternalStoragePath();

    _answerDebounce() {
      if (debounce?.isActive ?? false) {
        debounce!.cancel();
      }
      debounce = Timer(Duration(seconds: 3), () {
        answer(foundDirectories);
      });
    }

    _dirDigger(Directory directory) {
      for (var element in directory.listSync()) {
        if (element.runtimeType
            .toString()
            .toLowerCase()
            .contains('directory')) {
          try {
            element as Directory;

            element.list(recursive: true).forEach((element) {
              if (element.runtimeType
                  .toString()
                  .toLowerCase()
                  .contains('file')) {
                element as File;

                if (lookupMimeType(element.path).toString().contains('image') ||
                    lookupMimeType(element.path).toString().contains('video')) {
                  String dirName = element.path
                      .substring(0, element.path.lastIndexOf('/') + 1);

                  if (!foundDirectories.contains(dirName)) {
                    foundDirectories.add(dirName);
                    _answerDebounce();
                  }
                }
              }
            });
          } catch (e) {
            print(e);
          }
        }
      }
    }

    if (await Permission.storage.request().isGranted) {
      _dirDigger(internalStorage);
      if (externalStorage != null) {
        _dirDigger(externalStorage);
      }
    }
  }

  getImagesAndVideosFromDirectory(String path) {
    Directory thisDir = Directory(path);
    List<String> filesInDir = [];
    for (var element in thisDir.listSync()) {
      if (lookupMimeType(element.path).toString().contains('image') ||
          lookupMimeType(element.path).toString().contains('video')) {
        filesInDir.add(element.path);
      }
    }
    return filesInDir;
  }
}
