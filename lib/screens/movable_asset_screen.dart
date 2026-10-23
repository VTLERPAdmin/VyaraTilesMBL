// ===============================
// FILE: screens/movable_asset_screen.dart
// ===============================

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/movable_asset_model.dart';
import '../services/api_services.dart';
import '../services/session_manager.dart';
import '../screens/loader_service.dart';

class _PickedPhoto {
  final Uint8List bytes;
  final String ext;
  _PickedPhoto(this.bytes, this.ext);
}

class MovableAssetScreen extends StatefulWidget {
  const MovableAssetScreen({super.key});

  @override
  State<MovableAssetScreen> createState() => _MovableAssetScreenState();
}

class _MovableAssetScreenState extends State<MovableAssetScreen>
    with SingleTickerProviderStateMixin {
  static const primaryBlue = Color(0xFF06275B);
  static const backgroundColor = Color(0xFFF5F7FA);
  static const borderColor = Color(0xFFD9DEE7);
  static const mutedColor = Color(0xFF667085);
  static const textColor = Color(0xFF172033);
  static const readOnlyFill = Color(0xFFF2F4F7);

  late final TabController _tabController;
  int _currentTab = 0;

  bool loading = true;
  String? errorMessage;
  MovableAssetLookups? lookups;

  // ---- Information tab ----
  DateTime vouDate = DateTime.now();
  MaLookupItem? selectedLocation;
  MaLookupItem? selectedClient;
  MaLookupItem? selectedSite;
  MaLookupItem? selectedAgency;
  MaLookupItem? selectedEmp;

  // ---- Assets tab ----
  final List<MaAssetLine> addedLines = [];
  String notes = "";

  final ImagePicker _picker = ImagePicker();

  bool isSaving = false;

  String userId = "";
  String userpwd = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging &&
          _currentTab != _tabController.index) {
        setState(() => _currentTab = _tabController.index);
      }
    });
    loadSession();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
  Future<void> loadData() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    if (mounted) {
      LoaderService.show(
        context,
        title: "Loading Movable Asset",
        subtitle: "Fetching data from server...",
      );
    }

    try {
      final data = await ApiService.getMovableAssetData(
        userId: userId,
        userPwd: userpwd,
      );

      if (!mounted) return;

      setState(() {
        lookups = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        errorMessage = e.toString().replaceFirst("Exception: ", "");
      });
    } finally {
      LoaderService.hide();
    }
  }

  // ================= MESSAGE BOX =================
  // Every error / info message goes through this (no snack bars).
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

  Future<bool> _confirm({
    required String title,
    required String message,
    required String actionLabel,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(actionLabel, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return ok == true;
  }

  // ================= HELPERS =================
  String _fmtQty(double q) =>
      q == q.roundToDouble() ? q.toInt().toString() : q.toString();

  String _fmtRate(double r) => r.toStringAsFixed(2);

  String _orDash(String s) => s.trim().isEmpty ? "-" : s;

  // A client with no sites in the data can't have a site picked.
  bool get _selectedClientHasSites =>
      selectedClient != null &&
      lookups!.sitesForClient(selectedClient!.id).isNotEmpty;

  // ================= VALIDATION =================
  // Information tab:
  //  * at least ONE of Location / Client / Site / Agency
  //  * if a Client is chosen, a Site must be chosen too (when that
  //    client actually has sites)
  //  * Responsible Person
  String? _validateInfo() {
    final hasAny =
        selectedLocation != null ||
        selectedClient != null ||
        selectedSite != null ||
        selectedAgency != null;

    if (!hasAny) {
      return "Please select at least one of Location, Client, Site or Agency";
    }

    if (selectedClient != null &&
        _selectedClientHasSites &&
        selectedSite == null) {
      return "Please select a Site for the selected Client";
    }

    if (selectedEmp == null) return "Please select a Responsible Person";

    return null;
  }

  String? _validateAssets() {
    if (addedLines.isEmpty) return "Please add at least one Asset";
    return null;
  }

  // ================= NAVIGATION =================
  Future<void> _goNext() async {
    String? error;
    if (_currentTab == 0) error = _validateInfo();
    if (_currentTab == 1) error = _validateAssets();

    if (error != null) {
      await _showMessage(error);
      return;
    }

    _tabController.animateTo(_currentTab + 1);
  }

  // ================= SAVE =================
  Future<void> _save() async {
    if (isSaving) return; // block double-tap

    final infoError = _validateInfo();
    if (infoError != null) {
      _tabController.animateTo(0);
      await _showMessage(infoError);
      return;
    }

    final assetError = _validateAssets();
    if (assetError != null) {
      _tabController.animateTo(1);
      await _showMessage(assetError);
      return;
    }

    setState(() => isSaving = true);

    LoaderService.show(
      context,
      title: "Saving Movable Asset",
      subtitle: "Please wait...",
    );

    String? savedMessage;
    String? errorText;

    try {
      savedMessage = await ApiService.saveMovableAsset(
        userId: userId,
        userPwd: userpwd,
        vouDate: vouDate,
        location: selectedLocation,
        client: selectedClient,
        site: selectedSite,
        agency: selectedAgency,
        emp: selectedEmp!,
        notes: notes.trim(),
        lines: List<MaAssetLine>.from(addedLines),
      );
    } catch (e) {
      errorText = e.toString().replaceFirst("Exception: ", "");
    }

    // Hide the loader exactly once, only after the request has settled.
    LoaderService.hide();

    if (!mounted) return;

    setState(() => isSaving = false);

    if (errorText != null) {
      await _showMessage(errorText);
      return;
    }

    // The server message carries the generated Vou No.
    await _showMessage(
      savedMessage!.isNotEmpty ? savedMessage : "Saved successfully.",
      title: "Saved",
    );

    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  // ================= PHOTO =================
  String _extFrom(String name) {
    final dot = name.lastIndexOf('.');
    if (dot == -1 || dot == name.length - 1) return "jpg";
    final ext = name
        .substring(dot + 1)
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
    return (ext.isEmpty || ext.length > 5) ? "jpg" : ext;
  }

  Future<ImageSource?> _chooseSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text("Take Photo"),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text("Choose from Gallery"),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  // Camera (the camera app itself asks OK / Cancel) or gallery. The photo
  // is shrunk (max 1600px, 70% quality) so the upload stays small.
  Future<_PickedPhoto?> _pickPhoto() async {
    final source = await _chooseSource();
    if (source == null) return null;

    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (file == null) return null; // user cancelled

      final bytes = await file.readAsBytes();

      if (bytes.isEmpty) {
        await _showMessage("The photo is empty. Please try again.");
        return null;
      }

      return _PickedPhoto(bytes, _extFrom(file.name));
    } catch (e) {
      await _showMessage(
        "Could not get the photo. Please check the camera / photo permission and try again.",
      );
      return null;
    }
  }

  void _previewPhoto(Uint8List bytes) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            SizedBox(
              height: MediaQuery.of(dialogContext).size.height * 0.75,
              width: double.infinity,
              child: InteractiveViewer(
                child: Image.memory(bytes, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(dialogContext),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumb(Uint8List bytes, double size) {
    return GestureDetector(
      onTap: () => _previewPhoto(bytes),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
          cacheWidth: (size * 3).toInt(),
        ),
      ),
    );
  }

  Widget _sheetHandle() {
    return Center(
      child: Container(
        width: 45,
        height: 5,
        decoration: BoxDecoration(
          color: Colors.grey.shade400,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // ================= ITEM POPUP: ADD / EDIT / VIEW =================
  // One item under an asset: Item (+ HSN code, rate shown automatically),
  // Tax (GST), Qty, UOM, Remarks. Returns null if cancelled.
  // `others` = the asset's other items (to stop the same item twice).
  Future<MaItemEntry?> _showItemSheet({
    required String mode, // "add" | "edit" | "view"
    MaItemEntry? existing,
    required List<MaItemEntry> others,
  }) async {
    if (lookups == null) return null;

    final isView = mode == "view";
    final isAdd = mode == "add";

    MaItem? sItem = existing?.item;
    MaLookupItem? sTax = existing?.tax;
    MaUom? sUom = existing?.uom;

    MaUom? uomForItem(MaItem? item) {
      if (item == null || item.uomCode.isEmpty) return null;
      final code = item.uomCode.toLowerCase();
      for (final uom in lookups!.uoms) {
        if (uom.name.toLowerCase() == code || uom.code.toLowerCase() == code) {
          return uom;
        }
      }
      return null;
    }

    final hsnController = TextEditingController(
      text: existing?.hsnCode ?? sItem?.hsnCode ?? "",
    );
    final qtyController = TextEditingController(
      text: existing != null ? _fmtQty(existing.qty) : "",
    );
    final remarksController = TextEditingController(
      text: existing?.remarks ?? "",
    );

    final result = await showModalBottomSheet<MaItemEntry>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sheetHandle(),
                    const SizedBox(height: 14),
                    Text(
                      isAdd ? "Add Item" : (isView ? "View Item" : "Edit Item"),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _dropdown<MaItem>(
                      label: "Item *",
                      searchHint: "Search Item",
                      value: sItem,
                      items: () => lookups!.items,
                      text: (i) => i.name,
                      same: (a, b) => a.id == b.id,
                      enabled: !isView,
                      onChanged: (v) => setSheetState(() {
                        sItem = v;
                        sUom = uomForItem(v);
                        hsnController.text = v?.hsnCode ?? "";
                      }),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: hsnController,
                            readOnly: isView,
                            decoration: const InputDecoration(
                              labelText: "Item HSN Code",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _infoBox(
                            "Item Rate",
                            sItem != null ? _fmtRate(sItem!.rate) : "-",
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _dropdown<MaLookupItem>(
                      label: "Tax (GST) *",
                      searchHint: "Search Tax",
                      value: sTax,
                      items: () => lookups!.taxes,
                      text: (t) => t.name,
                      same: (a, b) => a.id == b.id,
                      enabled: !isView,
                      searchable: false,
                      onChanged: (v) => setSheetState(() => sTax = v),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: qtyController,
                            readOnly: isView,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,3}'),
                              ),
                            ],
                            decoration: const InputDecoration(
                              labelText: "Qty *",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _dropdown<MaUom>(
                            label: "UOM *",
                            searchHint: "Search UOM",
                            value: sUom,
                            items: () => lookups!.uoms,
                            text: (u) => u.name,
                            same: (a, b) => a.name == b.name,
                            enabled: !isView,
                            searchable: false,
                            onChanged: (v) => setSheetState(() => sUom = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: remarksController,
                      readOnly: isView,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: "Remarks",
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            child: Text(isView ? "Close" : "Cancel"),
                          ),
                        ),
                        if (!isView) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlue,
                              ),
                              onPressed: () async {
                                final qty =
                                    double.tryParse(
                                      qtyController.text.trim(),
                                    ) ??
                                    0;

                                String? error;
                                if (sItem == null) {
                                  error = "Please select an Item";
                                } else if (sTax == null) {
                                  error = "Please select a Tax (GST)";
                                } else if (qty <= 0) {
                                  error = "Please enter a valid Qty";
                                } else if (sUom == null) {
                                  error = "Please select a UOM";
                                } else if (others.any(
                                  (o) => o.item.id == sItem!.id,
                                )) {
                                  error =
                                      "This item is already added for this asset.";
                                }

                                if (error != null) {
                                  await _showMessage(error);
                                  return;
                                }

                                if (!sheetContext.mounted) return;
                                Navigator.pop(
                                  sheetContext,
                                  MaItemEntry(
                                    item: sItem!,
                                    hsnCode: hsnController.text.trim(),
                                    tax: sTax!,
                                    qty: qty,
                                    uom: sUom!,
                                    remarks: remarksController.text.trim(),
                                  ),
                                );
                              },
                              child: Text(
                                isAdd ? "Save Item" : "Update Item",
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    // The sheet is still animating out when the future completes, so the
    // controllers are released a moment later (disposing them straight
    // away can throw "used after being disposed" in debug builds).
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      hsnController.dispose();
      qtyController.dispose();
      remarksController.dispose();
    });

    return result;
  }

  // One item row inside the asset popup.
  Widget _itemTile({
    required MaItemEntry entry,
    required bool isView,
    required VoidCallback onTap,
    VoidCallback? onDelete,
  }) {
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: borderColor),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Qty: ${_fmtQty(entry.qty)} ${entry.uom.name}",
                      style: const TextStyle(color: textColor, fontSize: 12),
                    ),
                    Text(
                      entry.tax.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: mutedColor, fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (isView)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.chevron_right, size: 18, color: mutedColor),
                )
              else ...[
                const Icon(Icons.edit_outlined, size: 18, color: primaryBlue),
                IconButton(
                  tooltip: "Delete item",
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: Colors.red,
                  ),
                  onPressed: onDelete,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ================= ASSET POPUP: ADD / EDIT / VIEW =================
  // One popup holds the whole asset:
  //   Asset (+ asset code, HSN code, rate shown automatically)
  //   Asset Photo (compulsory)
  //   Items — one asset can have many; "Add Item" opens the item popup,
  //   and "Save Asset" saves the asset with all its items.
  Future<void> _showAssetSheet({
    required String mode, // "add" | "edit" | "view"
    int? index,
  }) async {
    if (lookups == null) return;

    final isView = mode == "view";
    final isAdd = mode == "add";

    final MaAssetLine? existing = (index != null && index < addedLines.length)
        ? addedLines[index]
        : null;

    MaAsset? sAsset = existing?.asset;
    final hsnController = TextEditingController(
      text: existing?.hsnCode ?? sAsset?.hsnCode ?? "",
    );
    Uint8List? sPhoto = existing?.photoBytes;
    String sPhotoExt = existing?.photoExt ?? "jpg";
    final List<MaItemEntry> sItems = List<MaItemEntry>.from(
      existing?.items ?? const <MaItemEntry>[],
    );

    final result = await showModalBottomSheet<MaAssetLine>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sheetHandle(),
                    const SizedBox(height: 14),
                    Text(
                      isAdd
                          ? "Add Asset"
                          : (isView ? "View Asset" : "Edit Asset"),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ---------- ASSET ----------
                    _dropdown<MaAsset>(
                      label: "Asset Name *",
                      searchHint: "Search Asset",
                      value: sAsset,
                      items: () => lookups!.assets,
                      text: (a) => a.name,
                      same: (a, b) => a.id == b.id,
                      enabled: !isView,
                      onChanged: (v) => setSheetState(() {
                        sAsset = v;
                        hsnController.text = v?.hsnCode ?? "";
                      }),
                    ),
                    const SizedBox(height: 12),
                    _infoBox("Asset Code", _orDash(sAsset?.assetCode ?? "")),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: hsnController,
                            readOnly: isView,
                            decoration: const InputDecoration(
                              labelText: "HSN Code",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _infoBox(
                            "Rate",
                            sAsset != null ? _fmtRate(sAsset!.rate) : "-",
                          ),
                        ),
                      ],
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(height: 1),
                    ),

                    // ---------- PHOTO ----------
                    Text(
                      isView ? "Asset Photo" : "Asset Photo *",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (!isView)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: sPhoto == null
                              ? primaryBlue
                              : Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () async {
                          final picked = await _pickPhoto();
                          if (picked != null && sheetContext.mounted) {
                            setSheetState(() {
                              sPhoto = picked.bytes;
                              sPhotoExt = picked.ext;
                            });
                          }
                        },
                        icon: Icon(
                          sPhoto == null
                              ? Icons.add_a_photo_outlined
                              : Icons.check_circle,
                          color: Colors.white,
                        ),
                        label: Text(
                          sPhoto == null ? "Add Photo" : "Photo Added",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    if (sPhoto != null) ...[
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => _previewPhoto(sPhoto!),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            sPhoto!,
                            height: 170,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            cacheWidth: 900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Tap the photo to enlarge",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: mutedColor, fontSize: 11),
                      ),
                    ] else if (isView)
                      const Text(
                        "No photo",
                        style: TextStyle(color: mutedColor),
                      ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(height: 1),
                    ),

                    // ---------- ITEMS ----------
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            isView
                                ? "Items (${sItems.length})"
                                : "Items * (${sItems.length})",
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: primaryBlue,
                            ),
                          ),
                        ),
                        if (!isView)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                            ),
                            onPressed: () async {
                              final entry = await _showItemSheet(
                                mode: "add",
                                others: List<MaItemEntry>.from(sItems),
                              );
                              if (entry != null && sheetContext.mounted) {
                                setSheetState(() => sItems.add(entry));
                              }
                            },
                            icon: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 18,
                            ),
                            label: const Text(
                              "Add Item",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (sItems.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          "No items added yet. Tap \"Add Item\".",
                          style: TextStyle(color: mutedColor, fontSize: 13),
                        ),
                      )
                    else
                      for (var i = 0; i < sItems.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _itemTile(
                            entry: sItems[i],
                            isView: isView,
                            onTap: () async {
                              final others = <MaItemEntry>[
                                for (var j = 0; j < sItems.length; j++)
                                  if (j != i) sItems[j],
                              ];
                              final edited = await _showItemSheet(
                                mode: isView ? "view" : "edit",
                                existing: sItems[i],
                                others: others,
                              );
                              if (edited != null && sheetContext.mounted) {
                                setSheetState(() => sItems[i] = edited);
                              }
                            },
                            onDelete: () async {
                              final ok = await _confirm(
                                title: "Delete Item",
                                message:
                                    "Remove \"${sItems[i].item.name}\" from this asset?",
                                actionLabel: "Delete",
                              );
                              if (ok && sheetContext.mounted) {
                                setSheetState(() => sItems.removeAt(i));
                              }
                            },
                          ),
                        ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            child: Text(isView ? "Close" : "Cancel"),
                          ),
                        ),
                        if (!isView) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlue,
                              ),
                              onPressed: () async {
                                String? error;
                                if (sAsset == null) {
                                  error = "Please select an Asset";
                                } else if (sPhoto == null) {
                                  error = "Please add a photo of the asset";
                                } else if (sItems.isEmpty) {
                                  error = "Please add at least one Item";
                                } else if (addedLines.asMap().entries.any(
                                  (e) =>
                                      e.value.asset.id == sAsset!.id &&
                                      e.key != index,
                                )) {
                                  error = "This asset is already added.";
                                }

                                if (error != null) {
                                  await _showMessage(error);
                                  return;
                                }

                                if (!sheetContext.mounted) return;
                                Navigator.pop(
                                  sheetContext,
                                  MaAssetLine(
                                    asset: sAsset!,
                                    hsnCode: hsnController.text.trim(),
                                    items: List<MaItemEntry>.from(sItems),
                                    photoBytes: sPhoto!,
                                    photoExt: sPhotoExt,
                                  ),
                                );
                              },
                              child: Text(
                                isAdd ? "Save Asset" : "Update Asset",
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    Future<void>.delayed(const Duration(milliseconds: 500), () {
      hsnController.dispose();
    });

    if (result == null || !mounted) return;

    setState(() {
      if (isAdd) {
        addedLines.add(result);
      } else if (index != null && index < addedLines.length) {
        addedLines[index] = result;
      }
    });
  }

  Future<void> _confirmDelete(int index) async {
    if (index >= addedLines.length) return;
    final line = addedLines[index];

    final ok = await _confirm(
      title: "Delete Asset",
      message:
          "Remove \"${line.asset.name}\" and its ${line.items.length} item(s) from this voucher?",
      actionLabel: "Delete",
    );

    if (ok && mounted) {
      setState(() => addedLines.removeAt(index));
    }
  }

  // ================= NOTES POPUP =================
  Future<void> _showNotesSheet() async {
    final controller = TextEditingController(text: notes);

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            MediaQuery.of(sheetContext).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sheetHandle(),
                const SizedBox(height: 14),
                const Text(
                  "Notes",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  minLines: 6,
                  maxLines: 10,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                    hintText: "Enter notes...",
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                        ),
                        onPressed: () =>
                            Navigator.pop(sheetContext, controller.text),
                        child: const Text(
                          "Save Notes",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    Future<void>.delayed(const Duration(milliseconds: 500), controller.dispose);

    if (result == null || !mounted) return;
    setState(() => notes = result.trim());
  }

  // ================= FULL INFORMATION POPUP =================
  Future<void> _showInfoDetails() async {
    Widget row(String label, String? value) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: mutedColor, fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(
              (value == null || value.isEmpty) ? "-" : value,
              style: const TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sheetHandle(),
              const SizedBox(height: 14),
              const Text(
                "Voucher Details",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
              const SizedBox(height: 16),
              row("Vou. Date", DateFormat('dd/MM/yyyy').format(vouDate)),
              row("Location", selectedLocation?.name),
              row("Client", selectedClient?.name),
              row("Site", selectedSite?.name),
              row("Agency", selectedAgency?.name),
              row("Responsible Person", selectedEmp?.name),
              const SizedBox(height: 4),
              OutlinedButton(
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text("Close"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= DATE =================
  Future<void> _pickVouDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: vouDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => vouDate = picked);
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: primaryBlue,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            "Movable Asset",
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null || lookups == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: primaryBlue,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            "Movable Asset",
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: Center(
          child: Padding(
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
                  onPressed: loadData,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text(
                    "Retry",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Movable Asset",
          style: TextStyle(color: Colors.white),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            const Tab(text: "Information"),
            Tab(text: "Assets (${addedLines.length})"),
            const Tab(text: "Preview"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [_infoTab(), _assetsTab(), _previewTab()],
      ),
      bottomNavigationBar: _bottomBar(),
    );
  }

  // ================= BOTTOM BAR =================
  Widget _bottomBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: borderColor)),
        ),
        child: Row(
          children: [
            if (_currentTab > 0) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: isSaving
                      ? null
                      : () => _tabController.animateTo(_currentTab - 1),
                  child: const Text("Back"),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: _currentTab < 2
                  ? ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                      ),
                      onPressed: _goNext,
                      child: const Text(
                        "Next",
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                      ),
                      onPressed: isSaving ? null : _save,
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "Save",
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= TAB 1: INFORMATION =================
  Widget _infoTab() {
    final clientHasNoSites = selectedClient != null && !_selectedClientHasSites;

    final locationEnabled =
        selectedClient == null &&
        selectedSite == null &&
        selectedAgency == null;

    final otherFieldsEnabled = selectedLocation == null;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            InkWell(
              onTap: _pickVouDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: "Vou. Date *",
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today, size: 18),
                ),
                child: Text(DateFormat('dd/MM/yyyy').format(vouDate)),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Select at least one of Location, Client, Site or Agency.",
              style: TextStyle(color: mutedColor, fontSize: 12),
            ),
            const SizedBox(height: 10),
            _dropdown<MaLookupItem>(
              label: "Location",
              searchHint: "Search Location",
              value: selectedLocation,
              enabled: locationEnabled,
              items: () => lookups!.locations,
              text: (l) => l.name,
              same: (a, b) => a.id == b.id,
              onChanged: (v) {
                setState(() {
                  selectedLocation = v;

                  if (v != null) {
                    selectedClient = null;
                    selectedSite = null;
                    selectedAgency = null;
                  }
                });
              },
            ),
            const SizedBox(height: 14),
            _dropdown<MaLookupItem>(
              label: "Client",
              searchHint: "Search Client",
              value: selectedClient,
              enabled: otherFieldsEnabled,
              items: () => lookups!.clients,
              text: (c) => c.name,
              same: (a, b) => a.id == b.id,
              onChanged: (v) {
                setState(() {
                  selectedClient = v;

                  if (v != null) {
                    selectedLocation = null;
                  } else {
                    selectedSite = null;
                  }

                  final validSites = lookups!
                      .sitesForClient(selectedClient?.id)
                      .map((s) => s.id)
                      .toSet();

                  if (selectedSite != null &&
                      !validSites.contains(selectedSite!.id)) {
                    selectedSite = null;
                  }
                });
              },
            ),
            const SizedBox(height: 14),
            _dropdown<MaLookupItem>(
              key: ValueKey('site_${selectedClient?.id}'),
              label: _selectedClientHasSites ? "Site *" : "Site",
              searchHint: "Search Site",
              value: selectedSite,
              enabled: otherFieldsEnabled && selectedClient != null,
              items: () => lookups!.sitesForClient(selectedClient?.id),
              text: (s) => s.name,
              same: (a, b) => a.id == b.id,
              helperText: clientHasNoSites
                  ? "This client has no sites, so none is needed."
                  : null,
              onChanged: (v) {
                setState(() {
                  selectedSite = v;

                  if (v != null) {
                    selectedLocation = null;
                  }
                });
              },
            ),
            const SizedBox(height: 14),
            _dropdown<MaLookupItem>(
              label: "Agency",
              searchHint: "Search Agency",
              value: selectedAgency,
              enabled: otherFieldsEnabled,
              items: () => lookups!.agencies,
              text: (a) => a.name,
              same: (a, b) => a.id == b.id,
              onChanged: (v) {
                setState(() {
                  selectedAgency = v;

                  if (v != null) {
                    selectedLocation = null;
                  }
                });
              },
            ),
            const SizedBox(height: 14),
            _dropdown<MaLookupItem>(
              label: "Responsible Person *",
              searchHint: "Search Employee",
              value: selectedEmp,
              items: () => lookups!.emps,
              text: (e) => e.name,
              same: (a, b) => a.id == b.id,
              onChanged: (v) => setState(() => selectedEmp = v),
            ),
          ],
        ),
      ),
    );
  }

  // ================= TAB 2: ASSETS (+ NOTES) =================
  Widget _assetsTab() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Assets (${addedLines.length})",
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: primaryBlue,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                    ),
                    onPressed: () => _showAssetSheet(mode: "add"),
                    icon: const Icon(Icons.add, color: Colors.white, size: 18),
                    label: const Text(
                      "Add Asset",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            // Notes: a small card — tap to write notes in a popup.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Material(
                color: Colors.white,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: borderColor),
                ),
                child: InkWell(
                  onTap: _showNotesSheet,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.notes_outlined,
                          size: 20,
                          color: primaryBlue,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Notes",
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: primaryBlue,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                notes.isEmpty ? "Tap to add notes" : notes,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: mutedColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: primaryBlue,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: addedLines.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 44,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "No assets added yet.\nTap \"Add Asset\" to add one.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: mutedColor),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: addedLines.length,
                      itemBuilder: (_, index) =>
                          _lineCard(addedLines[index], index),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lineCard(MaAssetLine line, int index) {
    const maxShown = 3;
    final shown = line.items.take(maxShown).toList();
    final extra = line.items.length - shown.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _thumb(line.photoBytes, 56),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.asset.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: primaryBlue,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Asset Code: ${_orDash(line.asset.assetCode)}",
                  style: const TextStyle(color: mutedColor, fontSize: 12),
                ),
                const Divider(height: 16),
                Text(
                  "Items (${line.items.length})",
                  style: const TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                for (final e in shown)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      "• ${e.item.name} — ${_fmtQty(e.qty)} ${e.uom.name}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: textColor, fontSize: 12),
                    ),
                  ),
                if (extra > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      "+ $extra more",
                      style: const TextStyle(color: mutedColor, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: primaryBlue),
            onSelected: (value) {
              if (value == "view") {
                _showAssetSheet(mode: "view", index: index);
              } else if (value == "edit") {
                _showAssetSheet(mode: "edit", index: index);
              } else if (value == "delete") {
                _confirmDelete(index);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: "view", child: Text("View")),
              PopupMenuItem(value: "edit", child: Text("Edit")),
              PopupMenuItem(value: "delete", child: Text("Delete")),
            ],
          ),
        ],
      ),
    );
  }

  // ================= TAB 3: PREVIEW =================
  // A last look at everything before saving. Small cards; tap one to
  // see its full data, or use the pencil to jump back and fix it.
  Widget _previewTab() {
    final issue = _validateInfo() ?? _validateAssets();

    final assetRows = <Widget>[];
    for (var i = 0; i < addedLines.length; i++) {
      if (i > 0) assetRows.add(const Divider(height: 1));
      assetRows.add(_previewAssetRow(addedLines[i], i));
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _statusBanner(issue),
            const SizedBox(height: 12),
            _sectionCard(
              title: "Information",
              icon: Icons.assignment_outlined,
              onTap: _showInfoDetails,
              onEdit: () => _tabController.animateTo(0),
              child: Column(
                children: [
                  _kv("Vou. Date", DateFormat('dd/MM/yyyy').format(vouDate)),
                  _kv("Location", selectedLocation?.name),
                  _kv("Client", selectedClient?.name),
                  _kv("Site", selectedSite?.name),
                  _kv("Agency", selectedAgency?.name),
                  _kv("Responsible", selectedEmp?.name, required: true),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _sectionCard(
              title: "Assets (${addedLines.length})",
              icon: Icons.inventory_2_outlined,
              onEdit: () => _tabController.animateTo(1),
              child: addedLines.isEmpty
                  ? const Text(
                      "No assets added",
                      style: TextStyle(color: Colors.red, fontSize: 13),
                    )
                  : Column(children: assetRows),
            ),
            const SizedBox(height: 12),
            _sectionCard(
              title: "Notes",
              icon: Icons.notes_outlined,
              onTap: _showNotesSheet,
              onEdit: _showNotesSheet,
              child: Text(
                notes.isEmpty ? "No notes added" : notes,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: notes.isEmpty ? mutedColor : textColor,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBanner(String? issue) {
    final ok = issue == null;
    final color = ok ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.warning_amber_rounded,
            color: color.shade700,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              ok
                  ? "All required details are filled. Review below, then tap Save."
                  : issue,
              style: TextStyle(color: color.shade900, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    VoidCallback? onTap,
    VoidCallback? onEdit,
  }) {
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: borderColor),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 6, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: primaryBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: primaryBlue,
                      ),
                    ),
                  ),
                  if (onEdit != null)
                    IconButton(
                      tooltip: "Edit",
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: primaryBlue,
                      ),
                      onPressed: onEdit,
                    ),
                ],
              ),
              Padding(padding: const EdgeInsets.only(right: 8), child: child),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kv(String label, String? value, {bool required = false}) {
    final empty = value == null || value.isEmpty;
    final missing = empty && required;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(color: mutedColor, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              missing ? "Required" : (empty ? "-" : value),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: missing ? Colors.red : textColor,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewAssetRow(MaAssetLine line, int index) {
    final first = line.items.isNotEmpty ? line.items.first.item.name : "-";
    final more = line.items.length > 1 ? " +${line.items.length - 1} more" : "";

    return InkWell(
      onTap: () => _showAssetSheet(mode: "view", index: index),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            _thumb(line.photoBytes, 44),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.asset.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${line.items.length} item(s) • $first$more",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: mutedColor, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: mutedColor),
          ],
        ),
      ),
    );
  }

  // ================= SHARED WIDGETS =================

  // Read-only box (asset code, HSN code, rates). Uses an
  // InputDecorator so no controllers need creating or disposing.
  Widget _infoBox(String label, String value) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: readOnlyFill,
      ),
      child: Text(value),
    );
  }

  Widget _dropdown<T>({
    Key? key,
    required String label,
    required String searchHint,
    required T? value,
    required List<T> Function() items,
    required String Function(T) text,
    required bool Function(T, T) same,
    required ValueChanged<T?> onChanged,
    bool enabled = true,
    bool searchable = true,
    String? helperText,
  }) {
    return DropdownSearch<T>(
      key: key,
      enabled: enabled,
      selectedItem: value,
      items: (filter, _) => items(),
      itemAsString: text,
      compareFn: same,
      onChanged: onChanged,
      // Names (assets, items, clients) can be long — wrap to two lines
      // instead of overflowing the closed field.
      dropdownBuilder: (context, item) => Text(
        item == null ? "" : text(item),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      decoratorProps: DropDownDecoratorProps(
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          border: const OutlineInputBorder(),
        ),
      ),
      popupProps: PopupProps.menu(
        showSearchBox: searchable,
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            hintText: searchHint,
            prefixIcon: const Icon(Icons.search),
          ),
        ),
      ),
      suffixProps: const DropdownSuffixProps(
        clearButtonProps: ClearButtonProps(isVisible: true),
      ),
    );
  }
}
