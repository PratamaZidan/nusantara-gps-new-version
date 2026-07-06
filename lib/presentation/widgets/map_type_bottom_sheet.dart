import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nusantara_gps/core/app/app_color_theme.dart';
import 'package:nusantara_gps/domain/entities/map_type.dart';
import 'package:nusantara_gps/presentation/widgets/default_padding.dart';

void showMapTypeBottomSheet({
  required BuildContext context,
  required MapType currentMapType,
  required Function(MapType) onMapTypeSelected,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DefaultPadding(
              paddingHorizontal: 16,
              child: Row(
                children: [
                  Spacer(),
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: Icon(Icons.close, color: AppColorTheme.gray400),
                  ),
                ],
              ),
            ),
            Text(
              "Pilih Tipe Peta",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (var mapType in GoogleMapType.values)
              ListTile(
                selected: currentMapType == mapType.mapTypeInGoogle,
                selectedTileColor: AppColorTheme.primary.withAlpha(10),
                selectedColor: AppColorTheme.primary,
                title: Text(mapType.name),
                leading: Image.asset(mapType.iconAsset, width: 32),
                onTap: () {
                  onMapTypeSelected(mapType.mapTypeInGoogle);
                  context.pop();
                },
              ),
          ],
        ),
      );
    },
  );
}
