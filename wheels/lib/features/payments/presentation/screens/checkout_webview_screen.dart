import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../providers/payment_provider.dart';

class CheckoutWebViewScreen extends ConsumerStatefulWidget {
  const CheckoutWebViewScreen({
    required this.checkoutUrl,
    required this.rideId,
    super.key,
  });

  final String checkoutUrl;
  final String rideId;

  @override
  ConsumerState<CheckoutWebViewScreen> createState() =>
      _CheckoutWebViewScreenState();
}

class _CheckoutWebViewScreenState extends ConsumerState<CheckoutWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoadingPage = true;
  bool _handledRedirect = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(paymentProvider.notifier).bindPaymentStream(widget.rideId);
    });

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (_handleRedirectIfNeeded(url)) {
              return;
            }
            if (mounted) {
              setState(() => _isLoadingPage = true);
            }
          },
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _isLoadingPage = false);
            }
          },
          onNavigationRequest: (request) {
            if (_handleRedirectIfNeeded(request.url)) {
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) {
            ref
                .read(paymentProvider.notifier)
                .handleCheckoutLaunchError(error.description);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  bool _handleRedirectIfNeeded(String rawUrl) {
    if (_handledRedirect) {
      return true;
    }

    final uri = Uri.tryParse(rawUrl);
    final normalizedUrl = rawUrl.toLowerCase();
    final scheme = uri?.scheme.toLowerCase();
    final host = uri?.host.toLowerCase();
    final path = uri?.path.toLowerCase() ?? '';
    final isWheelsScheme = scheme == 'wheels' && host == 'payment';
    final isWheelsHosted =
        scheme == 'https' &&
        host == 'wheels.app' &&
        path.startsWith('/payment/');

    if (!isWheelsScheme && !isWheelsHosted) {
      return false;
    }

    _handledRedirect = true;

    if (_isSuccessUrl(normalizedUrl)) {
      ref.read(paymentProvider.notifier).handleRedirectSuccess();
    } else if (_isPendingUrl(normalizedUrl)) {
      ref.read(paymentProvider.notifier).handleRedirectPending();
    } else if (_isFailureUrl(normalizedUrl)) {
      ref.read(paymentProvider.notifier).handleRedirectFailure();
    } else {
      ref
          .read(paymentProvider.notifier)
          .handleCheckoutLaunchError('Unknown Mercado Pago return URL.');
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });

    return true;
  }

  bool _isSuccessUrl(String url) {
    return url.contains('/payment/success') || url.contains('/payment/sucess');
  }

  bool _isPendingUrl(String url) {
    return url.contains('/payment/pending');
  }

  bool _isFailureUrl(String url) {
    return url.contains('/payment/failure') ||
        url.contains('/payment/failture');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mercado Pago')),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoadingPage)
            const Align(
              alignment: Alignment.topCenter,
              child: LinearProgressIndicator(minHeight: 2),
            ),
        ],
      ),
    );
  }
}
