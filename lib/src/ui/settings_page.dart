import 'package:flutter/material.dart';

import '../data/fuel_price_repository.dart';
import '../data/petrolimex_price_service.dart';
import '../data/theme_settings_store.dart';
import '../data/widget_data_sync.dart';
import '../data/widget_settings_store.dart';
import '../models/fuel_price.dart';
import '../models/fuel_price_snapshot.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    this.currentSnapshot,
    required this.themeController,
  });

  final FuelPriceSnapshot? currentSnapshot;
  final ThemeController themeController;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final FuelPriceRepository _repository;
  final _settingsStore = const WidgetSettingsStore();

  FuelPriceSnapshot? _snapshot;
  Set<String> _selectedProductIds = {};
  late ThemeMode _themeMode;
  bool _showZone1 = true;
  bool _showZone2 = true;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _repository = FuelPriceRepository(
      service: PetrolimexPriceService(),
      widgetSync: const WidgetDataSync(),
    );
    _themeMode = widget.themeController.themeMode;
    _load();
  }

  Future<void> _load() async {
    final settings = await _settingsStore.load();
    final cachedSnapshot =
        widget.currentSnapshot ?? await _repository.loadCachedSnapshot();
    if (!mounted) {
      return;
    }

    setState(() {
      _snapshot = cachedSnapshot;
      _selectedProductIds = _resolveInitialSelectedIds(
        cachedSnapshot,
        settings.selectedProductIds,
      );
      _showZone1 = settings.showZone1;
      _showZone2 = settings.showZone2;
      _isLoading = false;
    });
  }

  Set<String> _resolveInitialSelectedIds(
    FuelPriceSnapshot? snapshot,
    List<String> savedIds,
  ) {
    if (savedIds.isNotEmpty) {
      return savedIds.toSet();
    }
    return (snapshot?.products ?? const <FuelPrice>[])
        .take(WidgetDataSync.maxWidgetProducts)
        .map((product) => product.id)
        .toSet();
  }

  Future<void> _save() async {
    if (_selectedProductIds.isEmpty) {
      _showSnackBar('Chọn ít nhất một sản phẩm để hiển thị trên widget.');
      return;
    }
    if (!_showZone1 && !_showZone2) {
      _showSnackBar('Chọn ít nhất một vùng giá để hiển thị trên widget.');
      return;
    }

    setState(() => _isSaving = true);
    await _settingsStore.save(
      WidgetSettings(
        selectedProductIds: _selectedProductIds.toList(),
        showZone1: _showZone1,
        showZone2: _showZone2,
      ),
    );
    await _repository.updateWidgetFromCache();
    if (!mounted) {
      return;
    }
    setState(() => _isSaving = false);
    _showSnackBar('Đã lưu cài đặt widget.');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _toggleProduct(FuelPrice product, bool selected) {
    final next = Set<String>.from(_selectedProductIds);
    if (selected) {
      if (next.length >= WidgetDataSync.maxWidgetProducts &&
          !next.contains(product.id)) {
        _showSnackBar('Widget hiện hỗ trợ tối đa 6 sản phẩm.');
        return;
      }
      next.add(product.id);
    } else {
      next.remove(product.id);
    }
    setState(() => _selectedProductIds = next);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  _ThemeSettingsCard(
                    themeMode: _themeMode,
                    onChanged: (themeMode) async {
                      setState(() => _themeMode = themeMode);
                      await widget.themeController.setThemeMode(themeMode);
                    },
                  ),
                  const SizedBox(height: 12),
                  _WidgetSettingsCard(
                    products: _snapshot?.products ?? const [],
                    selectedProductIds: _selectedProductIds,
                    showZone1: _showZone1,
                    showZone2: _showZone2,
                    isSaving: _isSaving,
                    onProductChanged: _toggleProduct,
                    onZone1Changed: (value) =>
                        setState(() => _showZone1 = value),
                    onZone2Changed: (value) =>
                        setState(() => _showZone2 = value),
                    onSave: _save,
                  ),
                ],
              ),
      ),
    );
  }
}

class _ThemeSettingsCard extends StatelessWidget {
  const _ThemeSettingsCard({required this.themeMode, required this.onChanged});

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.palette_outlined, color: Color(0xFF0A54A8)),
                const SizedBox(width: 10),
                Text(
                  'Giao diện',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Chọn chế độ sáng, tối hoặc tự động theo hệ thống.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF667085)),
            ),
            const SizedBox(height: 8),
            RadioGroup<ThemeMode>(
              groupValue: themeMode,
              onChanged: (value) {
                if (value != null) {
                  onChanged(value);
                }
              },
              child: const Column(
                children: [
                  RadioListTile<ThemeMode>(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Theo hệ thống'),
                    value: ThemeMode.system,
                  ),
                  RadioListTile<ThemeMode>(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Sáng'),
                    value: ThemeMode.light,
                  ),
                  RadioListTile<ThemeMode>(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Tối'),
                    value: ThemeMode.dark,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WidgetSettingsCard extends StatelessWidget {
  const _WidgetSettingsCard({
    required this.products,
    required this.selectedProductIds,
    required this.showZone1,
    required this.showZone2,
    required this.isSaving,
    required this.onProductChanged,
    required this.onZone1Changed,
    required this.onZone2Changed,
    required this.onSave,
  });

  final List<FuelPrice> products;
  final Set<String> selectedProductIds;
  final bool showZone1;
  final bool showZone2;
  final bool isSaving;
  final void Function(FuelPrice product, bool selected) onProductChanged;
  final ValueChanged<bool> onZone1Changed;
  final ValueChanged<bool> onZone2Changed;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.widgets_outlined, color: Color(0xFF0A54A8)),
                const SizedBox(width: 10),
                Text('Widget', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Chọn tối đa 6 sản phẩm và vùng giá hiển thị trên home widget.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF667085)),
            ),
            const SizedBox(height: 18),
            Text(
              'Sản phẩm hiển thị',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            if (products.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Chưa có dữ liệu sản phẩm. Hãy quay lại màn hình chính để cập nhật bảng giá trước.',
                ),
              )
            else
              ...products.map(
                (product) => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(product.title),
                  value: selectedProductIds.contains(product.id),
                  onChanged: (value) =>
                      onProductChanged(product, value ?? false),
                ),
              ),
            const Divider(height: 28),
            Text(
              'Vùng hiển thị',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Vùng 1'),
              value: showZone1,
              onChanged: (value) => onZone1Changed(value ?? false),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Vùng 2'),
              value: showZone2,
              onChanged: (value) => onZone2Changed(value ?? false),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isSaving ? null : onSave,
                icon: isSaving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Lưu cài đặt widget'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
