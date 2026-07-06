import 'package:google_maps_flutter/google_maps_flutter.dart';

enum GoogleMapType { normal, satellite, terrain }

enum MapSource { google, osm }

extension MapTypeX on GoogleMapType {
  String get iconAsset {
    switch (this) {
      case GoogleMapType.normal:
        return "assets/icons/ic_map_default.png";
      case GoogleMapType.satellite:
        return "assets/icons/ic_map_satellite.png";
      case GoogleMapType.terrain:
        return "assets/icons/ic_map_terrain.png";
    }
  }

  MapType get mapTypeInGoogle {
    switch (this) {
      case GoogleMapType.normal:
        return MapType.normal;
      case GoogleMapType.satellite:
        return MapType.hybrid;
      case GoogleMapType.terrain:
        return MapType.terrain;
    }
  }

  String get name {
    switch (this) {
      case GoogleMapType.normal:
        return "Default";
      case GoogleMapType.satellite:
        return "Satellite";
      case GoogleMapType.terrain:
        return "Terrain";
    }
  }
}
