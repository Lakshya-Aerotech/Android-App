import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../booking/models/booking_model.dart';
import '../../../booking/viewmodels/booking_viewmodel.dart';
import '../../data/repositories/payment_repository.dart';

class PaymentWebViewScreen extends ConsumerStatefulWidget {
  final BookingModel booking;
  final String paymentUrl;
  final String merchantTransactionId;

  const PaymentWebViewScreen({
    super.key,
    required this.booking,
    required this.paymentUrl,
    required this.merchantTransactionId,
  });

  @override
  ConsumerState<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends ConsumerState<PaymentWebViewScreen> {
  late final WebViewController _webViewController;
  bool _isLoading = true;
  bool _verificationInProgress = false;

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
      if (uri.path.endsWith('/payment/redirect')) {
        _verifyPaymentWithBackend();
      }
    } catch (_) {}
  }

  Future<void> _verifyPaymentWithBackend() async {
    if (_verificationInProgress || !mounted) return;
    _verificationInProgress = true;
    final status = await ref
        .read(paymentRepositoryProvider)
        .checkPaymentStatus(widget.merchantTransactionId);
    _verificationInProgress = false;
    if (!mounted) return;

    switch (status) {
      case PaymentVerificationStatus.success:
        _navigateToSuccess();
        return;
      case PaymentVerificationStatus.failed:
        _navigateToFailure();
        return;
      case PaymentVerificationStatus.pending:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment is still being verified. Please wait.'),
          ),
        );
        return;
    }
  }

  void _navigateToSuccess() {
    if (!mounted) return;
    context.go('/payment-success', extra: {
      'booking': widget.booking,
      'transactionId': widget.merchantTransactionId,
    });
  }

  void _navigateToFailure() {
    if (!mounted) return;
    context.go('/payment-failed', extra: widget.booking);
  }

  Future<void> _handleBackPress() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Payment?'),
        content: const Text(
          'Are you sure you want to leave the payment page? If you have paid, please wait a moment for confirmation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Go Back to Payment'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel & Exit', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldExit == true && mounted) {
      context.go('/payment-failed', extra: widget.booking);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<BookingModel?>>(
      singleBookingStreamProvider(widget.booking.docId!),
      (previous, next) {
        if (next is AsyncData && next.value != null) {
          final liveBooking = next.value!;
          final paymentStatus = liveBooking.paymentStatus?.toUpperCase();
          if (paymentStatus == 'SUCCESS') {
            context.go('/payment-success', extra: {
              'booking': liveBooking,
              'transactionId': liveBooking.merchantTransactionId ?? liveBooking.transactionId ?? 'N/A',
            });
          } else if (paymentStatus == 'FAILED' || paymentStatus == 'CANCELLED') {
            context.go('/payment-failed', extra: liveBooking);
          }
        }
      },
    );

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
                      Text('Loading PhonePe Gateway...'),
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
