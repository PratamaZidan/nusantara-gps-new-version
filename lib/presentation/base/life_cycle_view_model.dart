import 'package:flutter/cupertino.dart';

abstract class LifeCycleViewModel extends ChangeNotifier {
  bool _initialized = false;
  bool _loading = false;
  Object? _error;

  bool get isInitialized => _initialized;
  bool get isLoading => _loading;
  Object? get error => _error;

  // called just once
  Future<void> onInit();

  /// called while explicit refresh
  Future<void> onRefresh();

  /// safe init (idempotent)
  Future<void> ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    await _run(onInit);
  }

  /// refresh explicitly
  Future<void> refresh() async {
    await _run(onRefresh);
  }

  Future<void> _run(Future<void> Function() action) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await action();
    } catch (e) {
      _error = e;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
