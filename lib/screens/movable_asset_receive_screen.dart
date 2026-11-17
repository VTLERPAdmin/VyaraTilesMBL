// ===============================
// FILE: screens/movable_asset_receive_screen.dart
// ===============================
//
// Every pending asset / item row is its own card with a Receive
// button. Tap Receive -> saved on the server -> a message box shows
// "<name> received" (closes by itself after a moment, or tap OK) ->
// the card fades out and disappears.
//
// Layout: 1 column on phones, 2 on tablets, 3 on wide screens. Cards
// grow with their content (no fixed heights), so long names wrap
// instead of overflowing.

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/movable_asset_receive_model.dart';
import '../services/api_services.dart';
import '../services/session_manager.dart';
import '../screens/loader_service.dart';

class MovableAssetReceiveScreen extends StatefulWidget {
  const MovableAssetReceiveScreen({super.key});

  @override
  State<MovableAssetReceiveScreen> createState() =>
      _MovableAssetReceiveScreenState();
}

class _MovableAssetReceiveScreenState extends State<MovableAssetReceiveScreen> {
  static const primaryBlue = Color(0xFF06275B);
  static const backgroundColor = Color(0xFFF5F7FA);
  static const borderColor = Color(0xFFD9DEE7);
  static const textColor = Color(0xFF172033);
  static const mutedColor = Color(0xFF667085);
  static const receiveGreen = Color(0xFF059669);

  bool loading = true;
  String? errorMessage;

  List<MaReceiveRow> rows = [];

  // Rows currently being saved (button shows a spinner) and rows that
  // were received and are fading out.
  final Set<String> _busy = {};
  final Set<String> _fading = {};

  final TextEditingController _searchController = TextEditingController();
  String _query = "";

  String userId = "";
  String userpwd = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => loadSession());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ================= SESSION =================
  Future<void> loadSession() async {
    final session = await SessionManager.getSession();

    if (!mounted) return;

    if (session == null || session["userId"] == null) {
      setState(() {
        loading = false;
        errorMessage = "Session expired. Please login again.";
      });
      return;
    }

    userId = session["userId"];
    userpwd = session["password"];

    await loadData();
  }

  // ================= LOAD =================
  Future<void> loadData({bool showLoader = true}) async {
    if (!mounted) return;

    setState(() {
      loading = rows.isEmpty;
      errorMessage = null;
    });

    if (showLoader) {
      LoaderService.show(
        context,
        title: "Loading Assets",
        subtitle: "Fetching assets to receive...",
      );
    }

    try {
      final data = await ApiService.getMovableAssetReceiveList(
        userId: userId,
        userPwd: userpwd,
      );

      // Keep vouchers together: location, voucher, line, sub-line.
      data.sort((a, b) {
        int c = a.locId.compareTo(b.locId);
        if (c != 0) return c;
        c = a.id.compareTo(b.id);
        if (c != 0) return c;
        c = a.srNo.compareTo(b.srNo);
        if (c != 0) return c;
        return a.subSrNo.compareTo(b.subSrNo);
      });

      if (!mounted) return;

      setState(() {
        rows = data;
        _busy.clear();
        _fading.clear();
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      final msg = e.toString().replaceFirst("Exception: ", "");

      setState(() {
        loading = false;
        if (rows.isEmpty) errorMessage = msg;
      });

      // List already on screen (pull-to-refresh failed): keep it and
      // just tell the user.
      if (rows.isNotEmpty) await _showMessage(msg);
    } finally {
      if (showLoader) LoaderService.hide();
    }
  }

  // ================= RECEIVE =================
  Future<void> _receive(MaReceiveRow row) async {
    if (_busy.contains(row.key) || _fading.contains(row.key)) return;

    setState(() => _busy.add(row.key));

    String? error;

    try {
      await ApiService.receiveMovableAsset(
        userId: userId,
        userPwd: userpwd,
        row: row,
      );
    } catch (e) {
      error = e.toString().replaceFirst("Exception: ", "");
    }

    if (!mounted) return;

    setState(() => _busy.remove(row.key));

    if (error != null) {
      await _showMessage(error);
      return;
    }

    // Start fading the card while the message box is up.
    setState(() => _fading.add(row.key));

    await _showReceived(row.name.isEmpty ? row.description : row.name);

    if (!mounted) return;

    setState(() {
      rows.removeWhere((r) => r.key == row.key);
      _fading.remove(row.key);
    });
  }

  // ================= MESSAGE BOXES =================
  Future<void> _showMessage(String message, {String title = "Message"}) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // "<name> received" — closes by itself after 1.5 s, or on OK, so
  // the user can go Receive, Receive, Receive quickly.
  Future<void> _showReceived(String name) async {
    if (!mounted) return;

    Timer? timer;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        timer ??= Timer(const Duration(milliseconds: 1500), () {
          if (dialogContext.mounted && Navigator.of(dialogContext).canPop()) {
            Navigator.of(dialogContext).pop();
          }
        });

        return AlertDialog(
          icon: const Icon(Icons.check_circle, color: receiveGreen, size: 44),
          title: const Text("Received"),
          content: Text(
            "$name\n\nhas been received.",
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );

    timer?.cancel();
  }

  // ================= FILTER =================
  List<MaReceiveRow> get _visibleRows {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return rows;

    return rows.where((r) {
      return r.description.toLowerCase().contains(q) ||
          r.client.toLowerCase().contains(q) ||
          r.site.toLowerCase().contains(q) ||
          r.agency.toLowerCase().contains(q) ||
          r.location.toLowerCase().contains(q);
    }).toList();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Movable Asset Receive",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          if (!loading && errorMessage == null)
            IconButton(
              tooltip: "Refresh",
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () => loadData(),
            ),
        ],
      ),
      body: SafeArea(child: _body()),
    );
  }

  Widget _body() {
    if (loading) return const SizedBox.shrink(); // loader overlay shows

    if (errorMessage != null) return _errorState();

    final visible = _visibleRows;

    return Column(
      children: [
        _searchBar(visible.length),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => loadData(showLoader: false),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final columns = width >= 1200 ? 3 : (width >= 700 ? 2 : 1);
                const gap = 12.0;
                const side = 16.0;
                final usable = (width - side * 2).clamp(0.0, double.infinity);
                final cardWidth = (usable - gap * (columns - 1)) / columns;

                if (visible.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: constraints.maxHeight * 0.2),
                      _emptyState(),
                    ],
                  );
                }

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(side, 4, side, 24),
                  child: Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final r in visible)
                        SizedBox(
                          key: ValueKey(r.key),
                          width: cardWidth,
                          child: _rowCard(r),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _searchBar(int shown) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: "Search asset, client, site, agency",
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = "");
                          },
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Pending: $shown of ${rows.length}",
                style: const TextStyle(color: mutedColor, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rowCard(MaReceiveRow r) {
    final busy = _busy.contains(r.key);
    final fading = _fading.contains(r.key);

    // "Issued to" lines — only the ones the server filled in.
    final parties = <MapEntry<IconData, String>>[
      if (r.client.isNotEmpty) MapEntry(Icons.business_outlined, r.client),
      if (r.site.isNotEmpty) MapEntry(Icons.location_on_outlined, r.site),
      if (r.agency.isNotEmpty) MapEntry(Icons.engineering_outlined, r.agency),
      if (r.location.isNotEmpty) MapEntry(Icons.warehouse_outlined, r.location),
    ];

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: fading ? 0.0 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- Type badge + qty ----
            Row(
              children: [
                _badge(
                  r.isItem ? "Item" : "Asset",
                  r.isItem ? const Color(0xFF7C3AED) : primaryBlue,
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    "${_fmtQty(r.qty)} ${r.uomCode}".trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ---- Name + code ----
            Text(
              r.name.isEmpty ? "-" : r.name,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: primaryBlue,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            if (r.code.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                r.code,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: mutedColor, fontSize: 12),
              ),
            ],

            // ---- Issued to ----
            if (parties.isNotEmpty) ...[
              const Divider(height: 20),
              for (final p in parties)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(p.key, size: 15, color: mutedColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          p.value,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              const TextStyle(color: textColor, fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                ),
            ],

            const SizedBox(height: 12),

            // ---- Receive ----
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: receiveGreen,
                  disabledBackgroundColor: receiveGreen.withOpacity(0.6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: (busy || fading) ? null : () => _receive(r),
                icon: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        fading ? Icons.check_circle : Icons.move_to_inbox,
                        color: Colors.white,
                        size: 20,
                      ),
                label: Text(
                  busy ? "Receiving..." : (fading ? "Received" : "Receive"),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _emptyState() {
    final searching = _query.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Icon(
            searching ? Icons.search_off : Icons.inventory_2_outlined,
            size: 52,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            searching ? "No matching assets" : "Nothing to receive",
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            searching
                ? "Try a different search."
                : "All issued assets have been received.\nPull down to refresh.",
            textAlign: TextAlign.center,
            style: const TextStyle(color: mutedColor),
          ),
        ],
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 42),
            const SizedBox(height: 12),
            Text(
              errorMessage ?? "Something went wrong.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: textColor),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
              onPressed: () => loadData(),
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                "Retry",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtQty(double q) =>
      q == q.roundToDouble() ? q.toInt().toString() : q.toStringAsFixed(2);
}