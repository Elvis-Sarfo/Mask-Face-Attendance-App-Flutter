import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:worker_manager/worker_manager.dart';

import '../../../../core/constants/constants.dart';

class AppPhotoService {
  static Future<File?> getImageFromGallery() async {
    File? image;
    final picker = ImagePicker();

    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

    if (pickedFile != null) {
      image = await _goToImageCropper(File(pickedFile.path));
      return image;
    } else {
      print('No image selected.');
    }
    return image;
  }

  static Future<File?> getImageFromCamera() async {
    File? image;
    final picker = ImagePicker();

    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
    );

    if (pickedFile != null) {
      image = await _goToImageCropper(File(pickedFile.path));
      return image;
    } else {
      print('No image selected.');
    }
    return image;
  }

  /* <---- Image Cropper ----> */
  static Future<File> _goToImageCropper(File? imageFile) async {
    File? croppedFile = (await ImageCropper().cropImage(
      sourcePath: imageFile!.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
            toolbarTitle: 'Cropper',
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false),
        IOSUiSettings(
          title: 'Cropper',
        ),
      ],
    )) as File?;
    return croppedFile!;
  }

  /// Gives a File From an url
  /// If the file is in cache you will get the cached file
  static Future<File> fileFromImageUrl(String imageUrl) async {
    File? gotImage;

    // IF the file is available in cache
    File? imageFromCache = await getImageFromCache(imageUrl);

    if (imageFromCache != null) {
      gotImage = imageFromCache;
    } else {
      final response = await http.get(Uri.parse(imageUrl));

      final documentDirectory = await getApplicationDocumentsDirectory();

      final Map<String, dynamic> data = {
        'path': documentDirectory.path,
        'response': response.bodyBytes,
      };

      File file =
          await Executor().execute(fun1: _writeFileToDiskIsolated, arg1: data);

      gotImage = file;
    }

    return gotImage;
  }

  static Future<File> _writeFileToDiskIsolated(
      Map<String, dynamic> data, TypeSendPort typesentPort) async {
    File theFile = File(data['path'] + 'imagetest');
    theFile.writeAsBytes(data['response']);
    return theFile;
  }

  /// Get Image From Cache
  static Future<File?> getImageFromCache(String imageUrl) async {
    File? dartFile;
    FileInfo? file = await DefaultCacheManager().getFileFromCache(imageUrl);
    if (file != null) {
      dartFile = file.file;
    } else {
      dartFile = null;
    }
    return dartFile;
  }
}
