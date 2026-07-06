class PoiModel {
  final int id;
  final int userId;
  final String nama;
  final String keterangan;
  final String icon;
  final String photo;
  final double lat;
  final double lng;
  final String? localImagePath;

  const PoiModel({
    required this.id,
    required this.userId,
    required this.nama,
    required this.keterangan,
    required this.icon,
    required this.photo,
    required this.lat,
    required this.lng,
    this.localImagePath,
  });

  factory PoiModel.fromJson(Map<String, dynamic> json) {
    return PoiModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: int.tryParse(json['userid']?.toString() ?? '0') ?? 0,
      nama: json['nama']?.toString() ?? '',
      keterangan: json['keterangan']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '',
      photo: json['photo']?.toString() ?? '',
      lat: _parseDouble(json['lat']),
      lng: _parseDouble(json['lng']),
      localImagePath: json['localImagePath']?.toString(),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  String get fullIconUrl =>
      'https://lacak.nusantaragps.com/assets/icon/$icon';

  String get fullPhotoUrl =>
      'https://lacak.nusantaragps.com/assets/icon/$photo';

  PoiModel copyWith({
    int? id,
    int? userId,
    String? nama,
    String? keterangan,
    String? icon,
    String? photo,
    double? lat,
    double? lng,
    String? localImagePath,
  }) {
    return PoiModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      nama: nama ?? this.nama,
      keterangan: keterangan ?? this.keterangan,
      icon: icon ?? this.icon,
      photo: photo ?? this.photo,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      localImagePath: localImagePath ?? this.localImagePath,
    );
  }

  @override
  String toString() =>
      'PoiModel(id: $id, name: $nama, lat: $lat, lng: $lng)';
}