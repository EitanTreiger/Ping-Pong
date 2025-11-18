import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

List directoryFileList = [];

Future<String> get _localPath async {
  await Permission.storage.request().isGranted;

  final directory = await getApplicationDocumentsDirectory();
  return directory.path;
}

Future<void> loadSavedFiles() async {
  final directoryPath = await _localPath;
  //print(directoryPath);
  final directory = Directory("$directoryPath/camera/videos");
  
  if (!await directory.exists()) {
    return;
  }

  final mediaFiles = await directory.list().where((e) => e is File).toList();
  //print(mediaFiles);

  directoryFileList = mediaFiles;
  //print("Length");
  //print(directoryFileList.length);
}

int getVideoAmount() {
  if (directoryFileList.isEmpty) {
    loadSavedFiles();
    //print("Empty");
  }

  //print("Got Video Amount");
  return directoryFileList.length;
}