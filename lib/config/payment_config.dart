import 'dart:io';

import 'package:glacier/env/env.dart';

/// Configuration class for payment-related settings
class PaymentConfig {
  // RevenueCat API Keys for different platforms
  // Get these from your RevenueCat dashboard: Dashboard -> Your App -> API Keys

  // Production keys
  static final String _prodIosApiKey = Env.revenueCatIosApiKey;
  static final String _prodAndroidApiKey = Env.revenueCatAndroidApiKey;

  // Environment flag - set this based on your build configuration
  static const bool _isProduction = true; // Change to false for development

  /// Product IDs for in-app purchases
  static final String subscriptionProductId = Env.revenueCatProjectId;

  /// Entitlement IDs (if you use RevenueCat entitlements)
  static const String premiumEntitlementId = 'premium';

  /// Check if we're running in production mode
  static bool get isProduction => _isProduction;

  /// Get platform name for debugging
  static String get platformName {
    if (Platform.isIOS) return 'iOS';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }

  /// Get the appropriate RevenueCat API key for the current platform and environment
  static String get revenueCatApiKey {
    if (Platform.isIOS) {
      return _prodIosApiKey;
    } else if (Platform.isAndroid) {
      return _prodAndroidApiKey;
    } else {
      // Fallback for other platforms (web, desktop, etc.)
      // You might want to throw an exception here instead
      return _prodIosApiKey;
    }
  }
}
