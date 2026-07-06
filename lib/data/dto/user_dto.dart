import 'package:nusantara_gps/data/models/user_model.dart';

class UserDTO {
  Data? data;

  UserDTO({this.data});

  String? get username => data?.username;
  String? get email => data?.email;
  String? get telephone => data?.telephone;
  String? get rememberToken => data?.rememberToken;
  String? get traccarToken => data?.traccarToken;

  UserDTO.fromJson(Map<String, dynamic> json) {
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  String? id;
  int? traccarId;
  String? username;
  String? email;
  String? address;
  String? telephone;
  String? status;
  String? emailVerifiedAt;
  String? rememberToken;
  String? lastChangePass;
  int? isAdmin;
  String? traccarToken;
  String? createdAt;
  String? updatedAt;
  String? deletedAt;

  Data({
    this.id,
    this.traccarId,
    this.username,
    this.email,
    this.address,
    this.telephone,
    this.status,
    this.emailVerifiedAt,
    this.rememberToken,
    this.lastChangePass,
    this.isAdmin,
    this.traccarToken,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    traccarId = json['traccar_id'];
    username = json['username'];
    email = json['email'];
    address = json['address'];
    telephone = json['telephone'];
    status = json['status'];
    emailVerifiedAt = json['email_verified_at'];
    rememberToken = json['remember_token'];
    lastChangePass = json['last_change_pass'];
    isAdmin = json['is_admin'];
    traccarToken = json['traccar_token'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    deletedAt = json['deleted_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['traccar_id'] = traccarId;
    data['username'] = username;
    data['email'] = email;
    data['address'] = address;
    data['telephone'] = telephone;
    data['status'] = status;
    data['email_verified_at'] = emailVerifiedAt;
    data['remember_token'] = rememberToken;
    data['last_change_pass'] = lastChangePass;
    data['is_admin'] = isAdmin;
    data['traccar_token'] = traccarToken;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['deleted_at'] = deletedAt;
    return data;
  }
}

extension UserDTOMapper on UserDTO {
  User toEntity() {
    final d = data;
    if (d == null) {
      throw const FormatException('Missing data');
    }
    return User(
      id: (d.id ?? 0).toString(),
      name: d.username ?? '-',
      phoneNumber: d.telephone ?? '-',
      token: d.rememberToken ?? '',
      traccarToken: d.traccarToken ?? '',
    );
  }
}
