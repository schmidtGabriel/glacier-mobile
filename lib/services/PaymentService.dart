import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Result of a purchase operation
class PaymentResult {
  final bool success;
  final String? error;
  final CustomerInfo? customerInfo;
  final StoreTransaction? transaction;

  PaymentResult({
    required this.success,
    this.error,
    this.customerInfo,
    this.transaction,
  });

  PaymentResult.error(this.error)
    : success = false,
      customerInfo = null,
      transaction = null;

  PaymentResult.success(this.customerInfo, this.transaction)
    : success = true,
      error = null;
}

/// Service class for handling in-app purchases using RevenueCat
class PaymentService {
  static PaymentService? _instance;
  static PaymentService get instance {
    _instance ??= PaymentService._internal();
    return _instance!;
  }

  // Controllers for purchase events
  final StreamController<PaymentResult> _purchaseResultController =
      StreamController<PaymentResult>.broadcast();

  bool _isConfigured = false;
  Offerings? _offerings;
  CustomerInfo? _customerInfo;

  PaymentService._internal();

  /// Get the current customer info
  CustomerInfo? get customerInfo => _customerInfo;

  /// Check if user has any active subscription
  bool get hasActiveSubscription {
    return _customerInfo?.entitlements.active.isNotEmpty ?? false;
  }

  /// Check if the service is configured
  bool get isConfigured => _isConfigured;

  /// Get available offerings
  Offerings? get offerings => _offerings;

  /// Stream of purchase results
  Stream<PaymentResult> get purchaseStream => _purchaseResultController.stream;

  /// Dispose the service
  void dispose() {
    _purchaseResultController.close();
  }

  /// Format price for display
  String formatPrice(Package package) {
    return package.storeProduct.priceString;
  }

  /// Get current customer info
  Future<CustomerInfo?> getCustomerInfo() async {
    try {
      if (!_isConfigured) {
        return null;
      }

      _customerInfo = await Purchases.getCustomerInfo();
      return _customerInfo;
    } catch (e) {
      _handleError('Failed to get customer info: $e');
      return null;
    }
  }

  /// Get localized price
  String getLocalizedPrice(Package package) {
    return package.storeProduct.priceString;
  }

  /// Get current offerings
  Future<Offerings?> getOfferings() async {
    try {
      if (!_isConfigured) {
        debugPrint('PaymentService: Not configured, cannot get offerings');
        return null;
      }

      _offerings = await Purchases.getOfferings();
      return _offerings;
    } catch (e) {
      _handleError('Failed to get offerings: $e');
      return null;
    }
  }

  /// Get package by product ID
  Package? getPackageByProductId(String productId) {
    if (_offerings == null) return null;

    for (final offering in _offerings!.all.values) {
      for (final package in offering.availablePackages) {
        if (package.storeProduct.identifier == productId) {
          return package;
        }
      }
    }
    return null;
  }

  /// Check if user has active subscription for a given entitlement
  bool hasActiveEntitlement(String entitlementId) {
    return _customerInfo?.entitlements.active[entitlementId] != null;
  }

  /// Initialize the RevenueCat SDK
  Future<void> initialize({
    required String apiKey,
    String? userId,
    bool observerMode = false,
  }) async {
    try {
      // Configure purchases
      final configuration = PurchasesConfiguration(apiKey)..appUserID = null;

      await Purchases.configure(configuration);

      // Set user ID if provided
      if (userId != null) {
        await Purchases.logIn(userId);
      }

      // Setup purchase listener
      Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);

      // Get initial customer info and offerings
      await _loadInitialData();

      _isConfigured = true;
      debugPrint('PaymentService: RevenueCat initialized successfully');
    } catch (e) {
      _handleError('Failed to initialize RevenueCat: $e');
    }
  }

  /// Log in a user
  Future<void> logIn(String userId) async {
    try {
      if (!_isConfigured) {
        debugPrint('PaymentService: Not configured, cannot log in user');
        return;
      }

      final result = await Purchases.logIn(userId);
      _customerInfo = result as CustomerInfo?;
      debugPrint('PaymentService: User logged in: $userId');
    } catch (e) {
      _handleError('Failed to log in user: $e');
    }
  }

  /// Log out the current user
  Future<void> logOut() async {
    try {
      if (!_isConfigured) {
        return;
      }

      final result = await Purchases.logOut();
      _customerInfo = result;
      debugPrint('PaymentService: User logged out');
    } catch (e) {
      _handleError('Failed to log out user: $e');
    }
  }

  /// Purchase a package
  Future<PaymentResult> purchasePackage(Package package) async {
    try {
      if (!_isConfigured) {
        return PaymentResult.error('RevenueCat not initialized');
      }

      final purchaseResult = await Purchases.purchasePackage(package);

      if (purchaseResult.customerInfo.entitlements.active.isNotEmpty) {
        _customerInfo = purchaseResult.customerInfo;
        final result = PaymentResult.success(_customerInfo, null);
        _purchaseResultController.add(result);
        return result;
      } else {
        return PaymentResult.error('Purchase was not successful');
      }
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        return PaymentResult.error('Purchase was cancelled');
      } else if (errorCode == PurchasesErrorCode.storeProblemError) {
        return PaymentResult.error('Store problem occurred');
      } else if (errorCode == PurchasesErrorCode.purchaseNotAllowedError) {
        return PaymentResult.error('Purchase not allowed');
      } else if (errorCode == PurchasesErrorCode.paymentPendingError) {
        return PaymentResult.error('Payment is pending');
      } else {
        return PaymentResult.error('Purchase failed: ${e.message}');
      }
    } catch (e) {
      return PaymentResult.error('Unexpected error: $e');
    }
  }

  /// Purchase a product by ID
  Future<PaymentResult> purchaseProduct(String productId) async {
    try {
      if (_offerings == null) {
        await _loadInitialData();
      }

      final package = getPackageByProductId(productId);
      if (package == null) {
        return PaymentResult.error('Product not found: $productId');
      }

      return await purchasePackage(package);
    } catch (e) {
      return PaymentResult.error('Failed to purchase product: $e');
    }
  }

  /// Restore purchases
  Future<PaymentResult> restorePurchases() async {
    try {
      if (!_isConfigured) {
        return PaymentResult.error('RevenueCat not initialized');
      }

      final customerInfo = await Purchases.restorePurchases();
      _customerInfo = customerInfo;

      final result = PaymentResult.success(customerInfo, null);
      _purchaseResultController.add(result);
      return result;
    } on PlatformException catch (e) {
      return PaymentResult.error('Failed to restore purchases: ${e.message}');
    } catch (e) {
      return PaymentResult.error('Unexpected error: $e');
    }
  }

  /// Set user attributes
  Future<void> setAttributes(Map<String, String> attributes) async {
    try {
      if (!_isConfigured) {
        return;
      }

      await Purchases.setAttributes(attributes);
      debugPrint('PaymentService: Attributes set');
    } catch (e) {
      _handleError('Failed to set attributes: $e');
    }
  }

  /// Handle errors
  void _handleError(String message) {
    debugPrint('PaymentService Error: $message');
    _purchaseResultController.add(PaymentResult.error(message));
  }

  /// Load initial data (customer info and offerings)
  Future<void> _loadInitialData() async {
    try {
      // Load customer info
      _customerInfo = await Purchases.getCustomerInfo();

      // Load offerings
      _offerings = await Purchases.getOfferings();

      debugPrint('PaymentService: Initial data loaded');
    } catch (e) {
      _handleError('Failed to load initial data: $e');
    }
  }

  /// Handle customer info updates
  void _onCustomerInfoUpdated(CustomerInfo customerInfo) {
    _customerInfo = customerInfo;
    debugPrint('PaymentService: Customer info updated');
  }
}
