import 'package:flutter/material.dart';
import 'package:vyara_erp/widgets/loader.dart';

class LoaderService {
  static OverlayEntry? _overlay;

  static void show(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) {
    hide(); // remove old if exists

    final overlayState = Overlay.of(context, rootOverlay: true);

    _overlay = OverlayEntry(
      builder: (context) => Material(
        color: Colors.black54,
        child: Center(
          child: VyaraLoaderScreen(
            title: title,
            subtitle: subtitle,
          ),
        ),
      ),
    );

    overlayState.insert(_overlay!);
  }

  static void hide() {
    try {
      _overlay?.remove();
      _overlay = null;
    } catch (e) {
      debugPrint("Loader hide error: $e");
      _overlay = null;
    }
  }
}