import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'src/background/price_refresh_worker.dart';
import 'src/data/fuel_price_repository.dart';
import 'src/data/petrolimex_price_service.dart';
import 'src/data/theme_settings_store.dart';
import 'src/data/widget_data_sync.dart';
import 'src/models/fuel_price_snapshot.dart';
import 'src/ui/settings_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi_VN');
  await PriceRefreshWorker.initialize();
  final themeController = ThemeController();
  await themeController.load();
  runApp(OilPriceTrackingApp(themeController: themeController));
}

class OilPriceTrackingApp extends StatelessWidget {
  const OilPriceTrackingApp({super.key, required this.themeController});

  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        return MaterialApp(
          title: 'Giá xăng dầu Petrolimex',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0A54A8),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFF6F8FB),
            appBarTheme: const AppBarTheme(
              centerTitle: false,
              backgroundColor: Color(0xFF0A54A8),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Color(0xFFE1E7F0)),
              ),
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFFD948),
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF101418),
            appBarTheme: const AppBarTheme(
              centerTitle: false,
              backgroundColor: Color(0xFF141A22),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            cardTheme: CardThemeData(
              color: const Color(0xFF171D25),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Color(0xFF2B3542)),
              ),
            ),
            dividerColor: const Color(0xFF2B3542),
          ),
          themeMode: themeController.themeMode,
          home: PriceHomePage(themeController: themeController),
        );
      },
    );
  }
}

class PriceHomePage extends StatefulWidget {
  const PriceHomePage({super.key, required this.themeController});

  final ThemeController themeController;

  @override
  State<PriceHomePage> createState() => _PriceHomePageState();
}

class _PriceHomePageState extends State<PriceHomePage> {
  late final FuelPriceRepository _repository;
  FuelPriceSnapshot? _snapshot;
  String? _errorMessage;
  DateTime? _lastErrorAt;
  bool _isLoading = true;
  bool _isRefreshing = false;

  final _currencyFormat = NumberFormat.decimalPattern('vi_VN');
  final _timeFormat = DateFormat('HH:mm, dd/MM/yyyy', 'vi_VN');

  @override
  void initState() {
    super.initState();
    _repository = FuelPriceRepository(
      service: PetrolimexPriceService(),
      widgetSync: const WidgetDataSync(),
    );
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final cached = await _repository.loadCachedSnapshot();
    final error = await _repository.loadLastError();
    if (!mounted) {
      return;
    }
    setState(() {
      _snapshot = cached;
      _errorMessage = error?.message;
      _lastErrorAt = error?.occurredAt;
      _isLoading = cached == null;
    });
    await _refresh(showSpinner: cached == null);
  }

  Future<void> _refresh({bool showSpinner = true}) async {
    if (_isRefreshing) {
      return;
    }
    setState(() {
      _isRefreshing = true;
      if (showSpinner) {
        _isLoading = true;
      }
    });

    final result = await _repository.refresh();
    if (!mounted) {
      return;
    }

    setState(() {
      _isRefreshing = false;
      _isLoading = false;
      if (result.snapshot != null) {
        _snapshot = result.snapshot;
      }
      _errorMessage = result.error?.message;
      _lastErrorAt = result.error?.occurredAt;
    });
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giá bán lẻ xăng dầu'),
        actions: [
          IconButton(
            tooltip: 'Cài đặt',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SettingsPage(
                    currentSnapshot: _snapshot,
                    themeController: widget.themeController,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.settings_outlined),
          ),
          IconButton(
            tooltip: 'Cập nhật',
            onPressed: _isRefreshing ? null : () => _refresh(),
            icon: _isRefreshing
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _refresh(showSpinner: false),
          child: _isLoading && snapshot == null
              ? const _LoadingView()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  children: [
                    _HeaderCard(
                      snapshot: snapshot,
                      errorMessage: _errorMessage,
                      lastErrorAt: _lastErrorAt,
                      timeFormat: _timeFormat,
                    ),
                    const SizedBox(height: 12),
                    if (snapshot == null)
                      _EmptyState(onRetry: () => _refresh())
                    else
                      _PriceTable(
                        snapshot: snapshot,
                        currencyFormat: _currencyFormat,
                      ),
                    const SizedBox(height: 12),
                    const _SourceNote(),
                  ],
                ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.snapshot,
    required this.errorMessage,
    required this.lastErrorAt,
    required this.timeFormat,
  });

  final FuelPriceSnapshot? snapshot;
  final String? errorMessage;
  final DateTime? lastErrorAt;
  final DateFormat timeFormat;

  @override
  Widget build(BuildContext context) {
    final updatedAt = snapshot?.displayUpdatedAt;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD948),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.local_gas_station,
                    color: Color(0xFF0A54A8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Petrolimex',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        updatedAt == null
                            ? 'Chưa có dữ liệu cập nhật'
                            : 'Cập nhật lúc ${timeFormat.format(updatedAt.toLocal())}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 12),
              _StatusBanner(
                message: lastErrorAt == null
                    ? errorMessage!
                    : '$errorMessage (${timeFormat.format(lastErrorAt!.toLocal())})',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5E6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFC46B)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: Color(0xFF9A5B00)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF744400)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceTable extends StatelessWidget {
  const _PriceTable({required this.snapshot, required this.currencyFormat});

  final FuelPriceSnapshot snapshot;
  final NumberFormat currencyFormat;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingTextStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: const Color(0xFF0A54A8),
              fontWeight: FontWeight.w700,
            ),
            columns: const [
              DataColumn(label: Text('Sản phẩm')),
              DataColumn(label: Text('Vùng 1'), numeric: true),
              DataColumn(label: Text('Vùng 2'), numeric: true),
            ],
            rows: snapshot.products
                .map(
                  (price) => DataRow(
                    cells: [
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 180),
                          child: Text(price.title),
                        ),
                      ),
                      DataCell(Text(currencyFormat.format(price.zone1Price))),
                      DataCell(Text(currencyFormat.format(price.zone2Price))),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _SourceNote extends StatelessWidget {
  const _SourceNote();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Đơn vị: VND. Dữ liệu lấy từ mục Giá bán lẻ xăng dầu trên Petrolimex.',
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: const Color(0xFF667085)),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: const [
        SizedBox(height: 160),
        Center(child: CircularProgressIndicator()),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_outlined, size: 42),
            const SizedBox(height: 12),
            const Text('Chưa tải được bảng giá'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
