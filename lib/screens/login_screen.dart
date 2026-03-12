import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _urlController = TextEditingController(
    text: '0.0.0.0:5000',
  );
  final TextEditingController _apiKeyController = TextEditingController();
  bool _isConnecting = false;
  List<Map<String, String>> _recentServers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // Carregar URL atual
    final savedUrl = prefs.getString('server_url');
    if (savedUrl != null && savedUrl.isNotEmpty) {
      setState(() {
        _urlController.text = savedUrl;
      });
    }

    // Carregar API Key atual
    final savedKey = prefs.getString('api_key');
    if (savedKey != null && savedKey.isNotEmpty) {
      setState(() {
        _apiKeyController.text = savedKey;
      });
    }

    // Carregar servidores recentes
    final List<String> recentList =
        prefs.getStringList('recent_servers_data') ?? [];
    setState(() {
      _recentServers = recentList
          .map((s) => Map<String, String>.from(json.decode(s)))
          .toList();
    });
  }

  Future<void> _saveServer(String url, String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', url);
    await prefs.setString('api_key', apiKey);

    List<String> currentList = prefs.getStringList('recent_servers_data') ?? [];

    // Remover se já existe (para reordenar)
    currentList.removeWhere((s) => json.decode(s)['url'] == url);

    // Adicionar no topo
    final serverData = json.encode({'url': url, 'apiKey': apiKey});
    currentList.insert(0, serverData);

    // Manter apenas os 5 últimos
    if (currentList.length > 5) currentList = currentList.sublist(0, 5);
    await prefs.setStringList('recent_servers_data', currentList);
  }

  void _removeServer(String url) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> currentList = prefs.getStringList('recent_servers_data') ?? [];
    currentList.removeWhere((s) => json.decode(s)['url'] == url);
    await prefs.setStringList('recent_servers_data', currentList);
    setState(() {
      _recentServers = currentList
          .map((s) => Map<String, String>.from(json.decode(s)))
          .toList();
    });
  }

  void _connect([String? directUrl, String? directKey]) async {
    final urlToConnect = directUrl ?? _urlController.text;
    final keyToConnect = directKey ?? _apiKeyController.text;

    if (urlToConnect.isEmpty) return;
    if (keyToConnect.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, informe a Chave API')),
      );
      return;
    }

    setState(() => _isConnecting = true);

    await _saveServer(urlToConnect, keyToConnect);

    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) =>
              DashboardScreen(serverUrl: urlToConnect, apiKey: keyToConnect),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [Color(0xFF161616), Color(0xFF000000)],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 60),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLogo(),
                const SizedBox(height: 50),
                _buildLoginForm(),
                if (_recentServers.isNotEmpty) ...[
                  const SizedBox(height: 40),
                  _buildRecentSection(),
                ],
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
        Text(
          'MASTER CONNECT',
          style: GoogleFonts.outfit(
            color: Colors.white38,
            fontSize: 12,
            letterSpacing: 4,
            fontWeight: FontWeight.bold,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ENDEREÇO DO SERVIDOR',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _urlController,
            keyboardType: TextInputType.url,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'ex: 192.168.1.10:5000',
              hintStyle: const TextStyle(color: Colors.white12),
              filled: true,
              fillColor: Colors.black,
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
          const SizedBox(height: 20),
          const Text(
            'CHAVE API',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _apiKeyController,
            obscureText: true,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'PM-XXXX-XXXX-XXXX',
              hintStyle: const TextStyle(color: Colors.white12),
              filled: true,
              fillColor: Colors.black,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(
                Icons.vpn_key_rounded,
                color: Color(0xFF00E676),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isConnecting ? null : () => _connect(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E676),
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isConnecting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 3,
                      ),
                    )
                  : const Text(
                      'CONECTAR AGORA',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSection() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.history_rounded,
                color: Colors.white24,
                size: 14,
              ),
              const SizedBox(width: 8),
              Text(
                'CONEXÕES RECENTES',
                style: GoogleFonts.outfit(
                  color: Colors.white24,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ..._recentServers.map(
            (server) => _buildRecentItem(server['url']!, server['apiKey']!),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentItem(String url, String apiKey) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.02)),
      ),
      child: ListTile(
        onTap: () => _connect(url, apiKey),
        dense: true,
        leading: const Icon(
          Icons.link_rounded,
          color: Color(0xFF00E676),
          size: 20,
        ),
        title: Text(
          url,
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(
            Icons.close_rounded,
            color: Colors.white12,
            size: 16,
          ),
          onPressed: () => _removeServer(url),
        ),
      ),
    );
  }
}
