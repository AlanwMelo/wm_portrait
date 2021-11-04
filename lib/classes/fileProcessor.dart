import 'dart:io';

import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:portrait/classes/checkDir.dart';
import 'package:portrait/classes/directoryManager.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_compress/video_compress.dart';

class FileProcessor {
  generateLocalInfo(String path) async {
    Directory appDir = await getApplicationDocumentsDirectory();
    String thumbPath = await CheckDir().getThumbPath(path);
    String imagesDir = '${appDir.path}/thumbImages/$thumbPath';

    await CheckDir().createDir(imagesDir);

    var result = DirectoryManager().getImagesAndVideosFromDirectory(path);

    for (var element in result) {
      File thisFile = File(element);
      String fileName =
          (thisFile.path.substring(thisFile.path.lastIndexOf('/') + 1));

      if (lookupMimeType(thisFile.path).toString().contains('image')) {
        await _generateLocalImageInfo(thisFile, '$imagesDir$fileName');
      }
      if (lookupMimeType(thisFile.path).toString().contains('video')) {
        await _generateLocalVideoInfo(thisFile, '$imagesDir$fileName');
      }
    }
  }

  _generateLocalImageInfo(File thisFile, String thumbName) async {
    if (File('$thumbName').existsSync()) {
      print('File already exists, skipping...');
    } else {
      print('Creating Thumb: $thumbName');

      try {
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

  _generateLocalVideoInfo(File thisFile, String thumbName) async {
    String thumbNameWithoutExtension =
        thumbName.substring(0, thumbName.lastIndexOf('.'));

    if (File('$thumbName.jpg').existsSync()) {
      print('File already exists, skipping...');
    } else {
      /// Generates Thumbnail for videos
      try {
        final thumbnailFile =
            await VideoCompress.getFileThumbnail(thisFile.path,
                quality: 30, // default(100)
                position: 0 // default(-1)
                );

        thumbnailFile.copy('$thumbNameWithoutExtension.jpg');
      } catch (e) {
        print(e);
      }
    }
  }
}
