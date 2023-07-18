import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:starter/camera/camera_page.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _selectedIndex = 0;
  final List<Widget> _widgetOptions = <Widget>[
    const Text('Home'),
    const NavigateToCamera(),
    const Text('School')
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Camera',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'School',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }
}

class NavigateToCamera extends StatefulWidget {
  const NavigateToCamera({Key? key}) : super(key: key);

  @override
  State<NavigateToCamera> createState() => _NavigateToCameraState();
}

class _NavigateToCameraState extends State<NavigateToCamera> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: GestureDetector(
          onTap: () async {
            await availableCameras().then(
              (value) => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => CameraPage(cameras: value))),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [Icon(Icons.camera_alt), Text("Open Camera")],
          ),
        ),
      ),
    );
  }
}
