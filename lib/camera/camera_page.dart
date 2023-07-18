import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

import '../utils/camera_utils.dart';
import '../utils/gallery_utils.dart';
import 'media_preview_page.dart';

class CameraPage extends StatefulWidget {
  final List<CameraDescription>? cameras;

  const CameraPage({Key? key, this.cameras}) : super(key: key);

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  bool isLoading = false;
  CameraController? controller;

  //RETRIEVE MEDIA FOR THE FIRST ALBUM
  AssetPathEntity? currentAlbum;

  //HOLD RETRIEVED ASSETS
  List<AssetEntity> assets = [];

  late AnimationController _flashModeControlRowAnimationController;
  late Animation<double> _flashModeControlRowAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _flashModeControlRowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _flashModeControlRowAnimation = CurvedAnimation(
      parent: _flashModeControlRowAnimationController,
      curve: Curves.easeInCubic,
    );

    checkCameraPermissions().then((value) {
      if (value && widget.cameras?.isNotEmpty == true) {
        setCamera(widget.cameras![0]);
      }
      setState(() {});
    });
    getAssets(RequestType.common);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _flashModeControlRowAnimationController.dispose();
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(children: <Widget>[
          controller != null
              ? Center(child: CameraPreview(controller!))
              : Container(),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _flashModeControlRowWidget(),
                      IconButton(
                        icon: _getFlashIcon(),
                        color: Colors.white,
                        onPressed: controller != null
                            ? onFlashModeButtonPressed
                            : null,
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (assets.isNotEmpty)
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        itemCount: assets.length,
                        scrollDirection: Axis.horizontal,
                        shrinkWrap: true,
                        itemBuilder: (BuildContext context, int index) {
                          return GestureDetector(
                            onTap: () {
                              convertAssetToFile(assets[index]).then((file) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          MediaPreviewPage(mediaFile: file)),
                                );
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              child: AssetEntityImage(
                                assets[index],
                                isOriginal: false,
                                thumbnailSize: const ThumbnailSize.square(80),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(
                                      Icons.error,
                                      color: Colors.black38,
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                          onTap: isLoading
                              ? null
                              : () {
                            _pickImageFromGallery(ImageSource.gallery);
                          },
                          child: const Icon(Icons.photo_album_outlined,
                              color: Colors.white)),
                      GestureDetector(
                          onTap: isLoading ? null : onTakePictureButtonPressed,
                          child: const Icon(Icons.camera, color: Colors.white)),
                      GestureDetector(
                          onTap: isLoading ? null : _toggleCameraLens,
                          child: const Icon(Icons.cameraswitch_outlined,
                              color: Colors.white))
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              alignment: Alignment.center,
              child: const CircularProgressIndicator(
                color: Colors.white,
              ),
            )
        ]));
  }

  getAssets(RequestType type) async {
    final checkPermissions = await checkGalleryPermissions();

    if (!checkPermissions) {
      await PhotoManager.openSetting();
    } else {
      //NOW GET ALBUMS THAT HAVE MEDIA IN THEM THEN GET ALL MEDIA IN THEM
      await requestAlbums(type).then(
        (allAlbums) async {
          setState(() {
            if ((allAlbums as List).isEmpty) {
              return;
            } else {
              currentAlbum = allAlbums.first;
            }
          });

          //GET MEDIA FOR THE FIRST ALBUM
          if (currentAlbum != null) {
            await requestAlbumAssets(currentAlbum!).then(
              (allAssets) {
                setState(() {
                  assets = (allAssets as List<AssetEntity>)
                      .where((asset) =>
                          asset.type == AssetType.video ||
                          asset.type == AssetType.image)
                      .toList();
                });
              },
            );
          }
        },
      );
    }
  }

  Future<void> setCamera(CameraDescription cameraDescription) async {
    final CameraController? oldController = controller;
    if (oldController != null) {
      controller = null;
      await oldController.dispose();
    }

    if (!(await Permission.camera.isGranted)) {
      return;
    }

    final CameraController cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.max,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    controller = cameraController;

    // If the controller is updated then update the UI.
    cameraController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    try {
      await cameraController.initialize();
    } on CameraException catch (e) {
      // ignore: avoid_print
      print("${e.code}: ${e.description}");
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _toggleCameraLens() {
    // get current lens direction (front / rear)
    final lensDirection = controller?.description.lensDirection;
    CameraDescription? newDescription;
    if (lensDirection == CameraLensDirection.front) {
      newDescription = widget.cameras?.firstWhere((description) =>
          description.lensDirection == CameraLensDirection.back);
    } else {
      newDescription = widget.cameras?.firstWhere((description) =>
          description.lensDirection == CameraLensDirection.front);
    }

    if (newDescription != null) {
      setCamera(newDescription);
    } else {
      print('Asked camera not available');
    }
  }

  void onTakePictureButtonPressed() {
    setState(() {
      isLoading = true;
    });

    takePicture(controller).then((XFile? file) {
      if (mounted) {
        if (file != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
                builder: (context) =>
                    MediaPreviewPage(mediaFile: File(file.path))),
          );
          // ignore: avoid_print
          print('Picture saved to ${file.path}');
        }
      }

      setState(() {
        isLoading = false;
      });
    });
  }

  void _pickImageFromGallery(ImageSource source) async {
    final image = await pickImageFromGallery(source);
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
            builder: (context) => MediaPreviewPage(mediaFile: image)),
      );
    }
  }

  void onSetFlashModeButtonPressed(FlashMode mode) {
    setFlashMode(controller, mode).then((_) {
      if (mounted) {
        onFlashModeButtonPressed();
        setState(() {});
      }
      print('Flash mode set to ${mode.toString().split('.').last}');
    });
  }

  Widget _flashModeControlRowWidget() {
    return SizeTransition(
      sizeFactor: _flashModeControlRowAnimation,
      child: ClipRect(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.flash_off),
              color: Colors.white,
              onPressed: controller != null
                  ? () => onSetFlashModeButtonPressed(FlashMode.off)
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.flash_auto),
              color: Colors.white,
              onPressed: controller != null
                  ? () => onSetFlashModeButtonPressed(FlashMode.auto)
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.flash_on),
              color: Colors.white,
              onPressed: controller != null
                  ? () => onSetFlashModeButtonPressed(FlashMode.always)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Icon _getFlashIcon() {
    if (controller != null) {
      switch (controller!.value.flashMode) {
        case FlashMode.off:
          return const Icon(Icons.flash_off);
        case FlashMode.auto:
          return const Icon(Icons.flash_auto);
        case FlashMode.always:
          return const Icon(Icons.flash_on);
        case FlashMode.torch:
          return const Icon(Icons.highlight);
      }
    }
    return const Icon(Icons.flash_off);
  }

  void onFlashModeButtonPressed() {
    if (_flashModeControlRowAnimationController.value == 1) {
      _flashModeControlRowAnimationController.reverse();
    } else {
      _flashModeControlRowAnimationController.forward();
    }
  }
}
