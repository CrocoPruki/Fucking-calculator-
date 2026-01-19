import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

const String kBuildTag = 'wear-ui+calc+chartfix+alerts (2026-01-19)';

// Default market for both chart and alerts.
// Bitget USDC perpetual uses symbols like BTCPERP (not BTCUSDC).
const String kBitgetSymbol = 'BTCPERP';
const String kBitgetProductType = 'usdc-futures';
const String kDisplaySymbol = 'BTC-PERP (USDC)';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trading Watch',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const WatchApp(),
    );
  }
}

class WatchApp extends StatefulWidget {
  const WatchApp({super.key});

  @override
  State<WatchApp> createState() => _WatchAppState();
}

class _WatchAppState extends State<WatchApp> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  int _notificationId = 0;

  Timer? _alertPollTimer;
  double? _alertPrice;
  bool _alertTriggerAbove = true;

  @override
  void initState() {
    super.initState();
    // Avoid crashing the whole app if notifications init fails on some Wear/Android builds.
    Future.microtask(() async {
      try {
        await _initializeNotifications();
      } catch (_) {
        // Silent: app should still run without notifications.
      }
    });
    _startAlertPolling();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    try {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (_) {
      // Some devices/OS versions may throw here.
    }
  }

  void _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'trading_channel',
      'Trading Alerts',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      _notificationId++,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  @override
  void dispose() {
    _alertPollTimer?.cancel();
    super.dispose();
  }

  void _setAlert(double price, {required bool triggerAbove}) {
    setState(() {
      _alertPrice = price;
      _alertTriggerAbove = triggerAbove;
    });
  }

  void _startAlertPolling() {
    _alertPollTimer?.cancel();
    _alertPollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _pollAlert();
    });
  }

  Future<void> _pollAlert() async {
    final alertPrice = _alertPrice;
    if (alertPrice == null) return;

    try {
      final uri = Uri.parse(
        'https://api.bitget.com/api/v2/mix/market/ticker?symbol=$kBitgetSymbol&productType=$kBitgetProductType',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return;
      final data = json.decode(response.body);
      if (data is! Map || data['code'] != '00000') return;
      final list = data['data'];
      if (list is! List || list.isEmpty) return;
      final lastPr = list.first['lastPr'];
      final current = double.tryParse(lastPr.toString());
      if (current == null) return;

      final triggered = _alertTriggerAbove ? current >= alertPrice : current <= alertPrice;
      if (triggered) {
        setState(() {
          _alertPrice = null;
        });
        _showNotification(
          '$kDisplaySymbol Alert Hit',
          '$kDisplaySymbol price: \$${current.toStringAsFixed(2)} (target: \$${alertPrice.toStringAsFixed(2)})',
        );
      }
    } catch (_) {
      // silent: network errors are expected sometimes
    }
  }

  void _clearAlert() {
    setState(() {
      _alertPrice = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _WatchHomeMenu(
          onOpenCalculator: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => _SimplePage(
                  title: 'Calculator',
                  child: RiskCalculator(onCalculate: (result) {
                    _showNotification('Risk Calculated', 'Result: $result');
                  }),
                ),
              ),
            );
          },
          onOpenChart: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const _SimplePage(
                  title: 'Chart',
                  child: BitcoinChart(),
                ),
              ),
            );
          },
          onOpenAlerts: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => _SimplePage(
                  title: 'Alerts',
                  child: AlertSettings(
                    onSetAlert: (price, triggerAbove) {
                      _setAlert(price, triggerAbove: triggerAbove);
                      _showNotification(
                        'Alert Set',
                        'BTC alert ${triggerAbove ? 'above' : 'below'} \$${price.toStringAsFixed(2)}',
                      );
                    },
                    onClearAlert: _clearAlert,
                    getCurrentAlert: () => _alertPrice,
                  ),
                ),
              ),
            );
          },
          currentAlert: _alertPrice,
        ),
      ),
    );
  }
}

class _SimplePage extends StatelessWidget {
  final String title;
  final Widget child;

  const _SimplePage({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: child,
    );
  }
}

class _WatchHomeMenu extends StatelessWidget {
  final VoidCallback onOpenCalculator;
  final VoidCallback onOpenChart;
  final VoidCallback onOpenAlerts;
  final double? currentAlert;

  const _WatchHomeMenu({
    required this.onOpenCalculator,
    required this.onOpenChart,
    required this.onOpenAlerts,
    required this.currentAlert,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final buttonHeight = (width * 0.23).clamp(56.0, 84.0);

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            kBuildTag,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          _MenuButton(
            icon: Icons.calculate,
            label: 'Calculator',
            height: buttonHeight,
            onTap: onOpenCalculator,
          ),
          const SizedBox(height: 10),
          _MenuButton(
            icon: Icons.show_chart,
            label: 'Chart',
            height: buttonHeight,
            onTap: onOpenChart,
          ),
          const SizedBox(height: 10),
          _MenuButton(
            icon: Icons.notifications,
            label: 'Alerts',
            height: buttonHeight,
            subtitle: currentAlert == null
                ? 'No active alert'
                : 'Active: \$${currentAlert!.toStringAsFixed(2)}',
            height2: 64,
            onTap: onOpenAlerts,
          ),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final double height;
  final double? height2;
  final VoidCallback onTap;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.height,
    required this.onTap,
    this.subtitle,
    this.height2,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      height: height,
      child: FilledButton.tonal(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: colorScheme.onSecondaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSecondaryContainer.withOpacity(0.8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RiskCalculator extends StatefulWidget {
  final Function(String) onCalculate;

  const RiskCalculator({super.key, required this.onCalculate});

  @override
  State<RiskCalculator> createState() => _RiskCalculatorState();
}

class _RiskCalculatorState extends State<RiskCalculator> {
  final TextEditingController _capitalController = TextEditingController();
  final TextEditingController _riskController = TextEditingController();
  final TextEditingController _entryController = TextEditingController();
  final TextEditingController _stopLossPriceController = TextEditingController();
  String _result = '';

  void _calculate() {
    double capital = double.tryParse(_capitalController.text) ?? 0;
    double risk = double.tryParse(_riskController.text) ?? 0;
    double entry = double.tryParse(_entryController.text) ?? 0;
    double stopLoss = double.tryParse(_stopLossPriceController.text) ?? 0;

    if (capital > 0 && risk > 0 && entry > 0 && stopLoss > 0) {
      final riskDollars = capital * (risk / 100.0);
      final perUnitRisk = (entry - stopLoss).abs();

      if (perUnitRisk == 0) {
        _result = 'Entry i Stop Loss nie mogą być takie same';
      } else {
        final quantity = riskDollars / perUnitRisk;
        final positionValue = quantity * entry;
        final stopDistancePct = (perUnitRisk / entry) * 100.0;

        _result =
            'Risk: ${risk.toStringAsFixed(2)}% (\$${riskDollars.toStringAsFixed(2)})\n'
            'Entry: \$${entry.toStringAsFixed(2)}\n'
            'Stop Loss: \$${stopLoss.toStringAsFixed(2)} (${stopDistancePct.toStringAsFixed(2)}%)\n'
            'Position size: ${quantity.toStringAsFixed(6)} BTC\n'
            'Position value: \$${positionValue.toStringAsFixed(2)}';
      }
    } else {
      _result = 'Enter valid values';
    }

    setState(() {});
    widget.onCalculate(_result);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Position Calculator',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _capitalController,
              decoration: const InputDecoration(
                labelText: 'Capital \$',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _riskController,
              decoration: const InputDecoration(
                labelText: 'Risk %',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _entryController,
              decoration: const InputDecoration(
                labelText: 'Entry Price \$',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _stopLossPriceController,
              decoration: const InputDecoration(
                labelText: 'Stop Loss Price \$',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _calculate,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 45),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('CALCULATE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            if (_result.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                ),
                child: Text(
                  _result,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CandleData {
  final double x;
  final double open;
  final double high;
  final double low;
  final double close;
  final int timestamp;

  CandleData(this.x, this.open, this.high, this.low, this.close, this.timestamp);
}

class BitcoinChart extends StatefulWidget {
  const BitcoinChart({super.key});

  @override
  State<BitcoinChart> createState() => _BitcoinChartState();
}

class _BitcoinChartState extends State<BitcoinChart> {
  List<CandleData> _candles = [];
  bool _loading = true;
  double _currentPrice = 0;
  double? _touchedPrice;
  List<double> _ema20 = [];
  int _minutesToClose = 0;
  Timer? _countdownTimer;
  Timer? _refreshTimer;
  String? _errorMessage;

  // Timeframes you care about.
  static const String _tf1D = '1D';
  static const String _tf1H = '1H';
  static const String _tf5m = '5m';
  String _granularity = _tf1H;

  static const String _apiKey = String.fromEnvironment('BITGET_API_KEY', defaultValue: '');
  static const String _apiSecret = String.fromEnvironment('BITGET_API_SECRET', defaultValue: '');
  static const String _apiPassphrase = String.fromEnvironment('BITGET_API_PASSPHRASE', defaultValue: '');

  @override
  void initState() {
    super.initState();
    _fetchBitgetData();
    _startCountdownTimer();
    _startAutoRefresh();
  }
  
  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_autoRefreshPeriod(), (_) {
      if (!mounted) return;
      _fetchBitgetData();
    });
  }

  Duration _autoRefreshPeriod() {
    if (_candles.isEmpty) return const Duration(seconds: 10);
    switch (_granularity) {
      case _tf1D:
        return const Duration(seconds: 60);
      case _tf5m:
      case _tf1H:
      default:
        return const Duration(seconds: 15);
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (mounted) {
        _updateCountdown();
      }
    });
    _updateCountdown();
  }

  void _updateCountdown() {
    final now = DateTime.now().toUtc();
    final minuteInHour = now.minute;
    setState(() {
      if (_granularity == _tf5m) {
        final mod = minuteInHour % 5;
        _minutesToClose = (4 - mod).clamp(0, 4);
      } else if (_granularity == _tf1D) {
        // Minutes to next UTC day boundary.
        final minutesToday = now.hour * 60 + now.minute;
        _minutesToClose = (1439 - minutesToday).clamp(0, 1439);
      } else {
        // 1H
        _minutesToClose = 59 - minuteInHour;
      }
    });
  }

  List<double> _calculateEMA20(List<CandleData> candles) {
    if (candles.length < 20) return [];
    
    List<double> ema = [];
    double multiplier = 2.0 / (20 + 1);
    
    // Calculate SMA for first 20 periods
    double sum = 0;
    for (int i = 0; i < 20; i++) {
      sum += candles[i].close;
    }
    double sma = sum / 20;
    ema.add(sma);
    
    // Calculate EMA for remaining periods
    for (int i = 20; i < candles.length; i++) {
      double emaValue = (candles[i].close - ema.last) * multiplier + ema.last;
      ema.add(emaValue);
    }
    
    return ema;
  }

  Future<void> _fetchBitgetData() async {
    final endpoint =
        'https://api.bitget.com/api/v2/mix/market/candles?symbol=$kBitgetSymbol&granularity=$_granularity&limit=32&productType=$kBitgetProductType';
    final uri = Uri.parse(endpoint);

    try {
      print('Fetching Bitget data...');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Response data code: ${data['code']}');
        
        if (data['code'] == '00000' && data['data'] != null) {
          final List<dynamic> candles = data['data'];
          print('Received ${candles.length} candles');
          
          if (mounted) {
            setState(() {
              // Bitget sometimes returns candles newest-first; sometimes oldest-first.
              // Sort by timestamp to keep the trend direction correct.
              final parsed = <CandleData>[];
              for (final row in candles) {
                if (row is! List || row.length < 5) continue;
                parsed.add(
                  CandleData(
                    0,
                    double.parse(row[1].toString()),
                    double.parse(row[2].toString()),
                    double.parse(row[3].toString()),
                    double.parse(row[4].toString()),
                    int.parse(row[0].toString()),
                  ),
                );
              }
              parsed.sort((a, b) => a.timestamp.compareTo(b.timestamp));

              _candles = List.generate(parsed.length, (i) {
                final c = parsed[i];
                return CandleData(
                  i.toDouble(),
                  c.open,
                  c.high,
                  c.low,
                  c.close,
                  c.timestamp,
                );
              });
              
              // Pobierz bieżącą cenę (ostatnia cena close)
              if (_candles.isNotEmpty) {
                _currentPrice = _candles.last.close;
              }
              
              // Oblicz 20 EMA
              _ema20 = _calculateEMA20(_candles);
              
              _loading = false;
              _errorMessage = null;
              _updateCountdown();
            });
            print('Chart updated with real data');
          }
        } else {
          print('API returned error code or no data');
          if (mounted) {
            setState(() {
              _loading = false;
              _errorMessage = 'API Error: ${data['msg'] ?? 'Invalid response'}';
            });
          }
        }
      } else {
        print('HTTP error ${response.statusCode}');
        if (mounted) {
          setState(() {
            _loading = false;
            _errorMessage = 'Connection Error: HTTP ${response.statusCode}';
          });
        }
      }
    } catch (e) {
      print('Error fetching data: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = 'Connection Error: ${e.toString()}';
        });
      }

      // Fallback data to avoid blank chart when API is flaky.
      if (_candles.isEmpty) {
        _loadSampleData();
      }
    }
  }

  void _setTimeframe(String granularity) {
    if (_granularity == granularity) return;
    setState(() {
      _granularity = granularity;
      _loading = true;
      _errorMessage = null;
    });
    _updateCountdown();
    _startAutoRefresh();
    _fetchBitgetData();
  }

  void _loadSampleData() {
    print('Loading sample data...');
    if (!mounted) {
      print('Widget not mounted, skipping sample data');
      return;
    }
    
    setState(() {
      final basePrice = 104000.0;
      _candles = List.generate(32, (i) {
        final variance = (i % 5 - 2) * 500;
        final open = basePrice + variance;
        final close = open + ((i % 3 - 1) * 300);
        final high = [open, close].reduce((a, b) => a > b ? a : b) + 200;
        final low = [open, close].reduce((a, b) => a < b ? a : b) - 200;
        return CandleData(i.toDouble(), open, high, low, close, DateTime.now().millisecondsSinceEpoch - (32 - i) * 3600000);
      });
      
      _currentPrice = _candles.last.close;
      _ema20 = _calculateEMA20(_candles);
      _loading = false;
      _errorMessage = 'Using demo data (API unavailable)';
      _updateCountdown();
    });
    print('Sample data loaded: ${_candles.length} candles');
  }



  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_candles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Icon(Icons.cloud_off, size: 36, color: Colors.orange),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Connecting...',
              style: const TextStyle(fontSize: 14, color: Colors.orange),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Auto-retry in 10s',
              style: TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SafeArea(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Wykres (pełny rozmiar)
          GestureDetector(
            onPanUpdate: (details) {
              final box = context.findRenderObject() as RenderBox?;
              if (box == null) return;

              final maxPrice = _candles.map((c) => c.high).reduce((a, b) => a > b ? a : b);
              final minPrice = _candles.map((c) => c.low).reduce((a, b) => a < b ? a : b);
              final priceRange = (maxPrice - minPrice) == 0 ? 1.0 : (maxPrice - minPrice);

              final height = box.size.height;
              final yPos = details.localPosition.dy.clamp(0.0, height);
              final price = maxPrice - (yPos / height) * priceRange;

              setState(() {
                _touchedPrice = price;
              });
            },
            onPanEnd: (_) {
              setState(() {
                _touchedPrice = null;
              });
            },
            child: CustomPaint(
              painter: CandlestickPainter(
                _candles,
                _ema20,
                _touchedPrice,
                _minutesToClose,
              ),
              child: const SizedBox.expand(),
            ),
          ),

          // Mała cena na górze
          Positioned(
            top: 16,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '\$${_currentPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Timeframe toggle
          Positioned(
            top: 42,
            left: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _TfChip(
                    label: '1D',
                    selected: _granularity == _tf1D,
                    onTap: () => _setTimeframe(_tf1D),
                  ),
                  const SizedBox(width: 4),
                  _TfChip(
                    label: '1H',
                    selected: _granularity == _tf1H,
                    onTap: () => _setTimeframe(_tf1H),
                  ),
                  const SizedBox(width: 4),
                  _TfChip(
                    label: '5m',
                    selected: _granularity == _tf5m,
                    onTap: () => _setTimeframe(_tf5m),
                  ),
                ],
              ),
            ),
          ),

          // Status/error info
          if (_errorMessage != null)
            Positioned(
              top: 16,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CandlestickPainter extends CustomPainter {
  final List<CandleData> candles;
  final List<double> ema20;
  final double? touchedPrice;
  final int minutesToClose;
  
  CandlestickPainter(this.candles, this.ema20, this.touchedPrice, this.minutesToClose);

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    double maxPrice = candles.map((c) => c.high).reduce((a, b) => a > b ? a : b);
    double minPrice = candles.map((c) => c.low).reduce((a, b) => a < b ? a : b);
    double priceRange = maxPrice - minPrice;
    if (priceRange == 0) priceRange = 1;

    // Szerokość dla 36 świec (32 świece + 4 puste spoty jako margines)
    const double totalCandleSpots = 36;
    double spacing = size.width / totalCandleSpots;
    double candleWidth = spacing * 0.7;

    // Narysuj linię poziomą dla dotkniętej ceny
    if (touchedPrice != null) {
      Paint linePaint = Paint()
        ..color = Colors.orange.withOpacity(0.7)
        ..strokeWidth = 1.5;
      
      double lineY = size.height - ((touchedPrice! - minPrice) / priceRange * size.height);
      _drawDashedLine(canvas, Offset(0, lineY), Offset(size.width, lineY), linePaint);
      
      // Pokaż cenę na linii
      TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: '\$${touchedPrice!.toStringAsFixed(2)}',
          style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(size.width - textPainter.width - 4, lineY - 12));
    }

    // Narysuj świeczki
    for (int i = 0; i < candles.length; i++) {
      CandleData candle = candles[i];
      double x = i * spacing + spacing / 2;

      double openY = size.height - ((candle.open - minPrice) / priceRange * size.height);
      double closeY = size.height - ((candle.close - minPrice) / priceRange * size.height);
      double highY = size.height - ((candle.high - minPrice) / priceRange * size.height);
      double lowY = size.height - ((candle.low - minPrice) / priceRange * size.height);

      bool isGreen = candle.close >= candle.open;
      Color color = isGreen ? Colors.green : Colors.red;

      // Draw high-low line (wick)
      Paint wickPaint = Paint()
        ..color = color
        ..strokeWidth = 1.5;
      canvas.drawLine(Offset(x, highY), Offset(x, lowY), wickPaint);

      // Draw candle body
      Paint bodyPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      double top = isGreen ? closeY : openY;
      double bottom = isGreen ? openY : closeY;
      double bodyHeight = (bottom - top).abs().clamp(1.0, size.height);

      canvas.drawRect(
        Rect.fromLTWH(x - candleWidth / 2, top, candleWidth, bodyHeight),
        bodyPaint,
      );
      
      // Rysuj countdown tylko na ostatniej świecy
      if (i == candles.length - 1) {
        TextPainter countdownPainter = TextPainter(
          text: TextSpan(
            text: minutesToClose.toString(),
            style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold),
          ),
          textDirection: TextDirection.ltr,
        );
        countdownPainter.layout();
        countdownPainter.paint(canvas, Offset(x - countdownPainter.width / 2, bottom + 4));
      }
    }
    
    // Rysuj 20 EMA jako kropki/diamenty
    if (ema20.isNotEmpty) {
      Paint emaPaint = Paint()
        ..color = Colors.blue.withOpacity(0.8)
        ..style = PaintingStyle.fill;
      
      for (int i = 0; i < ema20.length; i++) {
        int candleIndex = i + (candles.length - ema20.length);
        if (candleIndex >= 0 && candleIndex < candles.length) {
          double x = candleIndex * spacing + spacing / 2;
          double emaY = size.height - ((ema20[i] - minPrice) / priceRange * size.height);
          
          // Rysuj diament
          Path diamondPath = Path();
          const double diamondSize = 2.5;
          diamondPath.moveTo(x, emaY - diamondSize);
          diamondPath.lineTo(x + diamondSize, emaY);
          diamondPath.lineTo(x, emaY + diamondSize);
          diamondPath.lineTo(x - diamondSize, emaY);
          diamondPath.close();
          canvas.drawPath(diamondPath, emaPaint);
        }
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const double dashWidth = 6;
    const double dashSpace = 4;

    final totalDistance = (end - start).distance;
    if (totalDistance == 0) return;

    final direction = (end - start) / totalDistance;
    double distance = 0;

    while (distance < totalDistance) {
      final currentStart = start + direction * distance;
      final segmentEnd = (distance + dashWidth).clamp(0, totalDistance).toDouble();
      final currentEnd = start + direction * segmentEnd;
      canvas.drawLine(currentStart, currentEnd, paint);
      distance += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class _TfChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TfChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withOpacity(0.95) : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: selected ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }
}

class AlertSettings extends StatefulWidget {
  final void Function(double price, bool triggerAbove) onSetAlert;
  final VoidCallback onClearAlert;
  final double? Function() getCurrentAlert;

  const AlertSettings({
    super.key,
    required this.onSetAlert,
    required this.onClearAlert,
    required this.getCurrentAlert,
  });

  @override
  State<AlertSettings> createState() => _AlertSettingsState();
}

class _AlertSettingsState extends State<AlertSettings> {
  final TextEditingController _priceController = TextEditingController();
  bool _triggerAbove = true;

  void _setAlert() {
    double price = double.tryParse(_priceController.text) ?? 0;
    if (price > 0) {
      widget.onSetAlert(price, _triggerAbove);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Price Alerts',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Alert Price \$',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('Above'),
                  selected: _triggerAbove,
                  onSelected: (_) {
                    setState(() {
                      _triggerAbove = true;
                    });
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Below'),
                  selected: !_triggerAbove,
                  onSelected: (_) {
                    setState(() {
                      _triggerAbove = false;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Builder(
              builder: (context) {
                final current = widget.getCurrentAlert();
                if (current == null) return const SizedBox.shrink();
                return Column(
                  children: [
                    Text(
                      'Active alert: \$${current.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 12, color: Colors.green),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: widget.onClearAlert,
                      child: const Text('CLEAR ALERT'),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _setAlert,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 45),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('SET ALERT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
