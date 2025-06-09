import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodChannel;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class  MainWebScreenPUSH extends StatefulWidget {
  final String webUrl;

  const  MainWebScreenPUSH({Key? key, required this.webUrl}) : super(key: key);

  @override
  State< MainWebScreenPUSH> createState() => _MainWebScreenPUSHState();
}

class _MainWebScreenPUSHState extends State< MainWebScreenPUSH> {
  late InAppWebViewController _controller;
  bool _isLoading = true;
  double _progress = 0.0;

  static const String _privacyPolicyUrl = "https://chickchickdive.com/privacy-policy.html";
  @override
  void initState() {
    _ficationChannel();
    super.initState();
  }
  void _ficationChannel() {
    MethodChannel('com.example.fcm/notification')
        .setMethodCallHandler((call) async {
      if (call.method == "onNotificationTap") {
        final Map<String, dynamic> data = Map<String, dynamic>.from(call.arguments);
        final url = data["uri"];
        if (url != null && !url.contains("Нет URI")) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (context) => MainWebScreenPUSH( webUrl:url)),
                (route) => false,
          );
        }
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    final bool isPrivacyPolicy = widget.webUrl == _privacyPolicyUrl;

    Widget webView = SafeArea(
      child: InAppWebView(
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          disableDefaultErrorPage: true,
          mediaPlaybackRequiresUserGesture: false,
          allowsInlineMediaPlayback: true,
          allowsPictureInPictureMediaPlayback: true,
          useOnDownloadStart: true,
          javaScriptCanOpenWindowsAutomatically: true,
        ),
        initialUrlRequest: URLRequest(url: WebUri(widget.webUrl)),
        onWebViewCreated: (controller) {
          _controller = controller;
        },
        onLoadStart: (controller, url) {
          setState(() {
            _isLoading = true;
            _progress = 0.3;
          });
        },
        onProgressChanged: (controller, progress) {
          setState(() {
            _progress = progress / 100.0;
          });
        },
        onLoadStop: (controller, url) async {
          setState(() {
            _isLoading = false;
            _progress = 1.0;
          });
        },
        shouldOverrideUrlLoading: (controller, navigationAction) async {
          return NavigationActionPolicy.ALLOW;
        },
      ),
    );

    // Если политика — показываем AppBar с кнопкой назад
    if (isPrivacyPolicy) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF201E48),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Privacy Policy',
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
        ),
        backgroundColor: const Color(0xFF201E48),
        body: Stack(
          children: [
            webView,
            if (_isLoading)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 3,
                  backgroundColor: Colors.orange.shade100,
                  color: Colors.orange,
                ),
              ),
          ],
        ),
      );
    }

    // Если не политика — без кнопки назад
    return Scaffold(
      backgroundColor: const Color(0xFF201E48),
      body: Stack(
        children: [
          webView,
          if (_isLoading)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 3,
                backgroundColor: Colors.orange.shade100,
                color: Colors.orange,
              ),
            ),
        ],
      ),
    );
  }
}