import 'package:nusantara_gps/data/datasourse/i_vehicle_remote_data_source.dart';
import 'package:nusantara_gps/domain/interfaces/i_maps_repository.dart';

class MapsRepositoryImpl implements IMapsRepository {
  final IVehicleRemoteDataSource _remote;
  MapsRepositoryImpl(this._remote);

  @override
  Future<Map<String, double>> getInitialLocation() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return {"lat": -7.905297848202646, "lng": 112.66349950458638};
  }
}
