import 'package:flutter/material.dart';
import 'package:nusantara_gps/core/app/app_color_theme.dart';

enum VehicleStatus { on, off, standby, down }

extension VehicleStatusX on VehicleStatus {
  Color get color {
    switch (this) {
      case VehicleStatus.on:
        return AppColorTheme.green500;
      case VehicleStatus.off:
        return AppColorTheme.red600;
      case VehicleStatus.standby:
        return AppColorTheme.yellow500;
      case VehicleStatus.down:
        return AppColorTheme.gray600;
    }
  }

  Color get secondaryColor {
    switch (this) {
      case VehicleStatus.standby:
        return AppColorTheme.yellow100;
      case VehicleStatus.on:
        return AppColorTheme.green100;
      case VehicleStatus.off:
        return AppColorTheme.red100;
      case VehicleStatus.down:
        return AppColorTheme.gray100;
    }
  }

  String get iconAsset {
    switch (this) {
      case VehicleStatus.standby:
        return 'assets/icons/car_standby.png';
      case VehicleStatus.on:
        return 'assets/icons/car_on.png';
      case VehicleStatus.off:
        return 'assets/icons/car_off.png';
      case VehicleStatus.down:
        return 'assets/icons/car_down.png';
    }
  }

  String get label => toString().toUpperCase().split('.').last;
}
