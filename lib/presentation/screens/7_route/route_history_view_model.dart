import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nusantara_gps/core/app/app_color_theme.dart';
import 'package:nusantara_gps/core/config/result.dart';
import 'package:nusantara_gps/core/utils/date_time_extention.dart';
import 'package:nusantara_gps/core/utils/error_extention.dart';
import 'package:nusantara_gps/core/utils/geofence_detector.dart';
import 'package:nusantara_gps/data/models/position.dart';
import 'package:nusantara_gps/domain/interfaces/i_vehicle_repository.dart';

class RouteHistoryViewModel extends ChangeNotifier {
  final IVehicleRepository _repo;
  RouteHistoryViewModel(this._repo);

  String? mapStyle;

  Future<void> loadMapStyle() async {
    mapStyle = await rootBundle.loadString('assets/json/map_style.json');
    notifyListeners();
  }

  List<PositionModel> _tripPoints = <PositionModel>[];
  List<PositionModel> get tripPoints => _tripPoints;

  double _totalDistance = 0.0;
  double get totalDistance => _totalDistance;

  // Array kumulatif jarak antar titik
  List<double> _cumulativeDistances = [];

  double get _distanceTraveledMeters {
    if (_cumulativeDistances.isEmpty) return 0.0;
    return _cumulativeDistances[_currentIndex];
  }

  String get distanceTraveledFormatted {
    final meters = _distanceTraveledMeters;
    final km = meters / 1000;
    final meterFormatted = _formatThousands(meters.toInt());
    return "${km.toStringAsFixed(1)} km ($meterFormatted m)";
  }

  String _formatThousands(int value) {
    final str = value.toString();
    final buffer = StringBuffer();
    final offset = str.length % 3;
    for (int i = 0; i < str.length; i++) {
      if (i != 0 && (i - offset) % 3 == 0);
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  double get _segmentMeters {
    if (_currentIndex == 0 || _cumulativeDistances.isEmpty) return 0.0;
    return _cumulativeDistances[_currentIndex] -
        _cumulativeDistances[_currentIndex - 1];
  }

  String get segmentDistanceFormatted {
    if (_currentIndex == 0) return '-';
    final meters = _segmentMeters;
    final km = meters / 1000;
    final meterFormatted = _formatThousands(meters.toInt());
    return "+${km.toStringAsFixed(1)} km ($meterFormatted m)";
  }

  ResultState _loadTripPoints = ResultState.initial;
  ResultState get loadTripPoints => _loadTripPoints;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  DateTime _startDate = DateTime.now().subtract(const Duration(hours: 6));
  DateTime _endDate = DateTime.now();

  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  DateTime get selectedDate => _startDate;

  void setStartDate(DateTime date) {
    _startDate = date;
    notifyListeners();
  }

  void setEndDate(DateTime date) {
    _endDate = date;
    notifyListeners();
  }

  void setSelectedDate(DateTime date) {
    _startDate = DateTime(date.year, date.month, date.day, 0, 0, 0);
    _endDate = DateTime(date.year, date.month, date.day, 23, 59, 59);
    notifyListeners();
  }

  Future<void> loadRouteHistory({
    required int deviceId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final start = startDate ?? _startDate;
    final end = endDate ?? _endDate;

    final startStr = start.toListlinesFormat();
    final endStr = end.toListlinesFormat();

    _loadTripPoints = ResultState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _tripPoints = await _repo.getTripPointReportByDate(
        deviceId,
        startStr,
        endStr,
      );

      if (_tripPoints.isEmpty) {
        _loadTripPoints = ResultState.noData;
        _totalDistance = 0.0;
        _cumulativeDistances = [];
      } else {
        // Build array kumulatif 
        _cumulativeDistances = List<double>.filled(_tripPoints.length, 0.0);
        double runningMeters = 0.0;

        for (int i = 1; i < _tripPoints.length; i++) {
          runningMeters += GeofenceDetector.haversineDistance(
            _tripPoints[i - 1].latitude,
            _tripPoints[i - 1].longitude,
            _tripPoints[i].latitude,
            _tripPoints[i].longitude,
          );
          _cumulativeDistances[i] = runningMeters;
        }

        _totalDistance = runningMeters / 1000;

        _currentIndex = 0;
        _isPlaying = false;
        _stopTimer();

        _currentCourse = _tripPoints.length > 1
            ? _calculateBearing(
                LatLng(_tripPoints[0].latitude, _tripPoints[0].longitude),
                LatLng(_tripPoints[1].latitude, _tripPoints[1].longitude),
              )
            : _tripPoints.first.course;

        _animatedPosition = LatLng(
          _tripPoints.first.latitude,
          _tripPoints.first.longitude,
        );
        _loadTripPoints = ResultState.success;
      }
    } on DioException catch (e) {
      _errorMessage = mapDioErrorToMessage(e);
      _loadTripPoints = ResultState.error;
    } catch (e) {
      _errorMessage = e.toString();
      _loadTripPoints = ResultState.error;
    } finally {
      notifyListeners();
    }
  }

  // Playback
  Duration get _stepDuration {
    if (_tripPoints.isEmpty || _currentIndex >= _tripPoints.length - 1) {
      return const Duration(milliseconds: 500);
    }
    final from = _tripPoints[_currentIndex];
    final to = _tripPoints[_currentIndex];
    final timeDiff = to.fixTime.difference(from.fixTime).inSeconds;
    final ms = (timeDiff * 100).clamp(3000, 4000);
    return Duration(milliseconds: ms);
  }

  Duration get stepDuration => _stepDuration;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  Timer? _timer;

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;
  double get sliderValue => _currentIndex.toDouble();

  double _currentCourse = 0;
  double get currentCourse => _currentCourse;

  double get maxSliderValue =>
      _tripPoints.isEmpty ? 0 : (_tripPoints.length - 1).toDouble();

  PositionModel? get currentPoint =>
      _tripPoints.isEmpty ? null : _tripPoints[_currentIndex];

  LatLng? _animatedPosition;
  LatLng? get animatedPosition => _animatedPosition;

  bool get hasData => _tripPoints.isNotEmpty;

  Set<Polyline> get polylines {
    if (_tripPoints.length < 2) return {};
    final polyPoints =
        _tripPoints.map((e) => LatLng(e.latitude, e.longitude)).toList();
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: polyPoints,
        width: 4,
        color: AppColorTheme.green600,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    };
  }

  Set<Circle> get circles {
    return {
      Circle(
        circleId: const CircleId("start"),
        center: LatLng(_tripPoints.first.latitude, _tripPoints.first.longitude),
        radius: 2,
        fillColor: Colors.green,
        strokeColor: Colors.white,
        strokeWidth: 2,
      ),
      Circle(
        circleId: const CircleId("end"),
        center: LatLng(_tripPoints.last.latitude, _tripPoints.last.longitude),
        radius: 2,
        fillColor: Colors.red,
        strokeColor: Colors.white,
        strokeWidth: 2,
      ),
    };
  }

  void onSliderChanged(double value) {
    if (_tripPoints.isEmpty) return;
    _isPlaying = false;
    _stopTimer();
    _currentIndex = value.clamp(0, maxSliderValue).round();
    final p = _tripPoints[_currentIndex];
    _animatedPosition = LatLng(p.latitude, p.longitude);

    if (_currentIndex < _tripPoints.length - 1) {
      final next = _tripPoints[_currentIndex + 1];
      _currentCourse = _calculateBearing(
        LatLng(p.latitude, p.longitude),
        LatLng(next.latitude, next.longitude),
      );
    }
    notifyListeners(); 
  }

  void play() {
    if (_tripPoints.isEmpty) return;
    if (_isPlaying) return;
    _isPlaying = true;
    _scheduleNextStep();
    notifyListeners();
  }

  void _scheduleNextStep() {
    _timer?.cancel();
    _timer = Timer(_stepDuration, () {
      _nextStep();
      if (_isPlaying) _scheduleNextStep();
    });
  }

  void pause() {
    _isPlaying = false;
    _stopTimer();
    notifyListeners();
  }

  void _nextStep() {
    if (!_isPlaying || _tripPoints.isEmpty) return;

    if (_currentIndex < _tripPoints.length - 1) {
      final from = _tripPoints[_currentIndex];
      final to = _tripPoints[_currentIndex + 1];

      final fromLatLng = LatLng(from.latitude, from.longitude);
      final toLatLng = LatLng(to.latitude, to.longitude);

      _currentCourse = _calculateBearing(fromLatLng, toLatLng);
      _animateMarker(fromLatLng, toLatLng);
      recenterVehicleLocation();
      _currentIndex++;
      notifyListeners();
    } else {
      _isPlaying = false;
      _stopTimer();
      notifyListeners();
    }
  }

  void _animateMarker(LatLng from, LatLng to) {
    final dist = GeofenceDetector.haversineDistance(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
    final int steps = dist.clamp(10, 120).toInt();
    const Duration frame = Duration(milliseconds: 16);

    int currentStep = 0;
    Timer.periodic(frame, (timer) {
      if (currentStep >= steps) {
        _animatedPosition = to;
        notifyListeners();
        timer.cancel();
        return;
      }
      final t = currentStep / steps;
      _animatedPosition = LatLng(
        from.latitude + (to.latitude - from.latitude) * t,
        from.longitude + (to.longitude - from.longitude) * t,
      );
      currentStep++;
      notifyListeners();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  double _calculateBearing(LatLng from, LatLng to) {
    final lat1 = from.latitude * math.pi / 180;
    final lat2 = to.latitude * math.pi / 180;
    final dLng = (to.longitude - from.longitude) * math.pi / 180;

    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);

    final bearing = math.atan2(y, x) * 180 / math.pi;
    return (bearing + 360) % 360;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  final Map<String, BitmapDescriptor> _markerIconCache = {};

  BitmapDescriptor getMarkerIcon() {
    const assetPath = "assets/icons/car_on.png";
    final cached = _markerIconCache[assetPath];
    if (cached != null) return cached;

    BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(72, 72)),
      assetPath,
    ).then((descriptor) {
      _markerIconCache[assetPath] = descriptor;
      notifyListeners();
    });
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
  }

  GoogleMapController? _controller;

  void setMapController(GoogleMapController controller) {
    _controller = controller;
    notifyListeners();
  }

  void recenterVehicleLocation() {
    _controller?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(
            _tripPoints[_currentIndex].latitude,
            _tripPoints[_currentIndex].longitude,
          ),
          zoom: 15,
        ),
      ),
    );
    notifyListeners();
  }
}