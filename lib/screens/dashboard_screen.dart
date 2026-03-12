import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/service_ping.dart';
import '../widgets/service_card.dart';
import '../widgets/summary_card.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String serverUrl;
  final String apiKey;
  const DashboardScreen({
    super.key,
    required this.serverUrl,
    required this.apiKey,
  });

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
  String _appVersion = 'v1.0.0';
  bool _isUsingDemoData = false;
  String _lastError = '';
  bool _isFetching = false;
  String _systemName = 'Ping Master Pro';

  @override
  void initState() {
    super.initState();
    _currentServerUrl = widget.serverUrl;
    _loadSavedSystemName();
    _fetchData();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _fetchData();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 2), _checkUpdate);
    });
  }

  Future<void> _checkUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      if (mounted) setState(() => _appVersion = 'v$currentVersion');

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final response = await http.get(
        Uri.parse(
          'https://raw.githubusercontent.com/devairfernandes/ping_master/main/version.json?t=$timestamp',
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
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

  Future<void> _loadSavedSystemName() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('system_name');
    if (savedName != null && mounted) {
      setState(() => _systemName = savedName);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (_isFetching) return;
    _isFetching = true;
    try {
      String cleanUrl = _currentServerUrl.trim();
      if (!cleanUrl.startsWith('http')) cleanUrl = 'http://$cleanUrl';
      final response = await http
          .get(
            Uri.parse('$cleanUrl/api/v1/status'),
            headers: {'X-API-Key': widget.apiKey},
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);
        List<dynamic> servicesData = [];

        if (decoded is Map) {
          servicesData = decoded['services'] ?? [];
          _isMonitoring = decoded['monitoring_active'] ?? _isMonitoring;
        } else if (decoded is List) {
          servicesData = decoded;
        }

        if (mounted) {
          setState(() {
            _services = servicesData
                .map((m) => ServicePing.fromJson(m))
                .toList();
            _isMonitoring = decoded['monitoring_active'] ?? _isMonitoring;
            _systemName = decoded['system_name'] ?? _systemName;
            _saveSystemName(_systemName);
            _isLoading = false;
            _isUsingDemoData = false;
            _lastError = '';
            _lastGlobalUpdate = DateFormat('HH:mm:ss').format(DateTime.now());
          });
        }
      } else {
        _useFallback('Erro ${response.statusCode}');
      }
    } catch (e) {
      _useFallback(e.toString());
    } finally {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  Future<void> _saveSystemName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('system_name', name);
  }

  void _useFallback([String? error]) {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _isUsingDemoData = true;
        _lastError = error ?? 'Erro desconhecido';
        _lastGlobalUpdate = DateFormat('HH:mm:ss').format(DateTime.now());
      });
    }
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
                if (_isUsingDemoData)
                  SliverToBoxAdapter(child: _buildErrorBanner()),
                SliverToBoxAdapter(child: _buildActionRow()),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  sliver: SliverToBoxAdapter(child: _buildSummaryGrid()),
                ),
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
                      (context, index) =>
                          ServiceCard(service: _services[index]),
                      childCount: _services.length,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'Ping Master $_appVersion',
                        style: const TextStyle(color: Colors.white10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MODO DEMONSTRAÇÃO (OFFLINE)',
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _lastError,
            style: const TextStyle(color: Colors.white70, fontSize: 9),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildCompactAppBar() {
    return AppBar(
      backgroundColor: Colors.black,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _systemName.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF00E676),
            ),
          ),
          Text(
            'Última atualização: $_lastGlobalUpdate',
            style: const TextStyle(fontSize: 9, color: Colors.white38),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _showEditServerDialog,
          icon: const Icon(Icons.settings_outlined, color: Color(0xFF00E676)),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (c) => const LoginScreen()),
          ),
          icon: const Icon(Icons.logout),
        ),
      ],
    );
  }

  Widget _buildActionRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: Icon(
                _isMonitoring ? Icons.pause_rounded : Icons.play_arrow_rounded,
              ),
              label: Text(_isMonitoring ? 'PARAR' : 'INICIAR'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isMonitoring
                    ? Colors.red.withOpacity(0.8)
                    : const Color(0xFF00E676).withOpacity(0.8),
                foregroundColor: Colors.white,
              ),
              onPressed: _toggleMonitoring,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('ATUALIZAR'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.withOpacity(0.8),
                foregroundColor: Colors.white,
              ),
              onPressed: _fetchData,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleMonitoring() async {
    final bool targetState = !_isMonitoring;
    final String endpoint = targetState
        ? 'monitoring/start'
        : 'monitoring/stop';

    try {
      String cleanUrl = _currentServerUrl.trim();
      if (!cleanUrl.startsWith('http')) cleanUrl = 'http://$cleanUrl';

      final response = await http.post(
        Uri.parse('$cleanUrl/api/v1/$endpoint'),
        headers: {'X-API-Key': widget.apiKey},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() => _isMonitoring = targetState);
          _fetchData(); // Atualiza a lista imediatamente
        }
      }
    } catch (e) {
      debugPrint('Erro ao alterar monitoramento: $e');
    }
  }

  Widget _buildSummaryGrid() {
    final onlineCount = _services.where((s) => s.currentPing > 0).length;
    final offlineCount = _services.where((s) => s.currentPing == 0).length;

    double avgPing = 0;
    if (_services.any((s) => s.currentPing > 0)) {
      final activeServices = _services.where((s) => s.currentPing > 0);
      avgPing =
          activeServices.map((s) => s.currentPing).reduce((a, b) => a + b) /
          activeServices.length;
    }

    return Row(
      children: [
        SummaryCard(
          title: 'ONLINE',
          value: '$onlineCount',
          icon: Icons.router,
          color: const Color(0xFF00E676),
        ),
        const SizedBox(width: 10),
        SummaryCard(
          title: 'MÉDIO',
          value: '${avgPing.toStringAsFixed(0)}ms',
          icon: Icons.bolt,
          color: Colors.amber,
        ),
        const SizedBox(width: 10),
        SummaryCard(
          title: 'OFFLINE',
          value: '$offlineCount',
          icon: Icons.error_outline_rounded,
          color: Colors.redAccent,
        ),
      ],
    );
  }
}
