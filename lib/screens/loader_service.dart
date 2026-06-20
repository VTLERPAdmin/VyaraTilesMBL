import 'package:flutter/material.dart';
import 'package:vyara_erp/widgets/loader.dart';

class LoaderService {
  static OverlayEntry? _overlay;

  // Each show() call gets a unique token. hide() only clears the overlay
  // if it's still the one that matches the token it was shown with — this
  // stops a late-arriving hide() from one screen accidentally removing a
  // newer loader that a different screen has since shown.
  static int _token = 0;

  static void show(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) {
    hide(); // remove old if exists

    final overlayState = Overlay.of(context, rootOverlay: true);

    final myToken = ++_token;

    final entry = OverlayEntry(
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

    _overlay = entry;

    try {
      overlayState.insert(entry);
    } catch (e) {
      debugPrint("Loader show error: $e");
      // Insert failed (e.g. overlay state no longer valid) — don't leave
      // a dangling reference that a later hide() would try to remove.
      if (_overlay == entry) {
        _overlay = null;
      }
      return;
    }

    // If show() raced with another show()/hide() while we were inserting,
    // _token may have moved on; that's fine, _token always reflects the
    // most recent caller.
    _activeToken = myToken;
  }

  static int? _activeToken;

  static void hide() {
    if (_overlay == null) return;

    try {
      _overlay?.remove();
    } catch (e) {
      debugPrint("Loader hide error: $e");
    } finally {
      _overlay = null;
      _activeToken = null;
    }
  }

  /// Like hide(), but only removes the overlay if the caller's screen is
  /// still the most recent one to have called show(). Pass the token
  /// returned by showTracked() to use this safely across async gaps.
  static void hideIfCurrent(int token) {
    if (_activeToken == token) {
      hide();
    }
  }

  /// Same as show(), but returns a token you can hand to hideIfCurrent()
  /// in a finally block, so a late hide() from a stale screen can't
  /// remove a newer loader shown by a different screen in the meantime.
  static int showTracked(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) {
    show(context, title: title, subtitle: subtitle);
    return _activeToken ?? _token;
  }
}