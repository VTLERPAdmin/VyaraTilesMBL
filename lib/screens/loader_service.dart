import 'package:flutter/material.dart';
import 'package:vyara_erp/widgets/loader.dart';

class LoaderService {
  static OverlayEntry? _overlayEntry;
  static int _token = 0;
  static int? _activeToken;

  // ==========================================================
  // SHOW LOADER
  // ==========================================================

  static void show(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) {
    // Do not use a deactivated context.
    if (!context.mounted) {
      return;
    }

    // Remove any existing loader first.
    hide();

    if (!context.mounted) {
      return;
    }

    final overlayState = Overlay.maybeOf(
      context,
      rootOverlay: true,
    );

    if (overlayState == null || !overlayState.mounted) {
      debugPrint('Loader show skipped: Overlay is not available.');
      return;
    }

    final myToken = ++_token;

    final entry = OverlayEntry(
      builder: (BuildContext overlayContext) {
        return Material(
          color: Colors.black54,
          child: Center(
            child: VyaraLoaderScreen(
              title: title,
              subtitle: subtitle,
            ),
          ),
        );
      },
    );

    _overlayEntry = entry;
    _activeToken = myToken;

    try {
      overlayState.insert(entry);
    } catch (e) {
      debugPrint('Loader show error: $e');

      if (_overlayEntry == entry) {
        _overlayEntry = null;
        _activeToken = null;
      }
    }
  }

  // ==========================================================
  // SHOW WITH TOKEN
  // ==========================================================

  static int showTracked(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) {
    show(
      context,
      title: title,
      subtitle: subtitle,
    );

    return _activeToken ?? _token;
  }

  // ==========================================================
  // HIDE LOADER
  // ==========================================================

  static void hide() {
    final entry = _overlayEntry;

    // Clear references FIRST.
    //
    // This is important because remove() can cause widget rebuilds and
    // disposal work. We don't want another callback to try removing the
    // same OverlayEntry again.
    _overlayEntry = null;
    _activeToken = null;

    if (entry == null) {
      return;
    }

    // Only remove if the entry is actually mounted.
    if (!entry.mounted) {
      return;
    }

    try {
      entry.remove();
    } catch (e) {
      debugPrint('Loader hide error: $e');
    }
  }

  // ==========================================================
  // HIDE ONLY IF THIS IS THE CURRENT LOADER
  // ==========================================================

  static void hideIfCurrent(int token) {
    if (_activeToken != token) {
      return;
    }

    hide();
  }

  // ==========================================================
  // CHECK IF LOADER IS VISIBLE
  // ==========================================================

  static bool get isShowing {
    return _overlayEntry?.mounted ?? false;
  }
}