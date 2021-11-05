import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:portrait/classes/fileProcessor.dart';
import 'package:portrait/classes/syncingStream.dart';
import 'package:portrait/db/dbManager.dart';

import 'directoryManager.dart';

class SyncFiles {
  final SyncingStream syncingStreamClass;

  SyncFiles(this.syncingStreamClass);

  MyDbManager dbManager = MyDbManager();

  syncDirectories(Function(String) dirSynced) async {
    //verificar pemissao aqui!!!!

    await Permission.storage.request().isGranted.whenComplete(() {});
    if (await Permission.storage.request().isGranted) {
      syncingStreamClass.streamControllerSink.add('start');
      syncingStreamClass.streamControllerSink.add('Syncing directories list');
      await DirectoryManager()
          .getDirectoriesWithImagesAndVideos((answer) async {
        syncingStreamClass.streamControllerSink.add('stop');

        for (var element in answer) {
          await dbManager.addDirectoryToDB(element);
          dirSynced(element);
        }
        dirSynced('done');
      });
    } else {
      print('syncfiles else?');
    }
  }

  syncFiles(List<Directory> directories) async {
    syncingStreamClass.streamControllerSink.add('start');
    for (var directory in directories) {
      String dirName = directory.path.substring(0,directory.path.lastIndexOf('/'));
      dirName = dirName.substring(dirName.lastIndexOf('/')+1);

      syncingStreamClass.streamControllerSink.add('Syncing $dirName');

      await FileProcessor().generateLocalInfo(directory.path);

    }
    syncingStreamClass.streamControllerSink.add('stop');
  }
}
