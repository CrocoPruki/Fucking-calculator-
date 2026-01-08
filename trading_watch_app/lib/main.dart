import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
  int _selectedIndex = 0;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  void _initializeNotifications() {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
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
      0,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          RiskCalculator(onCalculate: (result) {
            _showNotification('Risk Calculated', 'Result: $result');
          }),
          BitcoinChart(),
          AlertSettings(onSetAlert: (price) {
            _showNotification('Alert Set', 'Alert for BTC at $price');
          }),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate),
            label: 'Calc',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Chart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
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
  final TextEditingController _stopController = TextEditingController();
  String _result = '';

  void _calculate() {
    double capital = double.tryParse(_capitalController.text) ?? 0;
    double risk = double.tryParse(_riskController.text) ?? 0;
    double stop = double.tryParse(_stopController.text) ?? 0;

    if (capital > 0 && risk > 0 && stop > 0) {
      List<double> leverages = [1, 1.8, 2, 3, 5, 8, 10, 20, 50, 100];
      double bestLeverage = 1;
      double minDiff = double.infinity;

      for (double l in leverages) {
        double actual = l * stop;
        double diff = (actual - risk).abs();
        if (diff < minDiff) {
          minDiff = diff;
          bestLeverage = l;
        }
      }

      double riskDollar = (bestLeverage * stop / 100) * capital;
      _result = 'Leverage: ${bestLeverage}x\nRisk: ${(bestLeverage * stop).toStringAsFixed(2)}%\nRisk \$: ${riskDollar.toStringAsFixed(2)}';
    } else {
      _result = 'Enter valid values';
    }

    setState(() {});
    widget.onCalculate(_result);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          TextField(
            controller: _capitalController,
            decoration: const InputDecoration(labelText: 'Capital \$'),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: _riskController,
            decoration: const InputDecoration(labelText: 'Risk %'),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: _stopController,
            decoration: const InputDecoration(labelText: 'Stop Loss %'),
            keyboardType: TextInputType.number,
          ),
          ElevatedButton(onPressed: _calculate, child: const Text('Calculate')),
          Text(_result),
        ],
      ),
    );
  }
}

class BitcoinChart extends StatefulWidget {
  const BitcoinChart({super.key});

  @override
  State<BitcoinChart> createState() => _BitcoinChartState();
}

class _BitcoinChartState extends State<BitcoinChart> {
  List<FlSpot> _spots = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final response = await http.get(Uri.parse(
        'https://api.coingecko.com/api/v3/coins/bitcoin/market_chart?vs_currency=usd&days=1&interval=hourly'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final prices = data['prices'] as List;
      setState(() {
        _spots = prices
            .asMap()
            .entries
            .map((e) => FlSpot(e.key.toDouble(), e.value[1].toDouble()))
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: _spots,
              isCurved: true,
              color: Colors.blue,
              barWidth: 2,
            ),
          ],
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}

class AlertSettings extends StatefulWidget {
  final Function(double) onSetAlert;

  const AlertSettings({super.key, required this.onSetAlert});

  @override
  State<AlertSettings> createState() => _AlertSettingsState();
}

class _AlertSettingsState extends State<AlertSettings> {
  final TextEditingController _priceController = TextEditingController();

  void _setAlert() {
    double price = double.tryParse(_priceController.text) ?? 0;
    if (price > 0) {
      widget.onSetAlert(price);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          TextField(
            controller: _priceController,
            decoration: const InputDecoration(labelText: 'Alert Price \$'),
            keyboardType: TextInputType.number,
          ),
          ElevatedButton(onPressed: _setAlert, child: const Text('Set Alert')),
        ],
      ),
    );
  }
}
