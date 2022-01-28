import 'dart:io';

import 'package:exif/exif.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:flutter_video_info/flutter_video_info.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:portrait/classes/checkDir.dart';
import 'package:portrait/classes/directoryManager.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:portrait/db/dbManager.dart';
import 'package:sqflite/sqflite.dart';
import 'package:video_compress/video_compress.dart';
import 'dart:developer';

class FileProcessor {
  generateLocalInfo(String path, Database openDB,
      {bool forceResync = false}) async {
    MyDbManager dbManager = MyDbManager();
    Directory appDir = await getApplicationDocumentsDirectory();
    String thumbPath = await CheckDir().getThumbPath(path);
    String imagesDir = '${appDir.path}/thumbImages/$thumbPath';

    await CheckDir().createDir(imagesDir);

    List<String> filesInDir =
        await DirectoryManager().getImagesAndVideosFromDirectory(path);
    List<Map> mapOfFilesInDB =
        await dbManager.readDirectoryFromAllFiles(path, openDB);
    List<String> filesToSync = [];
    List<String> filesToDelete = [];

    if (!forceResync) {
      /// Rotina muito pesada alterar para isolate
      /*/// Arquivos que estao na pasta mas não estão no DB
      for (var element in filesInDir) {
        if (!mapOfFilesInDB
            .toString()
            .toLowerCase()
            .contains(element.toLowerCase())) {
          filesToSync.add(element);
        }
      }
      /// Arquivos que estao no DB mas não estão na pasta
      for (var element in mapOfFilesInDB) {
        if (!filesInDir
            .toString()
            .toLowerCase()
            .contains(element['FilePath'].toString().toLowerCase())) {
          filesToDelete.add(element['FilePath']);
        }
      }*/
    } else {
      filesToSync = filesInDir;
    }

    for (var element in filesToSync) {
      File thisFile = File(element);
      String fileName =
          (thisFile.path.substring(thisFile.path.lastIndexOf('/') + 1));

      if (lookupMimeType(thisFile.path).toString().contains('image')) {
        await _generateLocalImageInfo(path, thisFile, '$imagesDir$fileName',
            thumbPath, forceResync, openDB);
      }
      if (lookupMimeType(thisFile.path).toString().contains('video')) {
        await _generateLocalVideoInfo(path, thisFile, '$imagesDir$fileName',
            thumbPath, forceResync, openDB);
      }
    }
    return true;
  }

  _generateLocalImageInfo(String path, File thisFile, String thumbName,
      String thumbPath, bool forceResync, Database openDB) async {
    MyDbManager dbManager = MyDbManager();

    if (forceResync) {
      try {
        File('$thumbName').deleteSync();
      } catch (e) {
        log(e.toString());
      }
    }

    if (File('$thumbName').existsSync()) {
      log('File already exists, skipping...');
    } else {
      log('Generating image info for image: $thumbName');

      try {
        String specialIMG = 'false';
        String orientation = 'portrait';
        DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(0);

        Future<Map<String, IfdTag>> data =
            readExifFromBytes(await thisFile.readAsBytes());

        await data.then((data) async {
          if (data.isNotEmpty) {
            if (data['Image Orientation'] != null) {
              if (data['Image Orientation']
                  .toString()
                  .toLowerCase()
                  .contains('horizontal')) {
                orientation = 'landscape';
              } else if (data['Image Orientation']
                  .toString()
                  .toLowerCase()
                  .contains('vertical')) {
                orientation = 'portrait';
              } else {
                String getNumbersFromString = data['Image Orientation']
                    .toString()
                    .replaceAll(new RegExp(r'[^0-9]'), '');
                orientation =
                    _getFileOrientation(int.parse(getNumbersFromString));
              }
            }

            if (data['Image ImageWidth'] != null) {
              int width = int.parse(data['Image ImageWidth'].toString());
              int height = int.parse(data['Image ImageLength'].toString());

              /// Panoramic and 360 images have the double width compared of it's height
              if ((width / 2) >= height) {
                specialIMG = 'true';
              }
            }

            for (var value in data.entries) {
              if (value.key == 'Image DateTime') {
                int year = int.parse(value.value.printable.substring(0, 4));
                int month = int.parse(value.value.printable.substring(5, 7));
                int day = int.parse(value.value.printable.substring(8, 11));
                int hour = int.parse(value.value.printable.substring(11, 13));
                int minute = int.parse(value.value.printable.substring(14, 16));
                int second = int.parse(value.value.printable.substring(17, 19));

                dateTime = DateTime(year, month, day, hour, minute, second);
              }
            }
          } else {
            ImageProperties properties =
                await FlutterNativeImage.getImageProperties(thisFile.path);

            if ((properties.width! / 2) >= properties.height!) {
              specialIMG = 'true';
            } else if (properties.width! > properties.height!) {
              orientation = 'landscape';
            }

            dateTime = thisFile.lastModifiedSync();
          }
        });

        String fileName =
            (thisFile.path.substring(thisFile.path.lastIndexOf('/') + 1));

        /// Generates Thumbnail for images
        if (!thisFile.path.toLowerCase().contains('jpg') &&
            !thisFile.path.toLowerCase().contains('jpeg')) {
          await thisFile.copy(thumbName);
        } else {
          await FlutterImageCompress.compressAndGetFile(
              thisFile.path, '$thumbName',
              quality: 20);


          DateTime getConvertedDate =
          DateTime.fromMillisecondsSinceEpoch(dateTime.millisecondsSinceEpoch);
          String convertedDate =
              '${getConvertedDate.day.toString().padLeft(2, '0')}/${getConvertedDate.month.toString().padLeft(2, '0')}/${getConvertedDate.year}';

          await dbManager.insertIntoAllFiles(
              path: path,
              fileName: fileName,
              fileType: 'image',
              filePath: thisFile.path,
              thumbPath: thumbName,
              fileDir: thisFile.path.substring(0, thisFile.path.lastIndexOf('/')+1),
              fileOrientation: orientation,
              videoDuration: '',
              specialIMG: specialIMG,
              created: dateTime.millisecondsSinceEpoch,
              createdDay: convertedDate,
              openDB: openDB);
        }
      } catch (e) {
        log(e.toString());
      }

      log('Info generated for image: $thumbName');
    }

    return true;
  }

  _generateLocalVideoInfo(String path, File thisFile, String thumbName,
      String thumbPath, bool forceResync, Database openDB) async {
    MyDbManager dbManager = MyDbManager();
    Duration duration = Duration(milliseconds: 500);
    String thumbNameWithoutExtension =
        thumbName.substring(0, thumbName.lastIndexOf('.'));

    if (forceResync) {
      try {
        File('$thumbNameWithoutExtension.jpg').deleteSync();
      } catch (e) {
        log(e.toString());
      }
    }

    try {
      if (File('$thumbNameWithoutExtension.jpg').existsSync()) {
        log('File already exists, skipping...');
      } else {
        log('Generating video info for video: $thumbName');

        final videoInfo = FlutterVideoInfo();
        String videoLength = '';
        String fileOrientation;

        await Future.delayed(duration);
        var info = await videoInfo.getVideoInfo(thisFile.path);

        int videoAux = info!.duration.toString().indexOf('.');
        videoLength = info.duration.toString().substring(0, videoAux);

        fileOrientation = _getFileOrientation(info.orientation);

        await Future.delayed(duration);

        /// Generates Thumbnail for videos
        final thumbnailFile =
            await VideoCompress.getFileThumbnail(thisFile.path,
                quality: 20, // default(100)
                position: 0 // default(-1)
                );

        await Future.delayed(duration);
        thumbnailFile.copy('$thumbNameWithoutExtension.jpg');

        DateTime date = DateTime.parse(info.date!);

        DateTime getConvertedDate =
        DateTime.fromMillisecondsSinceEpoch(date.millisecondsSinceEpoch);
        String convertedDate =
            '${getConvertedDate.day.toString().padLeft(2, '0')}/${getConvertedDate.month.toString().padLeft(2, '0')}/${getConvertedDate.year}';

        await dbManager.insertIntoAllFiles(
            path: path,
            fileName: info.title!,
            fileType: 'video',
            filePath: thisFile.path,
            fileDir: thisFile.path.substring(0, thisFile.path.lastIndexOf('/')+1),
            thumbPath: '$thumbNameWithoutExtension.jpg',
            fileOrientation: fileOrientation,
            videoDuration: videoLength,
            specialIMG: '',
            created: date.millisecondsSinceEpoch,
            createdDay: convertedDate,
            openDB: openDB);

        log('Info generated for video: $thumbName');
      }
    } catch (e) {
      log(e.toString());
    }
    return true;
  }

  _getFileOrientation(int? orientation) {
    if (orientation == 90 || orientation == 270) {
      return 'portrait';
    } else {
      return 'landscape';
    }
  }
}
