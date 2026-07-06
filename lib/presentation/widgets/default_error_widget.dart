import 'package:flutter/material.dart';
import 'package:nusantara_gps/core/app/app_text_theme.dart';
import 'package:nusantara_gps/presentation/widgets/animation/slide_fade_in.dart';

class DefaultErrorWidget extends StatelessWidget {
  final String? errorMessage;
  final String asset;
  final String onRetryButtonLabel;
  final VoidCallback? onRetry;
  const DefaultErrorWidget({
    super.key,
    this.errorMessage,
    this.asset = 'assets/images/error_mascot.png',
    this.onRetry,
    this.onRetryButtonLabel = 'Coba Lagi',
  });

  @override
  Widget build(BuildContext context) {
    final imageSize = MediaQuery.of(context).size.width * 0.25;
    final msg = errorMessage ?? 'Terjadi kesalahan. Silakan coba lagi.';
    return Center(
      child: SlideFadeIn(
        delay: 0.2,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(asset, width: imageSize, height: imageSize),
            SizedBox(
              width: 200,
              child: Text(
                msg,
                style: AppTextTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            if (onRetry != null)
              ElevatedButton(
                onPressed: onRetry,
                child: Text(onRetryButtonLabel),
              ),
          ],
        ),
      ),
    );
  }
}
