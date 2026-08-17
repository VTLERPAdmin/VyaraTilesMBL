import 'dart:async';
import 'dart:convert';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/app_config.dart';

import '../models/sample_request_models.dart';
import '../screens/loader_service.dart';
import '../services/api_services.dart';

class SampleRequestScreen extends StatefulWidget {
  final String userId;
  final String userpwd;

  const SampleRequestScreen({
    super.key,
    required this.userId,
    required this.userpwd,
  });

  @override
  State<SampleRequestScreen> createState() =>
      _SampleRequestScreenState();
}

class _SampleRequestScreenState extends State<SampleRequestScreen>
    with SingleTickerProviderStateMixin {
  // ==========================================================
  // COLORS
  // ==========================================================

  static const Color primaryColor = Color(0xFF06275B);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color borderColor = Color(0xFFD9DEE7);
  static const Color textColor = Color(0xFF172033);
  static const Color mutedColor = Color(0xFF667085);

  // ==========================================================
  // RESPONSIVE BREAKPOINTS
  // ==========================================================

  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  // ==========================================================
  // TAB
  // ==========================================================

  late TabController _tabController;

  int _currentTab = 0;

  // ==========================================================
  // MASTER DATA
  // ==========================================================

  SampleRequestMasterModel? _masterData;

  bool _isLoading = true;
  String? _loadError;

  // ==========================================================
  // INFORMATION
  // ==========================================================

  final TextEditingController _requestNoController =
      TextEditingController();

  final TextEditingController _dateController =
      TextEditingController();

  final TextEditingController _dueDateController =
      TextEditingController();

  SampleRequestLookupModel? _selectedFactory;
  SampleRequestLookupModel? _selectedReason;
  SampleRequestLookupModel? _selectedDeliveryMode;
  SampleRequestLookupModel? _selectedRequestedBy;

  // ==========================================================
  // SITE DETAILS
  // ==========================================================

  SampleRequestLedgerModel? _selectedLedger;

  final TextEditingController _siteController =
      TextEditingController();

  final TextEditingController _referenceController =
      TextEditingController();

  final TextEditingController _addressController =
      TextEditingController();

  final TextEditingController _contactController =
      TextEditingController();

  final TextEditingController _gstController =
      TextEditingController();

  final TextEditingController _panController =
      TextEditingController();

  // ==========================================================
  // PRODUCTS
  // ==========================================================

  final List<SampleRequestLineModel> _productLines = [];



  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 3,
      vsync: this,
    );

    _tabController.addListener(() {
      if (_tabController.index != _currentTab) {
        if (!mounted) return;

        setState(() {
          _currentTab = _tabController.index;
        });
      }
    });

    _dateController.text =
        DateFormat('dd/MM/yyyy').format(DateTime.now());

    _loadMasterData();
  }

  // ==========================================================
  // LOAD MASTER DATA
  // ==========================================================

  Future<void> _loadMasterData() async {
    if (!mounted) return;

    final frameDone = Completer<void>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!frameDone.isCompleted) {
        frameDone.complete();
      }
    });

    await frameDone.future;

    if (!mounted) return;

    LoaderService.show(
      context,
      title: 'Loading Sample Request',
      subtitle: 'Fetching data from server...',
    );

    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final data = await ApiService.getSampleRequestData(
        widget.userId,
        widget.userpwd,
      );

      if (!mounted) return;

      setState(() {
        _masterData = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _loadError = e.toString();
      });
    } finally {
      LoaderService.hide();
    }
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _tabController.dispose();

    _requestNoController.dispose();
    _dateController.dispose();
    _dueDateController.dispose();

    _siteController.dispose();
    _referenceController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    _gstController.dispose();
    _panController.dispose();

    super.dispose();
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  // ==========================================================
  // APP BAR
  // ==========================================================

  PreferredSizeWidget _buildAppBar() {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < mobileBreakpoint;

    return AppBar(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      titleSpacing: isMobile ? 12 : 16,
      title: Text(
        'Sample Request',
        style: TextStyle(
          fontSize: isMobile ? 17 : 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ==========================================================
  // BODY
  // ==========================================================

  Widget _buildBody() {
    if (_isLoading && _masterData == null && _loadError == null) {
      return const SizedBox.shrink();
    }

    if (_loadError != null) {
      return _buildErrorState();
    }

    if (_masterData == null) {
      return const Center(
        child: Text(
          'No Sample Request data available.',
        ),
      );
    }

    return Column(
      children: [
        _buildTabBar(),

        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildInformationTab(),
              _buildSiteDetailsTab(),
              _buildProductsTab(),
            ],
          ),
        ),

        _buildBottomNavigation(),
      ],
    );
  }

  // ==========================================================
  // ERROR
  // ==========================================================

  Widget _buildErrorState() {
    final width = MediaQuery.of(context).size.width;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(
          width < mobileBreakpoint ? 16 : 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.redAccent,
            ),

            const SizedBox(height: 12),

            const Text(
              'Unable to load Sample Request data',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _loadError ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: mutedColor,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _loadMasterData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // TAB BAR
  // ==========================================================

  Widget _buildTabBar() {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < mobileBreakpoint;

    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: primaryColor,
        unselectedLabelColor: mutedColor,
        indicatorColor: primaryColor,
        indicatorWeight: 3,
        labelStyle: TextStyle(
          fontSize: isMobile ? 11 : 13,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: isMobile ? 11 : 13,
        ),
        tabs: [
          Tab(
            icon: Icon(
              Icons.info_outline,
              size: isMobile ? 19 : 21,
            ),
            text: 'Information',
          ),
          Tab(
            icon: Icon(
              Icons.location_on_outlined,
              size: isMobile ? 19 : 21,
            ),
            text: 'Site Details',
          ),
          Tab(
            icon: Icon(
              Icons.inventory_2_outlined,
              size: isMobile ? 19 : 21,
            ),
            text: 'Products',
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // INFORMATION TAB
  // ==========================================================

  Widget _buildInformationTab() {
    final data = _masterData!;

    return _scrollableContent(
      children: [
        _sectionTitle(
          'Request Information',
          Icons.description_outlined,
        ),

        _card(
          children: [
            _responsiveRow(
              first: _textField(
                controller: _requestNoController,
                label: 'Req. No.',
                enabled: false,
                hint: 'Auto generated',
              ),
              second: _dateField(
                controller: _dateController,
                label: 'Date',
              ),
            ),

            _responsiveRow(
              first: _dateField(
                controller: _dueDateController,
                label: 'Due Date',
              ),
              second: _dropdown<SampleRequestLookupModel>(
                label: 'Factory',
                value: _selectedFactory,
                items: data.locations,
                itemLabel: (e) => e.name,
                onChanged: (value) {
                  setState(() {
                    _selectedFactory = value;
                  });
                },
              ),
            ),

            _responsiveRow(
              first: _dropdown<SampleRequestLookupModel>(
                label: 'Reason',
                value: _selectedReason,
                items: data.reasons,
                itemLabel: (e) => e.name,
                onChanged: (value) {
                  setState(() {
                    _selectedReason = value;
                  });
                },
              ),
              second: _dropdown<SampleRequestLookupModel>(
                label: 'Delivery Mode',
                value: _selectedDeliveryMode,
                items: data.deliveryModes,
                itemLabel: (e) => e.name,
                onChanged: (value) {
                  setState(() {
                    _selectedDeliveryMode = value;
                  });
                },
              ),
            ),

            _dropdown<SampleRequestLookupModel>(
              label: 'Requested By',
              value: _selectedRequestedBy,
              items: data.employees,
              itemLabel: (e) => e.name,
              onChanged: (value) {
                setState(() {
                  _selectedRequestedBy = value;
                });
              },
              searchable: true,
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================================
  // SITE DETAILS
  // ==========================================================

  Widget _buildSiteDetailsTab() {
    return _scrollableContent(
      children: [
        _sectionTitle(
          'Site Details',
          Icons.location_on_outlined,
        ),

        _card(
          children: [
            _ledgerSearch(),

            const SizedBox(height: 16),

            _textField(
              controller: _siteController,
              label: 'Site',
              hint: 'Enter site',
            ),

            const SizedBox(height: 16),

            _textField(
              controller: _referenceController,
              label: 'Reference',
            ),

            const SizedBox(height: 16),

            _addressBox(),

            const SizedBox(height: 16),

            _textField(
              controller: _contactController,
              label: 'Contact Name / No.',
              hint: 'Enter contact name / number',
            ),

            const SizedBox(height: 16),

            _responsiveRow(
              first: _textField(
                controller: _gstController,
                label: 'GST No.',
              ),
              second: _textField(
                controller: _panController,
                label: 'PAN No.',
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================================
  // LEDGER SEARCH
  // ==========================================================

  Widget _ledgerSearch() {
    final data = _masterData!;

    return DropdownSearch<SampleRequestLedgerModel>(
      selectedItem: _selectedLedger,

      items: (
        String filter,
        LoadProps? loadProps,
      ) async {
        final query = filter.trim().toLowerCase();

        if (query.isEmpty) {
          return data.ledgers.take(100).toList();
        }

        return data.ledgers
            .where(
              (ledger) =>
                  ledger.name.toLowerCase().contains(query) ||
                  ledger.id.toLowerCase().contains(query),
            )
            .take(100)
            .toList();
      },

      itemAsString: (ledger) =>
          '${ledger.name} (${ledger.id})',

      compareFn: (a, b) => a.id == b.id,

      decoratorProps: DropDownDecoratorProps(
        decoration: _inputDecoration(
          'Client / Ledger',
        ),
      ),

      popupProps: PopupProps.menu(
        fit: FlexFit.loose,

        menuProps: const MenuProps(
          backgroundColor: Colors.white,
          elevation: 8,
        ),

        showSearchBox: true,

        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            hintText: 'Search client / ledger...',

            prefixIcon: const Icon(
              Icons.search,
              color: mutedColor,
            ),

            filled: true,
            fillColor: Colors.white,

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide: const BorderSide(
                color: borderColor,
              ),
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide: const BorderSide(
                color: borderColor,
              ),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide: const BorderSide(
                color: primaryColor,
                width: 1.5,
              ),
            ),
          ),
        ),
      ),

      suffixProps: DropdownSuffixProps(
        clearButtonProps: ClearButtonProps(
          isVisible: _selectedLedger != null,

          icon: const Icon(
            Icons.close,
            size: 19,
            color: mutedColor,
          ),

          tooltip: 'Clear',

          padding: EdgeInsets.zero,
        ),

        dropdownButtonProps: DropdownButtonProps(
          isVisible: true,

          iconClosed: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: primaryColor,
          ),

          iconOpened: const Icon(
            Icons.keyboard_arrow_up_rounded,
            color: primaryColor,
          ),
        ),
      ),

      onChanged: (ledger) {
        setState(() {
          _selectedLedger = ledger;

          if (ledger == null) {
            _addressController.clear();
          } else {
            _addressController.text =
                ledger.address?.fullAddress ?? '';
          }
        });
      },
    );
  }

  // ==========================================================
  // ADDRESS
  // ==========================================================

  Widget _addressBox() {
    return TextField(
      controller: _addressController,
      minLines: 3,
      maxLines: 5,
      decoration: _inputDecoration(
        'Delivery Address',
      ).copyWith(
        hintText: _selectedLedger == null
            ? 'Select a Client / Ledger to auto-fill address'
            : 'Enter delivery address',
        alignLabelWithHint: true,
      ),
    );
  }

  // ==========================================================
  // PRODUCTS TAB
  // ==========================================================

  Widget _buildProductsTab() {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < mobileBreakpoint;

    return _scrollableContent(
      children: [
        if (isMobile)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sectionTitle(
                'Products',
                Icons.inventory_2_outlined,
              ),

              const SizedBox(height: 4),

              ElevatedButton.icon(
                onPressed: _openProductDialog,
                icon: const Icon(
                  Icons.add,
                  size: 18,
                ),
                label: const Text(
                  'Add Product',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                  ),
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: _sectionTitle(
                  'Products',
                  Icons.inventory_2_outlined,
                ),
              ),

              ElevatedButton.icon(
                onPressed: _openProductDialog,
                icon: const Icon(
                  Icons.add,
                  size: 18,
                ),
                label: const Text(
                  'Add Product',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),

        const SizedBox(height: 8),

        if (_productLines.isEmpty)
          _emptyProducts()
        else
          ...List.generate(
            _productLines.length,
            (index) {
              return _productCard(
                _productLines[index],
                index,
              );
            },
          ),

        if (_productLines.isNotEmpty)
          _productsSummary(),
      ],
    );
  }

  // ==========================================================
  // EMPTY PRODUCTS
  // ==========================================================

  Widget _emptyProducts() {
    return _card(
      children: [
        SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 40,
            ),
            child: Column(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),

                const SizedBox(height: 12),

                const Text(
                  'No products added',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Tap Add Product to create a request line.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: mutedColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // PRODUCT CARD
  // ==========================================================

  Widget _productCard(
    SampleRequestLineModel line,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: borderColor,
        ),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  line.product?.productName ?? 'Product',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ),

              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'view') {
                    _viewProduct(line);
                  } else if (value == 'edit') {
                    _openProductDialog(
                      existingLine: line,
                      index: index,
                    );
                  } else if (value == 'delete') {
                    _deleteProduct(index);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(
                          Icons.visibility_outlined,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text('View'),
                      ],
                    ),
                  ),

                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),

                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: Colors.red,
                        ),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const Divider(
            height: 20,
          ),

          Wrap(
            spacing: 22,
            runSpacing: 12,
            children: [
              _productInfo(
                'Grade',
                line.grade?.name ?? '-',
              ),

              _productInfo(
                'Finish',
                line.finish?.name ?? '-',
              ),

              _productInfo(
                'Unit',
                line.unit?.name ??
                    line.product?.uomCode ??
                    '-',
              ),

              _productInfo(
                'Qty',
                _formatNumber(line.quantity),
              ),

              _productInfo(
                'Rate',
                _formatMoney(line.rate),
              ),

              _productInfo(
                'Value',
                _formatMoney(line.value),
              ),
            ],
          ),

          if (line.isDryMix ||
              line.notes.trim().isNotEmpty)
            ...[
              const SizedBox(height: 14),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    if (line.isDryMix)
                      const Text(
                        'DryMix Product',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),

                    if (line.notes.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 4,
                        ),
                        child: Text(
                          line.notes,
                          style: const TextStyle(
                            color: mutedColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
        ],
      ),
    );
  }

  // ==========================================================
  // PRODUCT SUMMARY
  // ==========================================================

  Widget _productsSummary() {
    final total = _productLines.fold<double>(
      0,
      (sum, item) => sum + item.value,
    );

    final isMobile =
        MediaQuery.of(context).size.width <
            mobileBreakpoint;

    return Container(
      margin: const EdgeInsets.only(
        top: 4,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Total',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          Text(
            _formatMoney(total),
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 15 : 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // PRODUCT DIALOG
  // ==========================================================

  Future<void> _openProductDialog({
    SampleRequestLineModel? existingLine,
    int? index,
  }) async {
    if (!mounted || _masterData == null) {
      return;
    }

    final data = _masterData!;

    SampleRequestProductModel? selectedProduct =
        existingLine?.product;

    SampleRequestLookupModel? selectedGrade =
        existingLine?.grade;

    SampleRequestLookupModel? selectedFinish =
        existingLine?.finish;

    SampleRequestLookupModel? selectedUnit =
        existingLine?.unit;

    final quantityController = TextEditingController(
      text: existingLine == null
          ? ''
          : _formatNumber(existingLine.quantity),
    );

    final rateController = TextEditingController(
      text: existingLine == null
          ? ''
          : existingLine.rate.toString(),
    );

    final notesController = TextEditingController(
      text: existingLine?.notes ?? '',
    );

    bool isDryMix = existingLine?.isDryMix ?? false;

    final result =
        await showDialog<SampleRequestLineModel>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            dialogContext,
            setDialogState,
          ) {
            final screenWidth =
                MediaQuery.of(dialogContext).size.width;

            final screenHeight =
                MediaQuery.of(dialogContext).size.height;

            final isMobile =
                screenWidth < mobileBreakpoint;

            final dialogWidth = isMobile
                ? screenWidth * 0.94
                : screenWidth < 900
                    ? 650.0
                    : 700.0;

            void applyProduct(
              SampleRequestProductModel? product,
            ) {
              setDialogState(() {
                selectedProduct = product;

                if (product != null) {
                  rateController.text =
                      product.rate.toString();

                  final matchedUnit =
                      data.units.where(
                    (unit) =>
                        unit.name.toLowerCase() ==
                            product.uomCode.toLowerCase() ||
                        unit.code.toLowerCase() ==
                            product.uomCode.toLowerCase(),
                  );

                  if (matchedUnit.isNotEmpty) {
                    selectedUnit = matchedUnit.first;
                  }
                }
              });
            }

            return Dialog(
              insetPadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 10 : 24,
                vertical: 18,
              ),
              backgroundColor: Theme.of(
                dialogContext,
              ).dialogTheme.backgroundColor ??
                  Theme.of(dialogContext).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: dialogWidth,
                  maxHeight: screenHeight * 0.90,
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 16 : 20,
                    14,
                    isMobile ? 16 : 20,
                    10,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              existingLine == null
                                  ? 'Add Product'
                                  : 'Edit Product',
                              style: TextStyle(
                                fontSize: isMobile
                                    ? 20
                                    : 22,
                                fontWeight:
                                    FontWeight.w500,
                                color: textColor,
                              ),
                            ),
                          ),

                          IconButton(
                            onPressed: () {
                              Navigator.of(
                                dialogContext,
                              ).pop();
                            },
                            icon: const Icon(
                              Icons.close,
                              color: mutedColor,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      Flexible(
                        child: SingleChildScrollView(
                          physics:
                              const BouncingScrollPhysics(),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // ==================================================
                              // PRODUCT
                              // ==================================================

                              DropdownSearch<
                                  SampleRequestProductModel>(
                                selectedItem:
                                    selectedProduct,

                                items: (
                                  String filter,
                                  LoadProps? loadProps,
                                ) async {
                                  final query =
                                      filter.trim()
                                          .toLowerCase();

                                  if (query.isEmpty) {
                                    return data.products.baseData
                                        .take(100)
                                        .toList();
                                  }

                                  return data.products.baseData
                                      .where(
                                    (product) =>
                                        product.productName
                                            .toLowerCase()
                                            .contains(query) ||
                                        product.productId
                                            .toString()
                                            .contains(query) ||
                                        product.groupName
                                            .toLowerCase()
                                            .contains(query),
                                  )
                                      .take(100)
                                      .toList();
                                },

                                itemAsString: (product) =>
                                    '${product.productName} (${product.productId})',

                                compareFn: (a, b) =>
                                    a.productId ==
                                    b.productId,

                                decoratorProps:
                                    DropDownDecoratorProps(
                                  decoration:
                                      _inputDecoration(
                                    'Product',
                                  ),
                                ),

                                popupProps:
                                    PopupProps.menu(
                                  fit: FlexFit.loose,

                                  menuProps:
                                      const MenuProps(
                                    backgroundColor:
                                        Colors.white,
                                    elevation: 8,
                                  ),

                                  showSearchBox: true,

                                  searchFieldProps:
                                      TextFieldProps(
                                    decoration:
                                        InputDecoration(
                                      hintText:
                                          'Search product...',

                                      prefixIcon:
                                          const Icon(
                                        Icons.search,
                                        color: mutedColor,
                                      ),

                                      filled: true,
                                      fillColor:
                                          Colors.white,

                                      border:
                                          OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(
                                          7,
                                        ),
                                        borderSide:
                                            const BorderSide(
                                          color:
                                              borderColor,
                                        ),
                                      ),

                                      enabledBorder:
                                          OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(
                                          7,
                                        ),
                                        borderSide:
                                            const BorderSide(
                                          color:
                                              borderColor,
                                        ),
                                      ),

                                      focusedBorder:
                                          OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(
                                          7,
                                        ),
                                        borderSide:
                                            const BorderSide(
                                          color:
                                              primaryColor,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                suffixProps:
                                    DropdownSuffixProps(
                                  clearButtonProps:
                                      ClearButtonProps(
                                    isVisible:
                                        selectedProduct !=
                                            null,

                                    icon:
                                        const Icon(
                                      Icons.close,
                                      size: 19,
                                      color:
                                          mutedColor,
                                    ),

                                    tooltip: 'Clear',

                                    padding:
                                        EdgeInsets.zero,
                                  ),

                                  dropdownButtonProps:
                                      DropdownButtonProps(
                                    isVisible: true,

                                    iconClosed:
                                        const Icon(
                                      Icons
                                          .keyboard_arrow_down_rounded,
                                      color:
                                          primaryColor,
                                    ),

                                    iconOpened:
                                        const Icon(
                                      Icons
                                          .keyboard_arrow_up_rounded,
                                      color:
                                          primaryColor,
                                    ),
                                  ),
                                ),

                                onChanged: applyProduct,
                              ),

                              const SizedBox(height: 14),

                              // ==================================================
                              // GRADE + FINISH
                              // ==================================================

                              _responsiveDialogRow(
                                first: _dialogDropdown<
                                    SampleRequestLookupModel>(
                                  label: 'Grade',
                                  value: selectedGrade,
                                  items: data.grades,
                                  itemLabel: (e) => e.name,
                                  onChanged: (value) {
                                    setDialogState(() {
                                      selectedGrade = value;
                                    });
                                  },
                                ),

                                second: _dialogDropdown<
                                    SampleRequestLookupModel>(
                                  label: 'Finish',
                                  value: selectedFinish,
                                  items: data.finishes,
                                  itemLabel: (e) => e.name,
                                  onChanged: (value) {
                                    setDialogState(() {
                                      selectedFinish = value;
                                    });
                                  },
                                ),
                              ),

                              const SizedBox(height: 14),

                              // ==================================================
                              // QUANTITY + UNIT
                              // ==================================================

                              _responsiveDialogRow(
                                first: _dialogTextField(
                                  controller:
                                      quantityController,
                                  label: 'Quantity',
                                  keyboardType:
                                      const TextInputType
                                          .numberWithOptions(
                                    decimal: true,
                                  ),
                                ),

                                second: _dialogDropdown<
                                    SampleRequestLookupModel>(
                                  label: 'Unit',
                                  value: selectedUnit,
                                  items: data.units,
                                  itemLabel: (e) => e.name,
                                  onChanged: (value) {
                                    setDialogState(() {
                                      selectedUnit = value;
                                    });
                                  },
                                ),
                              ),

                              const SizedBox(height: 14),

                              _dialogTextField(
                                controller: rateController,
                                label: 'Rate',
                                keyboardType:
                                    const TextInputType
                                        .numberWithOptions(
                                  decimal: true,
                                ),
                              ),

                              const SizedBox(height: 14),

                              _dialogTextField(
                                controller: notesController,
                                label: 'Notes',
                                maxLines: 3,
                              ),

                              const SizedBox(height: 6),

                              SwitchListTile(
                                contentPadding:
                                    EdgeInsets.zero,
                                title: const Text(
                                  'DryMix Product',
                                ),
                                value: isDryMix,
                                activeColor: primaryColor,
                                onChanged: (value) {
                                  setDialogState(() {
                                    isDryMix = value;
                                  });
                                },
                              ),

                              const SizedBox(height: 4),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      // ==================================================
                      // ACTIONS
                      // ==================================================

                      SafeArea(
                        top: false,
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(
                                  dialogContext,
                                ).pop();
                              },
                              child: const Text(
                                'Cancel',
                              ),
                            ),

                            const SizedBox(width: 8),

                            ElevatedButton(
                              onPressed: () {
                                if (selectedProduct ==
                                    null) {
                                  _showDialogMessage(
                                    dialogContext,
                                    'Please select a product.',
                                  );
                                  return;
                                }

                                final quantity =
                                    double.tryParse(
                                          quantityController
                                              .text
                                              .trim(),
                                        ) ??
                                        0;

                                final rate =
                                    double.tryParse(
                                          rateController
                                              .text
                                              .trim(),
                                        ) ??
                                        0;

                                if (quantity <= 0) {
                                  _showDialogMessage(
                                    dialogContext,
                                    'Please enter a valid quantity.',
                                  );
                                  return;
                                }

                                if (rate < 0) {
                                  _showDialogMessage(
                                    dialogContext,
                                    'Please enter a valid rate.',
                                  );
                                  return;
                                }

                                Navigator.of(
                                  dialogContext,
                                ).pop(
                                  SampleRequestLineModel(
                                    product:
                                        selectedProduct,
                                    grade: selectedGrade,
                                    finish: selectedFinish,
                                    unit: selectedUnit,
                                    quantity: quantity,
                                    rate: rate,
                                    notes:
                                        notesController
                                            .text
                                            .trim(),
                                    isDryMix: isDryMix,
                                  ),
                                );
                              },
                              style:
                                  ElevatedButton.styleFrom(
                                backgroundColor:
                                    primaryColor,
                                foregroundColor:
                                    Colors.white,
                                padding:
                                    EdgeInsets.symmetric(
                                  horizontal:
                                      isMobile ? 18 : 22,
                                  vertical:
                                      isMobile ? 11 : 13,
                                ),
                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                    24,
                                  ),
                                ),
                              ),
                              child: Text(
                                existingLine == null
                                    ? 'Add Product'
                                    : 'Update',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    quantityController.dispose();
    rateController.dispose();
    notesController.dispose();

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      if (index != null &&
          index >= 0 &&
          index < _productLines.length) {
        _productLines[index] = result;
      } else {
        _productLines.add(result);
      }
    });
  }

  // ==========================================================
  // DIALOG MESSAGE
  // ==========================================================

  void _showDialogMessage(
    BuildContext dialogContext,
    String message,
  ) {
    ScaffoldMessenger.maybeOf(
      dialogContext,
    )
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ==========================================================
  // RESPONSIVE DIALOG ROW
  // ==========================================================

  Widget _responsiveDialogRow({
    required Widget first,
    required Widget second,
  }) {
    final width = MediaQuery.of(context).size.width;

    if (width < mobileBreakpoint) {
      return Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          first,

          const SizedBox(
            height: 14,
          ),

          second,
        ],
      );
    }

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Expanded(
          child: first,
        ),

        const SizedBox(
          width: 12,
        ),

        Expanded(
          child: second,
        ),
      ],
    );
  }

  // ==========================================================
  // VIEW PRODUCT
  // ==========================================================

  void _viewProduct(
    SampleRequestLineModel line,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final width =
            MediaQuery.of(dialogContext).size.width;

        return AlertDialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal:
                width < mobileBreakpoint ? 12 : 24,
            vertical: 24,
          ),

          title: const Text(
            'Product Details',
          ),

          content: SizedBox(
            width:
                width < mobileBreakpoint
                    ? width * 0.92
                    : 600,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  _detailRow(
                    'Product',
                    line.product?.productName ?? '-',
                  ),

                  _detailRow(
                    'Product ID',
                    line.product?.productId
                            .toString() ??
                        '-',
                  ),

                  _detailRow(
                    'Grade',
                    line.grade?.name ?? '-',
                  ),

                  _detailRow(
                    'Finish',
                    line.finish?.name ?? '-',
                  ),

                  _detailRow(
                    'Unit',
                    line.unit?.name ??
                        line.product?.uomCode ??
                        '-',
                  ),

                  _detailRow(
                    'Quantity',
                    _formatNumber(line.quantity),
                  ),

                  _detailRow(
                    'Rate',
                    _formatMoney(line.rate),
                  ),

                  _detailRow(
                    'Value',
                    _formatMoney(line.value),
                  ),

                  _detailRow(
                    'DryMix',
                    line.isDryMix ? 'Yes' : 'No',
                  ),

                  _detailRow(
                    'Notes',
                    line.notes.isEmpty
                        ? '-'
                        : line.notes,
                  ),
                ],
              ),
            ),
          ),

          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext),
              child: const Text(
                'Close',
              ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // DELETE PRODUCT
  // ==========================================================

  Future<void> _deleteProduct(
    int index,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Product',
          ),

          content: const Text(
            'Are you sure you want to remove this product?',
          ),

          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
                false,
              ),
              child: const Text(
                'Cancel',
              ),
            ),

            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
                true,
              ),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      setState(() {
        _productLines.removeAt(index);
      });
    }
  }

  // ==========================================================
  // BOTTOM NAVIGATION
  // ==========================================================

  Widget _buildBottomNavigation() {
    final width =
        MediaQuery.of(context).size.width;

    final isMobile =
        width < mobileBreakpoint;

    return Container(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 10 : 16,
        10,
        isMobile ? 10 : 16,
        12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: isMobile
          ? Row(
              children: [
                if (_currentTab > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousTab,
                      style:
                          OutlinedButton.styleFrom(
                        foregroundColor:
                            primaryColor,
                        side:
                            const BorderSide(
                          color: primaryColor,
                        ),
                        padding:
                            const EdgeInsets
                                .symmetric(
                          vertical: 12,
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        size: 18,
                      ),
                    ),
                  ),

                if (_currentTab > 0)
                  const SizedBox(width: 8),

                Expanded(
                  flex: 2,
                  child: _currentTab < 2
                      ? ElevatedButton(
                          onPressed: _nextTab,
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                primaryColor,
                            foregroundColor:
                                Colors.white,
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
                            'Next',
                          ),
                        )
                      : ElevatedButton(
                          onPressed:
                              _validateBeforeSave,
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                primaryColor,
                            foregroundColor:
                                Colors.white,
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
                            'Save Request',
                          ),
                        ),
                ),
              ],
            )
          : Row(
              children: [
                if (_currentTab > 0)
                  OutlinedButton.icon(
                    onPressed: _previousTab,
                    icon: const Icon(
                      Icons.arrow_back,
                      size: 18,
                    ),
                    label: const Text(
                      'Previous',
                    ),
                    style:
                        OutlinedButton.styleFrom(
                      foregroundColor:
                          primaryColor,
                      side:
                          const BorderSide(
                        color: primaryColor,
                      ),
                    ),
                  ),

                const Spacer(),

                if (_currentTab < 2)
                  ElevatedButton.icon(
                    onPressed: _nextTab,
                    icon: const Icon(
                      Icons.arrow_forward,
                      size: 18,
                    ),
                    label: const Text(
                      'Next',
                    ),
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          primaryColor,
                      foregroundColor:
                          Colors.white,
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed:
                        _validateBeforeSave,
                    icon: const Icon(
                      Icons.save_outlined,
                      size: 18,
                    ),
                    label: const Text(
                      'Save Request',
                    ),
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          primaryColor,
                      foregroundColor:
                          Colors.white,
                    ),
                  ),
              ],
            ),
    );
  }

  // ==========================================================
  // TAB NAVIGATION
  // ==========================================================

  void _previousTab() {
    if (_currentTab <= 0) {
      return;
    }

    _tabController.animateTo(
      _currentTab - 1,
    );
  }

 void _nextTab() {
  if (!_validateCurrentTab()) {
    return;
  }

  if (_currentTab >= 2) {
    return;
  }

  if (!mounted) {
    return;
  }

  _tabController.animateTo(
    _currentTab + 1,
  );
}

  // ==========================================================
  // VALIDATION
  // ==========================================================

  bool _validateCurrentTab() {
    if (_currentTab == 0) {
      if (_selectedFactory == null) {
        _showMessage(
          'Please select Factory.',
        );
        return false;
      }

      if (_selectedReason == null) {
        _showMessage(
          'Please select Reason.',
        );
        return false;
      }

      if (_selectedDeliveryMode == null) {
        _showMessage(
          'Please select Delivery Mode.',
        );
        return false;
      }

      if (_selectedRequestedBy == null) {
        _showMessage(
          'Please select Requested By.',
        );
        return false;
      }

      return true;
    }

    if (_currentTab == 1) {
      if (_selectedLedger == null) {
        _showMessage(
          'Please select Client / Ledger.',
        );
        return false;
      }

      if (_siteController.text.trim().isEmpty) {
        _showMessage(
          'Please enter Site.',
        );
        return false;
      }

      if (_addressController.text.trim().isEmpty) {
        _showMessage(
          'Please enter Delivery Address.',
        );
        return false;
      }

      return true;
    }

    if (_currentTab == 2) {
      if (_productLines.isEmpty) {
        _showMessage(
          'Please add at least one product.',
        );
        return false;
      }

      return true;
    }

    return true;
  }
Future<void> _validateBeforeSave() async {
  // Validate Information tab without changing tabs
  if (!_validateInformationTab()) {
    return;
  }

  // Validate Site Details tab without changing tabs
  if (!_validateSiteDetailsTab()) {
    return;
  }

  // Validate Products tab without changing tabs
  if (!_validateProductsTab()) {
    return;
  }

  // Only move to Products tab AFTER validation is complete.
  if (!mounted) return;

  _tabController.animateTo(2);

  // Give Flutter one frame to finish the tab transition/rebuild.
  await Future<void>.delayed(
    const Duration(milliseconds: 100),
  );

  if (!mounted) return;

  await _saveSampleRequest();
}

// ==========================================================
// VALIDATE INFORMATION TAB
// ==========================================================

bool _validateInformationTab() {
  if (_selectedFactory == null) {
    _showMessage(
      'Please select Factory.',
    );

    if (mounted) {
      _tabController.animateTo(0);
    }

    return false;
  }

  if (_selectedReason == null) {
    _showMessage(
      'Please select Reason.',
    );

    if (mounted) {
      _tabController.animateTo(0);
    }

    return false;
  }

  if (_selectedDeliveryMode == null) {
    _showMessage(
      'Please select Delivery Mode.',
    );

    if (mounted) {
      _tabController.animateTo(0);
    }

    return false;
  }

  if (_selectedRequestedBy == null) {
    _showMessage(
      'Please select Requested By.',
    );

    if (mounted) {
      _tabController.animateTo(0);
    }

    return false;
  }

  return true;
}


// ==========================================================
// VALIDATE SITE DETAILS TAB
// ==========================================================

bool _validateSiteDetailsTab() {
  if (_selectedLedger == null) {
    _showMessage(
      'Please select Client / Ledger.',
    );

    if (mounted) {
      _tabController.animateTo(1);
    }

    return false;
  }

  if (_siteController.text.trim().isEmpty) {
    _showMessage(
      'Please enter Site.',
    );

    if (mounted) {
      _tabController.animateTo(1);
    }

    return false;
  }

  if (_addressController.text.trim().isEmpty) {
    _showMessage(
      'Please enter Delivery Address.',
    );

    if (mounted) {
      _tabController.animateTo(1);
    }

    return false;
  }

  return true;
}


// ==========================================================
// VALIDATE PRODUCTS TAB
// ==========================================================

bool _validateProductsTab() {
  if (_productLines.isEmpty) {
    _showMessage(
      'Please add at least one product.',
    );

    if (mounted) {
      _tabController.animateTo(2);
    }

    return false;
  }

  return true;
}
// ==========================================================
// BUILD SAMPLE REQUEST POST BODY
// ==========================================================

Map<String, dynamic> _buildSampleRequestBody() {
  final details = _productLines.map((line) {
    return {
      'LocID': 0,
      'ID': 0,
      'SrNo': 0,

      'ProductID': _toInt(
        line.product?.productId,
      ),

      'ProductName':
          line.product?.productName ?? '',

      'IsDryMix':
          line.isDryMix,

      'GradeID': _toInt(
        line.grade?.id,
      ),

      'FinishID': _toInt(
        line.finish?.id,
      ),

      'Qty':
          line.quantity,

      'UoMCode':
          line.unit?.code ??
          line.product?.uomCode ??
          '',

      'Rate':
          line.rate,

      'Notes':
          line.notes.trim(),
    };
  }).toList();

  return {
    'UserID':
        widget.userId,

    'LocID':
        0,

    'ID':
        0,

    'FactoryID':
        _toInt(
          _selectedFactory?.id,
        ),

    'ReqTypeID':
        292,

    'VouDate':
        _dateController.text.trim(),

    'RequestByID':
        _toInt(
          _selectedRequestedBy?.id,
        ),

    'ReasonID':
        _toInt(
          _selectedReason?.id,
        ),

    'Client':
        _selectedLedger?.name ?? '',

    'Site':
        _siteController.text.trim(),

    'Reference':
        _referenceController.text.trim(),

    'DueDate':
        _dueDateController.text.trim().isEmpty
            ? '01/01/0001'
            : _dueDateController.text.trim(),

    'Remarks':
        '',

    'DeliveryMode':
        _selectedDeliveryMode?.name ?? '',

    'DeliveryAddress': {
      'Address1':
          _addressController.text.trim(),

      'Address2':
          '',

      'Address3':
          '',

      'ZipCode':
          '',

      'CityID':
          0,

      'StateID':
          0,

      'Country':
          'India',
    },

    'ContactNo':
        _contactController.text.trim(),

    'GSTNo':
        _gstController.text.trim(),

    'PANNo':
        _panController.text.trim(),

    'Details':
        details,
  };
}


// ==========================================================
// INTEGER HELPER
// ==========================================================

int _toInt(dynamic value) {
  if (value == null) {
    return 0;
  }

  if (value is int) {
    return value;
  }

  if (value is double) {
    return value.toInt();
  }

  return int.tryParse(
        value.toString(),
      ) ??
      0;
}


// ==========================================================
// SAVE SAMPLE REQUEST
// ==========================================================

Future<void> _saveSampleRequest() async {
  if (!mounted) {
    return;
  }

  final body = _buildSampleRequestBody();

  print('');
  print('================================================');
  print('SAMPLE REQUEST SAVE BODY');
  print('================================================');
  print(
    const JsonEncoder.withIndent('  ').convert(body),
  );
  print('================================================');
  print('');

  LoaderService.show(
    context,
    title: 'Saving Sample Request',
    subtitle: 'Please wait...',
  );

  try {
    final response = await ApiService.saveSampleRequest(
      userId: widget.userId,
      userPwd: widget.userpwd,
      
      body: body,
    );

    if (!mounted) {
      LoaderService.hide();
      return;
    }

    LoaderService.hide();

    print(
      'Sample Request save response: $response',
    );

    await Future<void>.delayed(
      const Duration(milliseconds: 50),
    );

    if (!mounted) {
      return;
    }

    
  } catch (e) {
    if (!mounted) {
      
      return;
    }

    

    LoaderService.hide();

    print(
      'Sample Request save failed: $e',
    );

    await Future<void>.delayed(
      const Duration(milliseconds: 50),
    );

    if (!mounted) {
      return;
    }

    _showMessage(
      e.toString().replaceFirst(
        'Exception: ',
        '',
      ),
    );
  }
}

// ==========================================================
// SUCCESS MESSAGE
// ==========================================================

void _showSuccessMessage(String message) {
  if (!mounted) {
    return;
  }

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) {
      return;
    }

    final messenger =
        ScaffoldMessenger.maybeOf(context);

    if (messenger == null) {
      return;
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(message),
              ),
            ],
          ),
          backgroundColor:
              Colors.green.shade700,
          behavior:
              SnackBarBehavior.floating,
          duration:
              const Duration(seconds: 3),
        ),
      );
  });
}

  // ==========================================================
  // DATE FIELD
  // ==========================================================

  Widget _dateField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      controller: controller,
      readOnly: true,

      onTap: () {
        _selectDate(controller);
      },

      decoration: _inputDecoration(
        label,
      ).copyWith(
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (controller.text.trim().isNotEmpty)
              IconButton(
                tooltip: 'Clear',
                icon: const Icon(
                  Icons.close,
                  size: 19,
                  color: mutedColor,
                ),
                onPressed: () {
                  setState(() {
                    controller.clear();
                  });
                },
              ),

            IconButton(
              tooltip: 'Select date',
              icon: const Icon(
                Icons.calendar_today_outlined,
                size: 19,
                color: mutedColor,
              ),
              onPressed: () {
                _selectDate(controller);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // SELECT DATE
  // ==========================================================

  Future<void> _selectDate(
    TextEditingController controller,
  ) async {
    final initialDate =
        _parseDate(controller.text) ??
            DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme:
                const ColorScheme.light(
              primary: primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selected != null && mounted) {
      setState(() {
        controller.text =
            DateFormat('dd/MM/yyyy').format(
          selected,
        );
      });
    }
  }

  DateTime? _parseDate(
    String value,
  ) {
    try {
      if (value.trim().isEmpty) {
        return null;
      }

      return DateFormat(
        'dd/MM/yyyy',
      ).parse(value);
    } catch (_) {
      return null;
    }
  }

  // ==========================================================
  // GENERIC DROPDOWN
  // ==========================================================

  Widget _dropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?> onChanged,
    bool searchable = false,
  }) {
    if (searchable) {
      return DropdownSearch<T>(
        selectedItem: value,

        items: (
          String filter,
          LoadProps? loadProps,
        ) async {
          final query =
              filter.trim().toLowerCase();

          if (query.isEmpty) {
            return items.take(100).toList();
          }

          return items
              .where(
                (item) => itemLabel(item)
                    .toLowerCase()
                    .contains(query),
              )
              .take(100)
              .toList();
        },

        itemAsString: itemLabel,

        compareFn: (a, b) =>
            itemLabel(a) == itemLabel(b),

        decoratorProps:
            DropDownDecoratorProps(
          decoration:
              _inputDecoration(label),
        ),

        popupProps:
            PopupProps.menu(
          fit: FlexFit.loose,

          menuProps:
              const MenuProps(
            backgroundColor:
                Colors.white,
            elevation: 8,
          ),

          showSearchBox: true,

          searchFieldProps:
              TextFieldProps(
            decoration:
                InputDecoration(
              hintText: 'Search...',

              prefixIcon:
                  const Icon(
                Icons.search,
                color: mutedColor,
              ),

              filled: true,
              fillColor: Colors.white,

              border:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(7),
                borderSide:
                    const BorderSide(
                  color: borderColor,
                ),
              ),

              enabledBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(7),
                borderSide:
                    const BorderSide(
                  color: borderColor,
                ),
              ),

              focusedBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(7),
                borderSide:
                    const BorderSide(
                  color: primaryColor,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),

        suffixProps:
            DropdownSuffixProps(
          clearButtonProps:
              ClearButtonProps(
            isVisible:
                value != null,

            icon:
                const Icon(
              Icons.close,
              size: 19,
              color: mutedColor,
            ),

            tooltip: 'Clear',

            padding:
                EdgeInsets.zero,
          ),

          dropdownButtonProps:
              DropdownButtonProps(
            isVisible: true,

            iconClosed:
                const Icon(
              Icons
                  .keyboard_arrow_down_rounded,
              color: primaryColor,
            ),

            iconOpened:
                const Icon(
              Icons
                  .keyboard_arrow_up_rounded,
              color: primaryColor,
            ),
          ),
        ),

        onChanged: onChanged,
      );
    }

    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,

      decoration:
          _inputDecoration(
        label,
      ).copyWith(
        suffixIcon: value != null
            ? IconButton(
                tooltip: 'Clear',
                icon: const Icon(
                  Icons.close,
                  size: 19,
                  color: mutedColor,
                ),
                onPressed: () {
                  onChanged(null);
                },
              )
            : const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: primaryColor,
              ),
      ),

      items: items
          .map(
            (item) =>
                DropdownMenuItem<T>(
              value: item,
              child: Text(
                itemLabel(item),
                overflow:
                    TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),

      onChanged: onChanged,
    );
  }

  // ==========================================================
  // DIALOG DROPDOWN
  // ==========================================================

  Widget _dialogDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,

      decoration:
          _inputDecoration(
        label,
      ).copyWith(
        suffixIcon: value != null
            ? IconButton(
                tooltip: 'Clear',
                icon: const Icon(
                  Icons.close,
                  size: 19,
                  color: mutedColor,
                ),
                onPressed: () {
                  onChanged(null);
                },
              )
            : const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: primaryColor,
              ),
      ),

      items: items
          .map(
            (item) =>
                DropdownMenuItem<T>(
              value: item,
              child: Text(
                itemLabel(item),
                overflow:
                    TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),

      onChanged: onChanged,
    );
  }

  // ==========================================================
  // TEXT FIELD
  // ==========================================================

  Widget _textField({
    required TextEditingController controller,
    required String label,
    bool enabled = true,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      keyboardType: keyboardType,

      decoration:
          _inputDecoration(
        label,
      ).copyWith(
        hintText: hint,
      ),
    );
  }

  // ==========================================================
  // DIALOG TEXT FIELD
  // ==========================================================

  Widget _dialogTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration:
          _inputDecoration(label),
    );
  }

  // ==========================================================
  // INPUT DECORATION
  // ==========================================================

  InputDecoration _inputDecoration(
    String label,
  ) {
    return InputDecoration(
      labelText: label,

      floatingLabelBehavior:
          FloatingLabelBehavior.auto,

      filled: true,

      fillColor: Colors.white,

      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 13,
      ),

      border:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(7),
        borderSide:
            const BorderSide(
          color: borderColor,
        ),
      ),

      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(7),
        borderSide:
            const BorderSide(
          color: borderColor,
        ),
      ),

      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(7),
        borderSide:
            const BorderSide(
          color: primaryColor,
          width: 1.5,
        ),
      ),

      disabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(7),
        borderSide:
            const BorderSide(
          color: borderColor,
        ),
      ),
    );
  }

  // ==========================================================
  // LAYOUT HELPERS
  // ==========================================================

  Widget _scrollableContent({
    required List<Widget> children,
  }) {
    final width =
        MediaQuery.of(context).size.width;

    final isMobile =
        width < mobileBreakpoint;

    final horizontalPadding =
        isMobile
            ? 10.0
            : width < tabletBreakpoint
                ? 16.0
                : 20.0;

    return LayoutBuilder(
      builder: (
        context,
        constraints,
      ) {
        return SingleChildScrollView(
          padding:
              EdgeInsets.all(
            horizontalPadding,
          ),

          child: Center(
            child:
                ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 1200,
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .stretch,
                children:
                    children,
              ),
            ),
          ),
        );
      },
    );
  }

  // ==========================================================
  // CARD
  // ==========================================================

  Widget _card({
    required List<Widget> children,
  }) {
    final width =
        MediaQuery.of(context).size.width;

    final isMobile =
        width < mobileBreakpoint;

    return Container(
      padding:
          EdgeInsets.all(
        isMobile ? 12 : 18,
      ),

      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(10),
        border:
            Border.all(
          color: borderColor,
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children:
            children,
      ),
    );
  }

  // ==========================================================
  // SECTION TITLE
  // ==========================================================

  Widget _sectionTitle(
    String title,
    IconData icon,
  ) {
    final width =
        MediaQuery.of(context).size.width;

    final isMobile =
        width < mobileBreakpoint;

    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 12,
      ),

      child: Row(
        children: [
          Icon(
            icon,
            color: primaryColor,
            size:
                isMobile ? 19 : 21,
          ),

          const SizedBox(
            width: 8,
          ),

          Expanded(
            child: Text(
              title,
              style:
                  TextStyle(
                fontSize:
                    isMobile
                        ? 15
                        : 17,
                fontWeight:
                    FontWeight.w700,
                color:
                    primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // RESPONSIVE ROW
  // ==========================================================

  Widget _responsiveRow({
    required Widget first,
    required Widget second,
  }) {
    final width =
        MediaQuery.of(context).size.width;

    if (width < mobileBreakpoint) {
      return Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          first,

          const SizedBox(
            height: 14,
          ),

          second,

          const SizedBox(
            height: 14,
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Expanded(
          child: first,
        ),

        const SizedBox(
          width: 14,
        ),

        Expanded(
          child: second,
        ),
      ],
    );
  }

  // ==========================================================
  // PRODUCT INFO
  // ==========================================================

  Widget _productInfo(
    String label,
    String value,
  ) {
    final width =
        MediaQuery.of(context).size.width;

    final itemWidth =
        width < mobileBreakpoint
            ? 105.0
            : 130.0;

    return SizedBox(
      width: itemWidth,

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style:
                const TextStyle(
              fontSize: 11,
              color: mutedColor,
            ),
          ),

          const SizedBox(
            height: 3,
          ),

          Text(
            value,
            style:
                const TextStyle(
              fontSize: 13,
              fontWeight:
                  FontWeight.w600,
              color: textColor,
            ),
            overflow:
                TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // DETAIL ROW
  // ==========================================================

  Widget _detailRow(
    String label,
    String value,
  ) {
    final width =
        MediaQuery.of(context).size.width;

    final labelWidth =
        width < mobileBreakpoint
            ? 90.0
            : 110.0;

    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 12,
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          SizedBox(
            width: labelWidth,

            child: Text(
              label,
              style:
                  const TextStyle(
                color: mutedColor,
                fontWeight:
                    FontWeight.w500,
              ),
            ),
          ),

          Expanded(
            child: Text(
              value,
              style:
                  const TextStyle(
                color: textColor,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // FORMATTING
  // ==========================================================

  String _formatNumber(
    double value,
  ) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value
        .toStringAsFixed(2)
        .replaceFirst(
          RegExp(r'\.?0+$'),
          '',
        );
  }

  String _formatMoney(
    double value,
  ) {
    return value.toStringAsFixed(2);
  }

  // ==========================================================
  // MESSAGE
  // ==========================================================

 void _showMessage(String message) {
  if (!mounted) {
    return;
  }

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) {
      return;
    }

    final messenger =
        ScaffoldMessenger.maybeOf(context);

    if (messenger == null) {
      return;
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
  });
}
}