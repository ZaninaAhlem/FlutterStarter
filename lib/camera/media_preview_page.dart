import 'dart:io';

import 'package:flutter/material.dart';

class MediaPreviewPage extends StatefulWidget {
  const MediaPreviewPage({Key? key, required this.mediaFile}) : super(key: key);
  final File? mediaFile;

  @override
  State<MediaPreviewPage> createState() => _MediaPreviewPageState();
}

class _MediaPreviewPageState extends State<MediaPreviewPage> {
  @override
  Widget build(BuildContext context) {
    return widget.mediaFile != null
        ? Image.file(
            widget.mediaFile!,
            fit: BoxFit.contain,
            alignment: Alignment.center,
          )
        : Container();
  }
}
