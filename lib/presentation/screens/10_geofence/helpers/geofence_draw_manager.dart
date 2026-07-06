import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nusantara_gps/core/app/app_color_theme.dart';
import 'package:nusantara_gps/domain/entities/geofence_draw_mode.dart';

class GeofenceDrawManager extends ChangeNotifier {

  // Mode aktif 
  GeofenceDrawMode _drawMode = GeofenceDrawMode.pan;
  GeofenceDrawMode get drawMode => _drawMode;

  void setDrawMode(GeofenceDrawMode mode) {
    if (_drawMode == mode) return;
    _drawMode = mode;
    _resetAll();
    notifyListeners();
  }

  void initDrawMode(GeofenceDrawMode mode) {
    _drawMode = mode;
    notifyListeners();
  }

  void _resetAll() {
    _circleCenter  = null;
    _circleRadius  = 100;
    _rectStart     = null;
    _rectEnd       = null;
    _polygonPoints = [];
  }

  // CIRCLE
  LatLng? _circleCenter;
  LatLng? get circleCenter => _circleCenter;

  double _circleRadius = 100;
  double get circleRadius => _circleRadius;

  void setCircleCenter(LatLng point) {
    _circleCenter = point;
    notifyListeners();
  }

  void updateRadius(double r) {
    if (r > 0) {
      _circleRadius = r;
      notifyListeners();
    }
  }

  Set<Circle> get previewCircles {
    if (_drawMode != GeofenceDrawMode.circle || _circleCenter == null) return {};
    return {
      Circle(
        circleId: const CircleId('preview_circle'),
        center: _circleCenter!,
        radius: _circleRadius,
        fillColor: AppColorTheme.primary.withAlpha(40),
        strokeColor: AppColorTheme.primary,
        strokeWidth: 2,
      ),
    };
  }

  // RECTANGLE
  LatLng? _rectStart;
  LatLng? _rectEnd;

  LatLng? get rectStart => _rectStart;
  LatLng? get rectEnd   => _rectEnd;

  void onRectTap(LatLng point) {
    if (_rectStart == null) {
      _rectStart = point;
      _rectEnd   = null;
    } else {
      _rectEnd = point;
    }
    notifyListeners();
  }

  void resetRectangle() {
    _rectStart = null;
    _rectEnd   = null;
    notifyListeners();
  }

  Set<Polygon> get previewRectangle {
    if (_drawMode != GeofenceDrawMode.rectangle ||
        _rectStart == null || _rectEnd == null) return {};
    return {
      Polygon(
        polygonId: const PolygonId('preview_rect'),
        points: rectToPoints(_rectStart!, _rectEnd!),
        strokeWidth: 2,
        strokeColor: Colors.blue,
        fillColor: Colors.blue.withAlpha(40),
      ),
    };
  }

  static List<LatLng> rectToPoints(LatLng a, LatLng b) => [
    LatLng(a.latitude, a.longitude),
    LatLng(a.latitude, b.longitude),
    LatLng(b.latitude, b.longitude),
    LatLng(b.latitude, a.longitude),
    LatLng(a.latitude, a.longitude),
  ];

  // POLYGON
  List<LatLng> _polygonPoints = [];
  List<LatLng> get polygonPoints => _polygonPoints;

  void addPolygonPoint(LatLng p) {
    _polygonPoints = [..._polygonPoints, p];
    notifyListeners();
  }

  void removeLastPolygonPoint() {
    if (_polygonPoints.isEmpty) return;
    _polygonPoints = _polygonPoints.sublist(0, _polygonPoints.length - 1);
    notifyListeners();
  }

  void closePolygon() {
    if (_polygonPoints.length < 3) return;
    if (_polygonPoints.first != _polygonPoints.last) {
      _polygonPoints = [..._polygonPoints, _polygonPoints.first];
    }
    notifyListeners();
  }

  bool get isPolygonClosed =>
      _polygonPoints.length >= 4 &&
      _polygonPoints.first == _polygonPoints.last;

  Set<Polygon> get previewPolygon {
    if (_drawMode != GeofenceDrawMode.polygon || _polygonPoints.length < 2) {
      return {};
    }
    return {
      Polygon(
        polygonId: const PolygonId('preview_poly'),
        points: _polygonPoints,
        strokeWidth: 2,
        strokeColor: Colors.orange,
        fillColor: Colors.orange.withAlpha(40),
      ),
    };
  }

  Set<Marker> get polygonMarkers {
    if (_drawMode != GeofenceDrawMode.polygon) return {};
    return _polygonPoints.asMap().entries.map((e) => Marker(
      markerId: MarkerId('poly_${e.key}'),
      position: e.value,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
    )).toSet();
  }

  // Handler tap peta
  void onMapTap(LatLng point) {
    switch (_drawMode) {
      case GeofenceDrawMode.pan:
        break;
      case GeofenceDrawMode.circle:
        setCircleCenter(point);
      case GeofenceDrawMode.rectangle:
        onRectTap(point);
      case GeofenceDrawMode.polygon:
        addPolygonPoint(point);
    }
  }

  // Validasi & hint
  bool get isAreaReady {
    switch (_drawMode) {
      case GeofenceDrawMode.pan: return false;
      case GeofenceDrawMode.circle: return _circleCenter != null;
      case GeofenceDrawMode.rectangle: return _rectStart != null && _rectEnd != null;
      case GeofenceDrawMode.polygon: return isPolygonClosed;
    }
  }

  String get hintText {
    switch (_drawMode) {
      case GeofenceDrawMode.pan:
        return 'Pilih mode gambar di toolbar kiri atas';
      case GeofenceDrawMode.circle:
        return _circleCenter == null
            ? 'Tap peta untuk menentukan pusat lingkaran'
            : 'Pusat dipilih. Atur radius di form bawah';
      case GeofenceDrawMode.rectangle:
        if (_rectStart == null) return 'Tap titik pertama (pojok area)';
        if (_rectEnd   == null) return 'Tap titik kedua (pojok berlawanan)';
        return 'Kotak siap. Tap "Gambar Ulang" untuk reset';
      case GeofenceDrawMode.polygon:
        if (_polygonPoints.isEmpty) return 'Tap peta untuk mulai menggambar polygon';
        if (_polygonPoints.length < 3) return 'Tambah ${3 - _polygonPoints.length} titik lagi';
        if (!isPolygonClosed) return 'Tekan "Tutup Polygon" jika sudah selesai';
        return 'Polygon siap disimpan';
    }
  }
}