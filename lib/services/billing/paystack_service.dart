import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

import '../../constants/billing_config.dart';
import '../../constants/feature_flags.dart';
import '../../constants/product_ids.dart';
import '../analytics/analytics_service.dart';

/// Exception thrown when Paystack operations fail
class PaystackException implements Exception {
  final String message;
  final String? code;
  
  const PaystackException(this.message, {this.code});
  
  @override
  String toString() => 'PaystackException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Represents a payment result from Paystack
class PaystackPaymentResult {
  final bool success;
  final String? error;
  final String? reference;
  final String? accessCode;
  final String? checkoutUrl;
  final Map<String, dynamic>? metadata;
  
  const PaystackPaymentResult({
    required this.success,
    this.error,
    this.reference,
    this.accessCode,
    this.checkoutUrl,
    this.metadata,
  });
}

/// Represents a Paystack product for web checkout
class PaystackProduct {
  final String id;
  final String name;
  final int amount; // Amount in kobo (smallest currency unit)
  final String currency;
  final String description;
  final Map<String, dynamic> metadata;
  
  const PaystackProduct({
    required this.id,
    required this.name,
    required this.amount,
    this.currency = 'NGN',
    required this.description,
    this.metadata = const {},
  });
  
  /// Create from product ID and convert price to kobo
  factory PaystackProduct.fromProductId(String productId, String userId) {
    // Map product IDs to Paystack products
    switch (productId) {
      case ProductIds.premiumMonthly:
        return PaystackProduct(
          id: productId,
          name: 'Premium Monthly',
          amount: 99900, // $0.99 converted to kobo (approximate)
          description: 'Monthly premium subscription',
          metadata: {
            BillingConfig.paystackMetadataUserIdKey: userId,
            BillingConfig.paystackMetadataProductIdKey: productId,
            BillingConfig.paystackMetadataEntitlementKey: BillingConfig.premiumEntitlementId,
            BillingConfig.paystackMetadataPlatformKey: 'web',
          },
        );
      case ProductIds.proMonthly:
        return PaystackProduct(
          id: productId,
          name: 'Pro Monthly',
          amount: 199900, // $1.99 converted to kobo (approximate)
          description: 'Monthly pro subscription',
          metadata: {
            BillingConfig.paystackMetadataUserIdKey: userId,
            BillingConfig.paystackMetadataProductIdKey: productId,
            BillingConfig.paystackMetadataEntitlementKey: BillingConfig.proEntitlementId,
            BillingConfig.paystackMetadataPlatformKey: 'web',
          },
        );
      case ProductIds.premiumLifetime:
        return PaystackProduct(
          id: productId,
          name: 'Premium Lifetime',
          amount: 999900, // $9.99 converted to kobo (approximate)
          description: 'Lifetime premium access',
          metadata: {
            BillingConfig.paystackMetadataUserIdKey: userId,
            BillingConfig.paystackMetadataProductIdKey: productId,
            BillingConfig.paystackMetadataEntitlementKey: BillingConfig.premiumEntitlementId,
            BillingConfig.paystackMetadataPlatformKey: 'web',
          },
        );
      case ProductIds.proLifetime:
        return PaystackProduct(
          id: productId,
          name: 'Pro Lifetime',
          amount: 1999900, // $19.99 converted to kobo (approximate)
          description: 'Lifetime pro access',
          metadata: {
            BillingConfig.paystackMetadataUserIdKey: userId,
            BillingConfig.paystackMetadataProductIdKey: productId,
            BillingConfig.paystackMetadataEntitlementKey: BillingConfig.proEntitlementId,
            BillingConfig.paystackMetadataPlatformKey: 'web',
          },
        );
      default:
        throw PaystackException('Unsupported product ID: $productId');
    }
  }
}

/// Service for managing Paystack web payments
class PaystackService extends ChangeNotifier {
  static PaystackService? _instance;
  static PaystackService get instance => _instance ??= PaystackService._();
  
  PaystackService._();

  bool _isInitialized = false;
  bool _isLoading = false;
  final AnalyticsService _analytics = AnalyticsService();
  
  /// Whether the service is initialized
  bool get isInitialized => _isInitialized;
  
  /// Whether a payment operation is in progress
  bool get isLoading => _isLoading;

  /// Initialize Paystack service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    if (!FeatureFlags.paystackEnabled || !FeatureFlags.webCheckoutEnabled) {
      if (kDebugMode) {
        print('Paystack: Disabled via feature flags');
      }
      return;
    }

    try {
      _setLoading(true);
      
      // Verify Paystack configuration
      if (!_isConfigurationValid()) {
        throw const PaystackException('Paystack configuration is invalid');
      }
      
      _isInitialized = true;
      
      _analytics.logEvent('paystack_service_initialized', {
        'provider': 'paystack',
        'configuration_valid': true,
      });
      
      if (kDebugMode) {
        print('Paystack: Successfully initialized');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('Paystack: Initialization failed: $e');
      }
      
      _analytics.logEvent('paystack_service_init_failed', {
        'provider': 'paystack',
        'error': e.toString(),
      });
      
      throw PaystackException('Failed to initialize Paystack: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Initialize a payment for a product
  Future<PaystackPaymentResult> initializePayment({
    required String productId,
    required String userId,
    required String userEmail,
    String? callbackUrl,
  }) async {
    if (!_isInitialized) {
      throw const PaystackException('Paystack not initialized');
    }

    try {
      _setLoading(true);
      
      _analytics.logEvent('paystack_payment_initiated', {
        'provider': 'paystack',
        'product_id': productId,
        'user_id': userId,
      });
      
      // Create product from product ID
      final product = PaystackProduct.fromProductId(productId, userId);
      
      // Generate unique reference
      final reference = _generateReference();
      
      // Prepare request body
      final requestBody = {
        'amount': product.amount,
        'email': userEmail,
        'reference': reference,
        'currency': product.currency,
        'metadata': product.metadata,
        'callback_url': callbackUrl ?? BillingConfig.webhookEndpoint,
      };
      
      // Make API request to initialize transaction
      final response = await http.post(
        Uri.parse('https://api.paystack.co/transaction/initialize'),
        headers: {
          'Authorization': 'Bearer ${BillingConfig.paystackSecretKey}',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );
      
      final responseData = json.decode(response.body) as Map<String, dynamic>;
      
      if (response.statusCode == 200 && responseData['status'] == true) {
        final data = responseData['data'] as Map<String, dynamic>;
        
        _analytics.logEvent('paystack_payment_initialized', {
          'provider': 'paystack',
          'product_id': productId,
          'reference': reference,
          'amount': product.amount,
        });
        
        if (kDebugMode) {
          print('Paystack: Payment initialized successfully for $productId');
        }
        
        return PaystackPaymentResult(
          success: true,
          reference: reference,
          accessCode: data['access_code'],
          checkoutUrl: data['authorization_url'],
          metadata: product.metadata,
        );
      } else {
        final errorMessage = responseData['message'] ?? 'Payment initialization failed';
        
        _analytics.logEvent('paystack_payment_init_failed', {
          'provider': 'paystack',
          'product_id': productId,
          'error': errorMessage,
        });
        
        return PaystackPaymentResult(
          success: false,
          error: errorMessage,
        );
      }
      
    } catch (e) {
      _analytics.logEvent('paystack_payment_init_failed', {
        'provider': 'paystack',
        'product_id': productId,
        'error': e.toString(),
      });
      
      if (kDebugMode) {
        print('Paystack: Payment initialization failed: $e');
      }
      
      return PaystackPaymentResult(
        success: false,
        error: e.toString(),
      );
    } finally {
      _setLoading(false);
    }
  }

  /// Verify a payment transaction
  Future<PaystackPaymentResult> verifyPayment(String reference) async {
    if (!_isInitialized) {
      throw const PaystackException('Paystack not initialized');
    }

    try {
      _setLoading(true);
      
      _analytics.logEvent('paystack_payment_verification_started', {
        'provider': 'paystack',
        'reference': reference,
      });
      
      final response = await http.get(
        Uri.parse('https://api.paystack.co/transaction/verify/$reference'),
        headers: {
          'Authorization': 'Bearer ${BillingConfig.paystackSecretKey}',
          'Content-Type': 'application/json',
        },
      );
      
      final responseData = json.decode(response.body) as Map<String, dynamic>;
      
      if (response.statusCode == 200 && responseData['status'] == true) {
        final data = responseData['data'] as Map<String, dynamic>;
        final status = data['status'] as String;
        
        final success = status == 'success';
        
        _analytics.logEvent('paystack_payment_verified', {
          'provider': 'paystack',
          'reference': reference,
          'status': status,
          'success': success,
          'amount': data['amount'],
        });
        
        if (kDebugMode) {
          print('Paystack: Payment verification completed. Status: $status');
        }
        
        return PaystackPaymentResult(
          success: success,
          reference: reference,
          metadata: data['metadata'] as Map<String, dynamic>?,
        );
      } else {
        final errorMessage = responseData['message'] ?? 'Payment verification failed';
        
        _analytics.logEvent('paystack_payment_verification_failed', {
          'provider': 'paystack',
          'reference': reference,
          'error': errorMessage,
        });
        
        return PaystackPaymentResult(
          success: false,
          error: errorMessage,
          reference: reference,
        );
      }
      
    } catch (e) {
      _analytics.logEvent('paystack_payment_verification_failed', {
        'provider': 'paystack',
        'reference': reference,
        'error': e.toString(),
      });
      
      if (kDebugMode) {
        print('Paystack: Payment verification failed: $e');
      }
      
      return PaystackPaymentResult(
        success: false,
        error: e.toString(),
        reference: reference,
      );
    } finally {
      _setLoading(false);
    }
  }

  /// Get supported products for web checkout
  List<PaystackProduct> getSupportedProducts(String userId) {
    return [
      PaystackProduct.fromProductId(ProductIds.premiumMonthly, userId),
      PaystackProduct.fromProductId(ProductIds.proMonthly, userId),
      PaystackProduct.fromProductId(ProductIds.premiumLifetime, userId),
      PaystackProduct.fromProductId(ProductIds.proLifetime, userId),
    ];
  }

  /// Generate a unique payment reference
  String _generateReference() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999);
    return 'QNP_${timestamp}_$random';
  }

  /// Check if Paystack configuration is valid
  bool _isConfigurationValid() {
    return !BillingConfig.paystackPublicKey.startsWith('your_') &&
           !BillingConfig.paystackSecretKey.startsWith('your_');
  }

  /// Set loading state
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// Dispose of resources
  @override
  void dispose() {
    super.dispose();
  }
}

/// Utility class for Paystack webhook verification
class PaystackWebhookVerifier {
  /// Verify webhook signature
  static bool verifySignature({
    required String payload,
    required String signature,
    required String secret,
  }) {
    try {
      final expectedSignature = _computeSignature(payload, secret);
      return signature == expectedSignature;
    } catch (e) {
      if (kDebugMode) {
        print('Paystack: Webhook signature verification failed: $e');
      }
      return false;
    }
  }

  /// Compute HMAC SHA-512 signature
  static String _computeSignature(String payload, String secret) {
    final key = utf8.encode(secret);
    final bytes = utf8.encode(payload);
    final hmacSha512 = Hmac(sha512, key);
    final digest = hmacSha512.convert(bytes);
    return digest.toString();
  }
}