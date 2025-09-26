import 'package:crisp_chat/crisp_chat.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Crisp Chat WebView Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String websiteID =
      "07387b65-0e31-4cb7-bb3a-509170f52720"; // 👈 put real Crisp ID
  String? sessionId;

  @override
  void initState() {
    super.initState();
    _initCrispSession();
  }

  Future<void> _initCrispSession() async {
    String? existing = await FlutterCrispChat.getSessionIdentifier();

    if (existing == null) {
      existing = "custom-session-${DateTime.now().millisecondsSinceEpoch}";
      FlutterCrispChat.setSessionString(
        key: "session_id",
        value: existing,
      );
    }

    setState(() {
      sessionId = existing;
    });

    debugPrint("🟢 Crisp Session Initialized: $sessionId");
  }

  void _openCrispWebView() {
    if (sessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Session not ready yet")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CrispWebViewPage(
          sessionId: sessionId!,
          websiteId: websiteID,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Crisp Chat Example")),
      body: Center(
        child: ElevatedButton(
          onPressed: _openCrispWebView,
          child: const Text("Open Crisp in WebView"),
        ),
      ),
    );
  }
}

class CrispWebViewPage extends StatefulWidget {
  final String sessionId;
  final String websiteId;

  const CrispWebViewPage({
    super.key,
    required this.sessionId,
    required this.websiteId,
  });

  @override
  State<CrispWebViewPage> createState() => _CrispWebViewPageState();
}

class _CrispWebViewPageState extends State<CrispWebViewPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(
        Uri.parse(
          "https://go.crisp.chat/chat/embed/?website_id=${widget.websiteId}&locale=ar",
        ),
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) async {
            // Inject JS after page fully loads
            await _controller.runJavaScript("""
              if (window.\$crisp) {
                window.\$crisp.push(["set", "session:identifier", "${widget.sessionId}"]);
                window.\$crisp.push(["set", "session:language", "ar"]);
              }
            """);
          },
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Crisp Chat")),
      body: WebViewWidget(controller: _controller),
    );
  }
}
