import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'bottom_nav_bar.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Flutter Demo',
    theme: ThemeData(
      primarySwatch: Colors.blue,
    ),
    home: const BottomNavBar(),
  ));
}
