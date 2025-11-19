import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

List videoFileList = [];

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

  videoFileList = mediaFiles;
  //print("Length");
  //print(directoryFileList.length);
}

int getVideoAmount() {
  if (videoFileList.isEmpty) {
    loadSavedFiles();
    //print("Empty");
  }

  //print("Got Video Amount");
  return videoFileList.length;
}

List analysisFileList = [];

Future<void> loadSavedAnalysisFiles() async {
  final directoryPath = await _localPath;
  final directory = Directory("$directoryPath/analysis");
  
  if (!await directory.exists()) {
    return;
  }

  final analysisFiles = await directory.list().where((e) => e is File).toList();

  analysisFileList = analysisFiles;
}

int getAnalysisAmount() {
  if (analysisFileList.isEmpty) {
    loadSavedAnalysisFiles();
  }

  return analysisFileList.length;
}

FileSystemEntity getAnalysisbyIndex(int x) {
  return analysisFileList[x];
}