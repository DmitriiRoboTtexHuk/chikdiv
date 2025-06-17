import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodChannel, SystemChrome, SystemUiOverlayStyle;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

class MainWebScreenPUSH extends StatefulWidget {
  final String webUrl;

  const MainWebScreenPUSH({Key? key, required this.webUrl}) : super(key: key);

  @override
  State<MainWebScreenPUSH> createState() => _MainWebScreenPUSHState();
}

class _MainWebScreenPUSHState extends State<MainWebScreenPUSH> {
  late InAppWebViewController _controller;
  bool _isLoading = true;
  double _progress = 0.0;

  static const String _privacyPolicyUrl = "https://chickchickdive.com/privacy-policy.html";

  Uri? _lastRedirectUrl;
  bool _triedLastUrl = false; // чтобы не зациклить повторную попытку

  /// Проверка: нужно ли открывать ссылку вне webview
  bool _shouldOpenExternally(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    final host = uri.host.toLowerCase();

    // Открыть во внешнем приложении:
    if (scheme == "paytmmp" ||
        scheme == "phonepe" ||
        scheme == "bankid") {
      return true;
    }
    // App Store
    if (scheme == "https" && host.contains("apps.apple.com")) {
      return true;
    }
    // Google Play
    if (scheme == "https" && host.contains("play.google.com")) {
      return true;
    }
    return false;
  }
  @override
  void initState() {
    _ficationChannel();
    // Черный статус-бар
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black, // Android
      statusBarBrightness: Brightness.dark, // iOS: светлые иконки
      statusBarIconBrightness: Brightness.light, // Android: светлые иконки
    ));
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
            MaterialPageRoute(builder: (context) => MainWebScreenPUSH(webUrl: url)),
                (route) => false,
          );
        }
      }
    });
  }



  @override
  Widget build(BuildContext context) {
    // Устанавливаем стиль status bar
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black, // Android: чёрный status bar
      statusBarBrightness: Brightness.dark, // iOS: светлые иконки (чёрный фон)
      statusBarIconBrightness: Brightness.light, // Android: светлые иконки
    ));

    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        color: Colors.black,
        child: SafeArea(
          child: Container(
            color: Colors.black,
            child: Stack(
              children: [
                Container(
                  height: statusBarHeight,
                  color: Colors.black,
                ),
                InAppWebView(
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    disableDefaultErrorPage: true,
                    mediaPlaybackRequiresUserGesture: false,
                    allowsInlineMediaPlayback: true,
                    allowsPictureInPictureMediaPlayback: true,
                    useOnDownloadStart: true,
                    javaScriptCanOpenWindowsAutomatically: true,
                    supportZoom: false, // отключаем зум
                    // отключаем жесты масштабирования
                  ),
                  initialUrlRequest: URLRequest(url: WebUri(widget.webUrl)),
                  onWebViewCreated: (controller) {
                    _controller = controller;
                  },
                  onLoadStart: (controller, url) {
                    setState(() {
                      _isLoading = true;
                      _progress = 0.3;
                      if (url != null) {
                        _lastRedirectUrl = url;
                      }
                    });
                  },
                  onUpdateVisitedHistory: (controller, url, androidIsReload) {},
                  onReceivedError: (controller, request, error) async {
                    final failingUrl = request.url;
                    // Подавляем ошибку, если она по диплинку/маркету
                    if (failingUrl != null && _shouldOpenExternally(failingUrl)) {
                      return;
                    }
                    if (error.type == WebResourceErrorType.TOO_MANY_REDIRECTS &&
                        !_triedLastUrl &&
                        _lastRedirectUrl != null) {
                      _triedLastUrl = true;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              MainWebScreenPUSH(webUrl: _lastRedirectUrl.toString()),
                        ),
                            (route) => false,
                      );
                    }
                  },
                  onLoadError: (controller, url, code, message) async {
                    // Подавляем ошибку, если она по диплинку/маркету
                    if (url != null && _shouldOpenExternally(url)) {
                      return;
                    }
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
                    final uri = navigationAction.request.url;
                    if (uri != null) {
                      _lastRedirectUrl = uri;

                      if (_shouldOpenExternally(uri)) {
                        try {
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                            return NavigationActionPolicy.CANCEL;
                          }
                        } catch (e) {
                          debugPrint("Не удалось запустить deeplink: $uri, ошибка: $e");
                          // Если приложение не установлено — подавляем ошибку
                          return NavigationActionPolicy.CANCEL;
                        }
                      }
                    }
                    return NavigationActionPolicy.ALLOW;
                  },
                ),
                if (_isLoading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: _progress < 1.0 ? _progress : null,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}