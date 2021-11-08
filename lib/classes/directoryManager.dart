import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:file_manager/file_manager.dart';
import 'package:flutter/foundation.dart';
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

    ReceivePort receiverPort = ReceivePort();
    Map argsMap = Map();
    argsMap['sendPort'] = receiverPort.sendPort;

    _answerDebounce() {
      if (debounce?.isActive ?? false) {
        debounce!.cancel();
      }
      debounce = Timer(Duration(seconds: 3), () {
        answer(foundDirectories);
      });
    }

    receiverPort.listen((message) {
      if (!foundDirectories.contains(message)) {
        foundDirectories.add(message);
        _answerDebounce();
      }
    });

    if (await Permission.storage.request().isGranted) {
      argsMap['dir'] = internalStorage;
      compute(_isolatedDirDigger, argsMap);
      if (externalStorage != null) {
        argsMap['dir'] = externalStorage;
        compute(_isolatedDirDigger, argsMap);
      }
    }
  }

  getImagesAndVideosFromDirectory(String path) {
    return compute(_isolatedGetImagesAndVideosFromDirectory, path);
  }
}

_isolatedDirDigger(Map argsMap) {
  SendPort sendPort = argsMap['sendPort'];
  Directory directory = argsMap['dir'];

  for (var element in directory.listSync()) {
    if (element.runtimeType.toString().toLowerCase().contains('directory')) {
      try {
        element as Directory;

        for (var element in element.listSync(recursive: true)) {
          if (element.runtimeType.toString().toLowerCase().contains('file')) {
            element as File;

            if (lookupMimeType(element.path).toString().contains('image') ||
                lookupMimeType(element.path).toString().contains('video')) {
              String dirName =
                  element.path.substring(0, element.path.lastIndexOf('/') + 1);
              sendPort.send(dirName);
            }
          }
        }
      } catch (e) {
        print(e);
      }
    }
  }
  return true;
}

_isolatedGetImagesAndVideosFromDirectory(String path) {
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