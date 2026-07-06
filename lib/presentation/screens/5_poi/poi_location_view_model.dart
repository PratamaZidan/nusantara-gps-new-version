import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nusantara_gps/core/config/result.dart';
import 'package:nusantara_gps/core/service/poi_icon_cache.dart';
import 'package:nusantara_gps/core/utils/error_extention.dart';
import 'package:nusantara_gps/data/models/poi_model.dart';
import 'package:nusantara_gps/domain/event/data_invalidation_bus.dart';
import 'package:nusantara_gps/domain/interfaces/i_poi_repository.dart';
import 'package:nusantara_gps/presentation/base/life_cycle_view_model.dart';

class FavoriteLocationViewModel extends LifeCycleViewModel {
  final IPoiRepository _poiRepo;
  final DataInvalidationBus _bus;

  FavoriteLocationViewModel(this._poiRepo, this._bus) {
    _bus.subscribe(
      DataInvalidationEvent.favoriteLocationChanged,
      _onExternalChanged,
    );
  }

  // State List
  List<PoiModel> _items = [];
  List<PoiModel> get items => _items;

  ResultState _loadState = ResultState.initial;
  ResultState get loadFavoriteLocationState => _loadState;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  ResultState _deleteState = ResultState.initial;
  ResultState get deleteState => _deleteState;

  LatLng? _selectedLatLng;
  LatLng? get selectedLatLng => _selectedLatLng;

  MapType _mapType = MapType.normal;
  MapType get mapType => _mapType;
  
  Map<String, BitmapDescriptor> get iconDescriptors =>
      Map.unmodifiable(_iconDescriptors);
  final Map<String, BitmapDescriptor> _iconDescriptors = {};

  void _onExternalChanged() {
    _selectedLatLng = null;
    refresh();
  }

  // Actions
  Future<void> loadFavoriteLocation() async {
    _loadState = ResultState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _items = await _poiRepo.getPois();
      _loadState = ResultState.success;
      notifyListeners(); // tampilkan list dulu dengan marker default

      // Preload icon di background — update markers setelah selesai
      await _preloadIcons();
    } on DioException catch (e) {
      _errorMessage = mapDioErrorToMessage(e);
      _loadState = ResultState.error;
    } catch (e) {
      _errorMessage = e.toString();
      _loadState = ResultState.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> _preloadIcons() async {
    final uniqueIcons = _items
        .map((p) => p.icon)
        .where((i) => i.isNotEmpty)
        .toSet();

    if (uniqueIcons.isEmpty) return;

    // Download semua icon secara paralel
    await PoiIconCache.instance.preload(uniqueIcons, width: PoiIconCache.markerWidthDp);

    // Isi map descriptor dari cache
    for (final iconPath in uniqueIcons) {
      final desc = PoiIconCache.instance.getCached(iconPath, width: PoiIconCache.markerWidthDp);
      if (desc != null) _iconDescriptors[iconPath] = desc;
    }

    notifyListeners(); // rebuild markers dengan icon asli
  }

  Future<void> deletePoi(int id) async {
    _deleteState = ResultState.loading;
    notifyListeners();
    try {
      await _poiRepo.deletePoi(id: id);
      _deleteState = ResultState.success;
      _bus.emit(DataInvalidationEvent.favoriteLocationChanged);
    } on DioException catch (e) {
      _errorMessage = mapDioErrorToMessage(e);
      _deleteState = ResultState.error;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _deleteState = ResultState.error;
    } finally {
      notifyListeners();
    }
  }

  void setSelectedLatLng(LatLng value) {
    _selectedLatLng = value;
    notifyListeners();
  }

  void clearSelectedLatLng() {
    _selectedLatLng = null;
    notifyListeners();
  }

  void changeMapType(MapType type) {
    _mapType = type;
    notifyListeners();
  }

  // LifeCycle
  @override
  Future<void> onInit() async {
    await loadFavoriteLocation();
  }

  @override
  Future<void> onRefresh() async {
    await loadFavoriteLocation();
  }

  @override
  void dispose() {
    _bus.unsubscribe(
      DataInvalidationEvent.favoriteLocationChanged,
      _onExternalChanged,
    );
    super.dispose();
  }
}