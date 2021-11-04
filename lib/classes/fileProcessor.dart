import 'dart:io';

import 'package:exif/exif.dart';
import 'package:flutter_video_info/flutter_video_info.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:portrait/classes/checkDir.dart';
import 'package:portrait/classes/directoryManager.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:portrait/db/dbManager.dart';
import 'package:video_compress/video_compress.dart';

class FileProcessor {
  generateLocalInfo(String path, {bool forceResync = false}) async {
    MyDbManager dbManager = MyDbManager();
    Directory appDir = await getApplicationDocumentsDirectory();
    String thumbPath = await CheckDir().getThumbPath(path);
    String imagesDir = '${appDir.path}/thumbImages/$thumbPath';

    await dbManager.createDirectoryOfFiles(thumbPath);
    await CheckDir().createDir(imagesDir);

    var result = DirectoryManager().getImagesAndVideosFromDirectory(path);

    for (var element in result) {
      File thisFile = File(element);
      String fileName =
          (thisFile.path.substring(thisFile.path.lastIndexOf('/') + 1));

      if (lookupMimeType(thisFile.path).toString().contains('image')) {
        await _generateLocalImageInfo(
            thisFile, '$imagesDir$fileName', thumbPath, forceResync);
      }
      if (lookupMimeType(thisFile.path).toString().contains('video')) {
        await _generateLocalVideoInfo(
            thisFile, '$imagesDir$fileName', thumbPath, forceResync);
      }
    }
    return true;
  }

  _generateLocalImageInfo(File thisFile, String thumbName, String thumbPath,
      bool forceResync) async {
    MyDbManager dbManager = MyDbManager();

    if (forceResync) {
      try {
        File('$thumbName').deleteSync();
      } catch (e) {
        print(e);
      }
    }

    if (File('$thumbName').existsSync()) {
      print('File already exists, skipping...');
    } else {
      print('Generating image info for image: $thumbName');

      try {
        String? specialIMG = 'false';
        String? orientation;
        DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(0);

        Future<Map<String, IfdTag>> data =
            readExifFromBytes(await thisFile.readAsBytes());

        await data.then((data) async {
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
        });

        String fileName =
            (thisFile.path.substring(thisFile.path.lastIndexOf('/') + 1));

        await dbManager.insertDirectoryOfFiles(
            dirName: thumbPath,
            fileName: fileName,
            fileType: 'image',
            filePath: thisFile.path,
            fileOrientation: orientation!,
            videoDuration: '',
            specialIMG: specialIMG!,
            created: dateTime.millisecondsSinceEpoch);

        /// Generates Thumbnail for images
        await FlutterImageCompress.compressAndGetFile(
            thisFile.path, '$thumbName',
            quality: 25);
      } catch (e) {
        print(e);
      }
    }

    return true;
  }

  _generateLocalVideoInfo(File thisFile, String thumbName, String thumbPath,
      bool forceResync) async {
    MyDbManager dbManager = MyDbManager();
    String thumbNameWithoutExtension =
        thumbName.substring(0, thumbName.lastIndexOf('.'));

    if (forceResync) {
      try {
        File('$thumbNameWithoutExtension.jpg').deleteSync();
      } catch (e) {
        print(e);
      }
    }

    try {
      if (File('$thumbNameWithoutExtension.jpg').existsSync()) {
        print('File already exists, skipping...');
      } else {
        print('Generating video info for video: $thumbName');

        final videoInfo = FlutterVideoInfo();
        String videoLength = '';
        String fileOrientation;

        var info = await videoInfo.getVideoInfo(thisFile.path);

        int videoAux = info!.duration.toString().indexOf('.');
        videoLength = info.duration.toString().substring(0, videoAux);

        fileOrientation = _getFileOrientation(info.orientation);

        await dbManager.insertDirectoryOfFiles(
            dirName: thumbPath,
            fileName: info.title!,
            fileType: 'video',
            filePath: thisFile.path,
            fileOrientation: fileOrientation,
            videoDuration: videoLength,
            specialIMG: '',
            created: thisFile.lastModifiedSync().millisecondsSinceEpoch);

        /// Generates Thumbnail for videos
        final thumbnailFile =
            await VideoCompress.getFileThumbnail(thisFile.path,
                quality: 30, // default(100)
                position: 0 // default(-1)
                );

        thumbnailFile.copy('$thumbNameWithoutExtension.jpg');
      }
    } catch (e) {
      print(e);
    }
  }

  _getFileOrientation(int? orientation) {
    if (orientation == 90 || orientation == 270) {
      return 'portrait';
    } else {
      return 'landscape';
    }
  }
}
