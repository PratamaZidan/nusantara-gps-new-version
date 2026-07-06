import 'dart:ui';

enum DataInvalidationEvent { favoriteLocationChanged, geofenceChanged }

class DataInvalidationBus {
  final _listeners = <DataInvalidationEvent, List<VoidCallback>>{};

  void subscribe(DataInvalidationEvent event, VoidCallback listener) {
    _listeners.putIfAbsent(event, () => []).add(listener);
  }

  void emit(DataInvalidationEvent event) {
    for (final listener in _listeners[event] ?? []) {
      listener();
    }
  }

  void unsubscribe(DataInvalidationEvent event, VoidCallback listener) {
    _listeners[event]?.remove(listener);
  }
}
