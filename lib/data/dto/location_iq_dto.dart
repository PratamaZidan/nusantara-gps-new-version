class LocationIqDTO {
  String? placeId;
  String? licence;
  String? osmType;
  String? osmId;
  String? lat;
  String? lon;
  String? displayName;
  Address? address;
  List<String>? boundingbox;

  LocationIqDTO({
    this.placeId,
    this.licence,
    this.osmType,
    this.osmId,
    this.lat,
    this.lon,
    this.displayName,
    this.address,
    this.boundingbox,
  });

  LocationIqDTO.fromJson(Map<String, dynamic> json) {
    placeId = json['place_id'];
    licence = json['licence'];
    osmType = json['osm_type'];
    osmId = json['osm_id'];
    lat = json['lat'];
    lon = json['lon'];
    displayName = json['display_name'];
    address = json['address'] != null
        ? Address.fromJson(json['address'])
        : null;
    boundingbox = json['boundingbox'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['place_id'] = placeId;
    data['licence'] = licence;
    data['osm_type'] = osmType;
    data['osm_id'] = osmId;
    data['lat'] = lat;
    data['lon'] = lon;
    data['display_name'] = displayName;
    if (address != null) {
      data['address'] = address!.toJson();
    }
    data['boundingbox'] = boundingbox;
    return data;
  }
}

class Address {
  String? village;
  String? municipality;
  String? county;
  String? state;
  String? region;
  String? country;
  String? countryCode;

  Address({
    this.village,
    this.municipality,
    this.county,
    this.state,
    this.region,
    this.country,
    this.countryCode,
  });

  Address.fromJson(Map<String, dynamic> json) {
    village = json['village'];
    municipality = json['municipality'];
    county = json['county'];
    state = json['state'];
    region = json['region'];
    country = json['country'];
    countryCode = json['country_code'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['village'] = village;
    data['municipality'] = municipality;
    data['county'] = county;
    data['state'] = state;
    data['region'] = region;
    data['country'] = country;
    data['country_code'] = countryCode;
    return data;
  }
}
