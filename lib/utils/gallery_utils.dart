import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

Future<File?> convertAssetToFile(AssetEntity asset) async {
  return await asset.file;
}

Future<File?> pickImageFromGallery(ImageSource source) async {
  try {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile == null) return null;
    final image = File(pickedFile.path);
    print('Picked image: $image');
    return image;
  } catch (errorMsg) {
    print('Error picking image: $errorMsg');
    return null;
  }
}

//LET US RETRIEVE ALL ASSETS AVAILABLE IN A SPECIFIC ALBUM
Future requestAlbumAssets(AssetPathEntity album) async {
  //SET THE 'END' TO THE HIGHEST NUMBER POSSIBLE
  final List<AssetEntity> assets = await album.getAssetListRange(
    start: 0,
    end: 1000000000000,
  );

  return assets;
}

Future requestAlbums(RequestType type) async {
  final List<AssetPathEntity> albums =
      await PhotoManager.getAssetPathList(type: type);

  return albums;
}

Future<bool> checkGalleryPermissions() async {

  //CHECK IF STORAGE PERMISSION IS GRANTED
  bool isVideoPermission = true;
  bool isPhotoPermission = true;
  bool isStoragePermission = true;

  // Only check for storage > Android 13
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

  if (androidInfo.version.sdkInt >= 33) {
    isVideoPermission = await Permission.videos.status.isGranted;
    isPhotoPermission = await Permission.photos.status.isGranted;
  } else {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    isStoragePermission = ps.isAuth;
  }

  if (!isVideoPermission) {
    Permission.videos.request();
    isVideoPermission = await Permission.videos.status.isGranted;
  }

  if (!isPhotoPermission) {
    await Permission.photos.request();
    isPhotoPermission = await Permission.photos.status.isGranted;
  }

  return isStoragePermission && isVideoPermission && isPhotoPermission;
}