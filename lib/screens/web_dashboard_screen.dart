import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';

class WebDashboardScreen extends StatefulWidget {
  final String serverUrl;
  final String apiKey;
  const WebDashboardScreen({
    super.key,
    required this.serverUrl,
    required this.apiKey,
  });

  @override
  State<WebDashboardScreen> createState() => _WebDashboardScreenState();
}

class _WebDashboardScreenState extends State<WebDashboardScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String _appVersion = "v1.0.7";

  @override
  void initState() {
    super.initState();
    _initLibVersion();

    String finalUrl = widget.serverUrl.trim();
    if (!finalUrl.startsWith("http://") && !finalUrl.startsWith("https://")) {
      finalUrl = "http://$finalUrl";
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint("Web Error: ${error.description}");
          },
        ),
      )
      ..loadRequest(Uri.parse(finalUrl));
  }

  Future<void> _initLibVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _appVersion = "v${packageInfo.version}");
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF161616),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "DASHBOARD WEB",
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF00E676),
                letterSpacing: 1.5,
              ),
            ),
            Text(
              widget.serverUrl,
              style: const TextStyle(fontSize: 10, color: Colors.white38),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: () => _controller.reload(),
          ),
          IconButton(
            icon: const Icon(
              Icons.dashboard_customize_outlined,
              color: Color(0xFF00E676),
            ),
            tooltip: "Ver Dashboard Nativo",
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => DashboardScreen(
                    serverUrl: widget.serverUrl,
                    apiKey: widget.apiKey,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white38),
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (c) => const LoginScreen()),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF00E676)),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.05)),
          ),
        ),
        child: Row(
          children: [
            Text(
              "PING MASTER $_appVersion",
              style: const TextStyle(
                color: Colors.white24,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.public_rounded,
              color: Color(0xFF00E676),
              size: 10,
            ),
            const SizedBox(width: 6),
            const Text(
              "MODO NAVEGADOR ATIVO",
              style: TextStyle(
                color: Color(0xFF00E676),
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
