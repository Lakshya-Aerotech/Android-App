import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../booking/models/booking_model.dart';
import '../../../booking/viewmodels/booking_viewmodel.dart';

class PaymentWebViewScreen extends ConsumerStatefulWidget {
  final BookingModel booking;
  final String paymentUrl;

  const PaymentWebViewScreen({
    super.key,
    required this.booking,
    required this.paymentUrl,
  });

  @override
  ConsumerState<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends ConsumerState<PaymentWebViewScreen> {
  late final WebViewController _webViewController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
            _checkUrlCompletion(url);
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            _checkUrlCompletion(url);
          },
          onNavigationRequest: (NavigationRequest request) {
            _checkUrlCompletion(request.url);
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _checkUrlCompletion(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.path.contains('/api/payment/redirect') || uri.queryParameters.containsKey('status')) {
        final status = uri.queryParameters['status']?.toUpperCase();
        if (status == 'SUCCESS') {
          _navigateToSuccess();
        } else if (status == 'FAILED' || status == 'CANCELLED') {
          _navigateToFailure();
        }
      }
    } catch (_) {}
  }

  void _navigateToSuccess() {
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  void _navigateToFailure() {
    if (!mounted) return;
    Navigator.pop(context, false);
  }

  Future<void> _handleBackPress() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Payment?'),
        content: const Text(
          'Are you sure you want to leave the payment page? You can try paying again or switch payment timing on the booking screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay on Payment'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel Payment & Exit', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldExit == true && mounted) {
      Navigator.pop(context, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.booking.docId != null) {
      ref.listen<AsyncValue<BookingModel?>>(
        singleBookingStreamProvider(widget.booking.docId!),
        (previous, next) {
          if (next is AsyncData && next.value != null) {
            final liveBooking = next.value!;
            final paymentStatus = liveBooking.paymentStatus?.toUpperCase();
            if (paymentStatus == 'SUCCESS' || paymentStatus == 'PAID') {
              _navigateToSuccess();
            } else if (paymentStatus == 'FAILED' || paymentStatus == 'CANCELLED') {
              _navigateToFailure();
            }
          }
        },
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackPress();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Secure Payment Gateway'),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _handleBackPress,
          ),
          actions: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _webViewController),
            if (_isLoading)
              Container(
                color: Colors.white.withValues(alpha: 0.8),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      SizedBox(height: 16),
                      Text('Loading Cashfree Gateway...'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
