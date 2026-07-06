import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nusantara_gps/core/app/app_color_theme.dart';

class MainShellScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const MainShellScreen({super.key, required this.navigationShell});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int get _currentIndex => widget.navigationShell.currentIndex;

  void _onTap(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == _currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        onTap: _onTap,
        selectedLabelStyle: TextStyle(fontSize: 10),
        unselectedLabelStyle: TextStyle(fontSize: 10),
        backgroundColor: Colors.white,
        selectedItemColor: AppColorTheme.primary,
        unselectedItemColor: AppColorTheme.gray400,
        currentIndex: _currentIndex,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car_filled_outlined),
            label: 'Kendaraan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border_outlined),
            label: 'Lokasi Minat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fence_outlined), 
            label: 'Geofence'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Pengaturan',
          ),
        ],
      ),
    );
  }
}
