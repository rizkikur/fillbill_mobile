import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class SnapWebviewScreen extends StatefulWidget {
  final String paymentUrl;

  const SnapWebviewScreen({super.key, required this.paymentUrl});

  @override
  State<SnapWebviewScreen> createState() => _SnapWebviewScreenState();
}

class _SnapWebviewScreenState extends State<SnapWebviewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (url) {
            setState(() {
              _isLoading = false;
            });
          },
          onNavigationRequest: (request) {
            final url = request.url.toLowerCase();
            // Deteksi redirect callback penyelesaian Snap Midtrans
            if (url.contains('finish') || url.contains('status_code=200')) {
              Navigator.of(context).pop(true);
              return NavigationDecision.prevent;
            } else if (url.contains('error') || url.contains('status_code=202')) {
              Navigator.of(context).pop(false);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Pembayaran Deposit'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: AppColors.bgLight,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentEmeraldDark),
                    ),
                    const SizedBox(height: 16),
                    Text('Menghubungkan ke Gateway...', style: AppTypography.bodySmall),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

