import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'PushLoad.dart' show MainWebScreenPUSH;

class WebviewScreen extends StatefulWidget {
  final String webUrl;

  const WebviewScreen({Key? key, required this.webUrl}) : super(key: key);

  @override
  State<WebviewScreen> createState() => _WebviewScreenState();
}

class _WebviewScreenState extends State<WebviewScreen> {
  late InAppWebViewController _controller;
  bool _isLoading = true;
  double _progress = 0.0;
  Uri? _lastRedirectUrl;
  bool _triedLastUrl = false; // чтобы не зациклить повторную попытку

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
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

            print("Last redirect"+url.toString());
            setState(() {
              _isLoading = true;
              _progress = 0.3;
              if (url != null) {
                _lastRedirectUrl = url;
              }
            });
          },
          onUpdateVisitedHistory: (controller, url, androidIsReload) {

          },
          onReceivedError: (controller, request, error) async {
            print("WebView error: $error");
            if (error.type == WebResourceErrorType.TOO_MANY_REDIRECTS && !_triedLastUrl && _lastRedirectUrl != null) {
              _triedLastUrl = true;

              print(" LOAD DIRECT "+_lastRedirectUrl.toString());
              // Попробуем загрузить последний URL напрямую
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (context) => MainWebScreenPUSH( webUrl:_lastRedirectUrl.toString())),
                    (route) => false,
              );
            }
          },
          onLoadError: (controller, url, code, message) async {
            print("Load error: $message ($code) for $url");
            // Обработка аналогична onReceivedError, если нужно
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
              if (url != null) {
                _lastRedirectUrl = url;
              }
            });
          },
          shouldOverrideUrlLoading: (controller, navigationAction) async {
            // Можно также записывать сюда
            if (navigationAction.request.url != null) {
              _lastRedirectUrl = navigationAction.request.url;
            }
            return NavigationActionPolicy.ALLOW;
          },
        ),
      ),
    );
  }
}