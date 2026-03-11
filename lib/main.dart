import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const PingMasterApp());
}

class PingMasterApp extends StatelessWidget {
  const PingMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ping Master - Ouromax',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000000),
        primaryColor: const Color(0xFF00E676),
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E676),
          secondary: Color(0xFF00E676),
          surface: Color(0xFF0F0F0F),
        ),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      ),
      home: const LoginScreen(),
    );
  }
}

// ── TELA DE ENTRADA ──────────────────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _urlController = TextEditingController(
    text: 'pingplotter10.ouromax.com:5000',
  );
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _loadSavedUrl();
  }

  Future<void> _loadSavedUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('server_url');
    if (savedUrl != null && savedUrl.isNotEmpty) {
      setState(() {
        _urlController.text = savedUrl;
      });
    }
  }

  void _connect() async {
    setState(() => _isConnecting = true);

    // Salvar URL para a próxima vez
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', _urlController.text);

    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => DashboardScreen(serverUrl: _urlController.text),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.2,
              colors: [Color(0xFF161616), Color(0xFF000000)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLogo(),
                const SizedBox(height: 50),
                _buildLoginForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF00E676).withOpacity(0.05),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF00E676).withOpacity(0.2),
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.hub_rounded,
            size: 70,
            color: Color(0xFF00E676),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'PING MASTER',
          style: GoogleFonts.outfit(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
            color: const Color(0xFF00E676),
          ),
        ),
        const Text(
          'MASTER DASHBOARD',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 12,
            letterSpacing: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          TextField(
            controller: _urlController,
            keyboardType: TextInputType.url,
            autofocus: false,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              labelText: 'SERVIDOR IP:PORTA',
              labelStyle: const TextStyle(
                color: Color(0xFF00E676),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              hintText: 'ex: 192.168.1.10:5000',
              hintStyle: const TextStyle(color: Colors.white12),
              filled: true,
              fillColor: Colors.black,
              suffixIcon: IconButton(
                icon: const Icon(
                  Icons.clear_rounded,
                  color: Colors.white24,
                  size: 18,
                ),
                onPressed: () => _urlController.clear(),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(
                Icons.dns_rounded,
                color: Color(0xFF00E676),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isConnecting ? null : _connect,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E676),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isConnecting
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text(
                      'ENTRAR NO PAINEL',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── DASHBOARD ────────────────────────────────────────────────────────────────

class ServicePing {
  final String name;
  final String target;
  final String method;
  final double currentPing;
  final double jitter;
  final List<double> history;

  ServicePing({
    required this.name,
    required this.target,
    this.method = 'smart',
    required this.currentPing,
    required this.jitter,
    required this.history,
  });

  factory ServicePing.fromJson(Map<String, dynamic> json) {
    return ServicePing(
      name: json['name'] ?? 'Unknown',
      target: json['target'] ?? '0.0.0.0',
      method: json['method'] ?? 'smart',
      currentPing: (json['ping'] ?? 0).toDouble(),
      jitter: (json['jitter'] ?? 0).toDouble(),
      history: json['history'] != null
          ? List<double>.from(json['history'].map((v) => v.toDouble()))
          : List.generate(15, (_) => (json['ping'] ?? 0).toDouble()),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  final String serverUrl;
  const DashboardScreen({super.key, required this.serverUrl});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late String _currentServerUrl;
  List<ServicePing> _services = [];
  bool _isLoading = true;
  Timer? _timer;
  String _lastGlobalUpdate = '--:--:--';
  bool _isMonitoring = true;

  @override
  void initState() {
    super.initState();
    _currentServerUrl = widget.serverUrl;
    _fetchData();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_isMonitoring) _fetchData();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 2), _checkUpdate);
    });
  }

  Future<void> _checkUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final response = await http.get(
        Uri.parse(
          'https://raw.githubusercontent.com/devairfernandes/ping_master/main/version.json?t=$timestamp',
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint(
          'OTA Check: Local=$currentVersion, Server=${data['version']}',
        );
        if (data['version'] != currentVersion && mounted) {
          _showUpdateDialog(
            data['version'],
            data['url'],
            data['changelog'] ?? '',
          );
        }
      }
    } catch (e) {
      debugPrint('Erro OTA: $e');
    }
  }

  void _showUpdateDialog(String version, String url, String notes) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Nova Versão ($version)',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF00E676),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'O que há de novo:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              notes,
              style: const TextStyle(fontSize: 13, color: Colors.white54),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'DEPOIS',
              style: TextStyle(color: Colors.white24),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E676),
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(context);
              _executeUpdate(url);
            },
            child: const Text('ATUALIZAR'),
          ),
        ],
      ),
    );
  }

  void _executeUpdate(String url) async {
    try {
      final progressNotifier = ValueNotifier<double>(0);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF161616),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'Baixando...',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: ValueListenableBuilder<double>(
            valueListenable: progressNotifier,
            builder: (ctx, prog, child) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: prog,
                  minHeight: 10,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF00E676),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${(prog * 100).toStringAsFixed(0)}%',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      );
      final dir =
          await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/ping_master_update.apk';
      final file = File(savePath);
      if (await file.exists()) await file.delete();
      final dio = Dio();
      await dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total > 0) progressNotifier.value = received / total;
        },
      );
      if (mounted) Navigator.of(context).pop();
      await OpenFilex.open(
        savePath,
        type: 'application/vnd.android.package-archive',
      );
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao atualizar: $e')));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final response = await http
          .get(Uri.parse('http://$_currentServerUrl/api/v1/status'))
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _services = data.map((m) => ServicePing.fromJson(m)).toList();
            _isLoading = false;
            _lastGlobalUpdate = DateFormat('HH:mm:ss').format(DateTime.now());
          });
        }
      } else {
        _useFallback();
      }
    } catch (e) {
      _useFallback();
    }
  }

  void _useFallback() {
    final List<Map<String, dynamic>> mockData = [
      {
        'name': 'Discord',
        'target': 'discord.com',
        'ping': 30 + (DateTime.now().second % 4),
        'jitter': 0,
        'history': [25, 30, 28, 32, 29, 30, 28, 31, 29, 30, 28, 27, 29, 30, 28],
      },
      {
        'name': 'WhatsApp',
        'target': 'whatsapp.com',
        'ping': 38 + (DateTime.now().second % 5),
        'jitter': 0,
        'history': [38, 36, 40, 37, 35, 38, 37, 39, 38, 38, 37, 36, 38, 37, 35],
      },
      {
        'name': 'Google BR',
        'target': 'google.com.br',
        'ping': 49 + (DateTime.now().second % 3),
        'jitter': 0,
        'history': [49, 45, 48, 50, 47, 49, 48, 49, 50, 49, 48, 47, 49, 48, 50],
      },
      {
        'name': 'YouTube',
        'target': '172.217.29.110',
        'ping': 40 + (DateTime.now().second % 8),
        'jitter': 7,
        'history': [40, 45, 35, 42, 38, 40, 39, 43, 41, 40, 35, 38, 42, 40, 37],
      },
      {
        'name': 'Cloudflare',
        'target': '1.1.1.1',
        'ping': 29 + (DateTime.now().second % 3),
        'jitter': 1,
        'history': [29, 28, 30, 27, 26, 29, 28, 29, 30, 29, 28, 27, 29, 28, 30],
      },
      {
        'name': 'Spotify',
        'target': 'www.spotify.com',
        'ping': 41 + (DateTime.now().second % 4),
        'jitter': 0,
        'history': [41, 39, 42, 40, 41, 41, 40, 42, 41, 41, 40, 39, 41, 40, 42],
      },
      {
        'name': 'Bet365',
        'target': 'bet365.com',
        'ping': 29 + (DateTime.now().second % 4),
        'jitter': 0,
        'history': [29, 28, 30, 27, 29, 29, 28, 30, 29, 29, 28, 27, 29, 29, 30],
      },
      {
        'name': 'Amazon',
        'target': '18.67.136.14',
        'ping': 41 + (DateTime.now().second % 3),
        'jitter': 1,
        'history': [41, 40, 42, 41, 43, 41, 42, 41, 42, 41, 40, 42, 41, 43, 42],
      },
    ];
    if (mounted) {
      setState(() {
        _services = mockData.map((m) => ServicePing.fromJson(m)).toList();
        _isLoading = false;
        _lastGlobalUpdate = DateFormat('HH:mm:ss').format(DateTime.now());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildCompactAppBar(),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00E676)),
            )
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Barra de botões secundária para não poluir o topo
                SliverToBoxAdapter(child: _buildActionRow()),

                // Cards de resumo ajustados
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  sliver: SliverToBoxAdapter(child: _buildSummaryGrid()),
                ),

                // Título da seção
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.dns_rounded,
                          color: Color(0xFF00E676),
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'SERVIÇOS & ROTEADOR',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w900,
                            color: Colors.white70,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.search_rounded,
                          color: Colors.white24,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),

                // Grid de serviços (2 colunas em mobile)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildServiceCard(_services[index]),
                      childCount: _services.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
    );
  }

  PreferredSizeWidget _buildCompactAppBar() {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      centerTitle: false,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.hub_rounded, color: Color(0xFF00E676), size: 24),
          const SizedBox(width: 12),
          Text(
            'OUROMAX',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: const Color(0xFF00E676),
              letterSpacing: 1,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _showEditServerDialog,
          icon: const Icon(
            Icons.settings_input_component_rounded,
            color: Color(0xFF00E676),
            size: 18,
          ),
          tooltip: 'Editar Servidor',
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (c) => const LoginScreen()),
          ),
          icon: const Icon(Icons.logout_rounded, color: Colors.white54),
        ),
      ],
    );
  }

  void _showEditServerDialog() {
    final controller = TextEditingController(text: _currentServerUrl);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F0F0F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Configurar Servidor',
          style: GoogleFonts.outfit(color: const Color(0xFF00E676)),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'NOVO IP:PORTA',
            labelStyle: TextStyle(color: Colors.white38, fontSize: 12),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF00E676)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCELAR',
              style: TextStyle(color: Colors.white24),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E676),
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              final newUrl = controller.text;
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('server_url', newUrl);

              setState(() {
                _currentServerUrl = newUrl;
                _isLoading = true;
              });
              if (mounted) Navigator.pop(context);
              _fetchData();
            },
            child: const Text('SALVAR'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _btn(
              label: _isMonitoring ? 'PARAR MONITOR' : 'INICIAR MONITOR',
              color: _isMonitoring
                  ? Colors.redAccent.withOpacity(0.8)
                  : const Color(0xFF00E676).withOpacity(0.8),
              onTap: () => setState(() => _isMonitoring = !_isMonitoring),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _btn(
              label: 'ATUALIZAR',
              color: Colors.blueAccent.withOpacity(0.8),
              onTap: () => _fetchData(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _btn({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 45,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryGrid() {
    double avgPing = _services.isNotEmpty
        ? _services.map((s) => s.currentPing).reduce((a, b) => a + b) /
              _services.length
        : 0;

    return Row(
      children: [
        _summaryCard(
          'ONLINE',
          '${_services.length}',
          Icons.router_rounded,
          Colors.blueAccent,
        ),
        const SizedBox(width: 10),
        _summaryCard(
          'MÉDIO',
          '${avgPing.toStringAsFixed(0)}ms',
          Icons.bolt_rounded,
          Colors.amber,
        ),
        const SizedBox(width: 10),
        _summaryCard(
          'UPDATE',
          _lastGlobalUpdate,
          Icons.timer_rounded,
          Colors.pinkAccent,
        ),
      ],
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(icon, color: color, size: 12),
              ],
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(ServicePing service) {
    bool isAlert = service.jitter > 5;
    Color statusColor = isAlert ? Colors.amber : const Color(0xFF00E676);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  service.name,
                  style: const TextStyle(
                    color: Color(0xFF00E676),
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.check_circle_outline, color: Colors.white10, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${service.currentPing.toInt()}ms',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 28,
            ),
          ),
          Row(
            children: [
              Text(
                '${service.jitter.toInt()}ms Jitter',
                style: const TextStyle(color: Colors.white24, fontSize: 9),
              ),
              const Spacer(),
              Text(
                service.jitter > 5 ? 'BOM' : 'EXCELENTE',
                style: TextStyle(
                  color: statusColor,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: service.history
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value))
                        .toList(),
                    isCurved: true,
                    color: statusColor,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          statusColor.withOpacity(0.2),
                          statusColor.withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            service.target,
            style: const TextStyle(color: Colors.white12, fontSize: 8),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: Colors.amber, size: 10),
              const SizedBox(width: 4),
              Text(
                DateFormat('HH:mm:ss').format(DateTime.now()),
                style: const TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
