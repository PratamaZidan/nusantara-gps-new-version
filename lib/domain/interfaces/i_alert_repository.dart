import 'package:nusantara_gps/data/models/alert_model.dart';

// Interface repository untuk data alert kendaraan.
abstract class IAlertRepository {
  // Ambil list alert dari api dimulai dari halaman 1
  Future<List<AlertModel>> getAlerts({int page = 1});
}