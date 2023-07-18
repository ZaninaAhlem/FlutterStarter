import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

Future<XFile?> takePicture(CameraController? controller) async {
  final CameraController? cameraController = controller;
  if (cameraController == null || !cameraController.value.isInitialized) {
    // ignore: avoid_print
    print('Error: select a camera first.');
    return null;
  }

  try {
    final XFile file = await cameraController.takePicture();
    return file;
  } on CameraException catch (e) {
    // ignore: avoid_print
    print("${e.code}: ${e.description}");
    return null;
  }
}

Future<void> setFlashMode(CameraController? controller, FlashMode mode) async {
  if (controller == null) {
    return;
  }

  try {
    await controller.setFlashMode(mode);
  } on CameraException catch (e) {
    print('Error: ${e.code}\n${e.description}');
    rethrow;
  }
}

Future<bool> checkCameraPermissions() async {
  var cameraPermissionStatus = await Permission.camera.request();
  var microphonePermissionStatus = await Permission.microphone.request();

  if (cameraPermissionStatus == PermissionStatus.denied) {
    bool showRationale =
    await Permission.microphone.shouldShowRequestRationale;
    if (showRationale) {
      cameraPermissionStatus = await Permission.camera.request();
    }
  } else if (cameraPermissionStatus == PermissionStatus.permanentlyDenied) {
    // Show app settings
    await openAppSettings();
  } else if (microphonePermissionStatus == PermissionStatus.denied) {
    bool showRationale =
    await Permission.microphone.shouldShowRequestRationale;
    if (showRationale) {
      microphonePermissionStatus = await Permission.microphone.request();
    }
  } else if (microphonePermissionStatus ==
      PermissionStatus.permanentlyDenied) {
    // Show app settings
    await openAppSettings();
  }

  return (cameraPermissionStatus == PermissionStatus.granted &&
      microphonePermissionStatus == PermissionStatus.granted);
}
