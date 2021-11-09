import 'dart:io';

import 'directoryManager.dart';

class CheckDir {
  ///Verifica se existe/cria o diretório
  createDir(String dirPath) async {
    if (await Directory(dirPath).exists()) {
      print('The directory already exists');
      print('Directory: $dirPath');
      return true;
    } else {
      print('The directory doesn\'t exists');
      print('Creating directory');
      await Directory(dirPath).create(recursive: true);
      print('Directory created');
      print('Directory: $dirPath');
      return true;
    }
  }

  getThumbPath(String path) async {
    Directory internalStorage =
        await DirectoryManager().getInternalStoragePath();
    Directory? externalStorage =
        await DirectoryManager().getExternalStoragePath();

    path = path.replaceAll(internalStorage.path, 'internal');
    if (externalStorage != null) {
      path = path.replaceAll(externalStorage.path, 'external');
    }

    return path;
  }
}
