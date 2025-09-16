import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:glacier/config/payment_config.dart';
import 'package:glacier/resources/UserResource.dart';
import 'package:glacier/themes/app_colors.dart';
import 'package:glacier/themes/theme_extensions.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/PaymentService.dart';
// Optionally, you can use a separate config class:
// import '../config/payment_config.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  // Product ID for the subscription - adjust this to match your product ID
  static final String _subscriptionProductId =
      PaymentConfig.subscriptionProductId;
  // Get the appropriate API key based on platform
  final String _revenueCatApiKey = PaymentConfig.revenueCatApiKey;
  final PaymentService _paymentService = PaymentService.instance;

  bool _isLoading = true;
  bool _isSubscribing = false;
  bool _isRestoring = false;
  String? _error;
  Package? _subscriptionPackage;
  UserResource? user;

  @override
  Widget build(BuildContext context) {
    print('RevenueCat API Key: $_revenueCatApiKey');

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (user != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Text(
                              'You’re logged in as ${user?.email}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                color:
                                    context.isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                              ),
                            ),

                            GestureDetector(
                              onTap: () async {
                                bool? shouldSignOut = await showDialog<bool>(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text('Sign Out'),
                                      content: Text(
                                        'Are you sure you want to sign out?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(
                                                context,
                                              ).pop(false),
                                          child: Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(
                                                context,
                                              ).pop(true),
                                          child: Text('Sign Out'),
                                        ),
                                      ],
                                    );
                                  },
                                );

                                if (shouldSignOut == true) {
                                  await FirebaseAuth.instance.signOut();
                                  SharedPreferences.getInstance().then((
                                    prefs,
                                  ) async {
                                    await prefs.remove('user');
                                    await prefs.remove('friends');
                                    await prefs.remove('invite');
                                    await prefs.remove('reactions');
                                    await prefs.remove('recent_friends');
                                    Navigator.pushNamedAndRemoveUntil(
                                      context,
                                      '/',
                                      (route) => false,
                                    );
                                  });
                                }
                              },

                              child: Text(
                                'Logout',
                                style: TextStyle(
                                  color:
                                      context.isDarkMode
                                          ? AppColors.primaryLight
                                          : AppColors.primaryDark,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                      // content
                      if (_isLoading)
                        Expanded(
                          child: Center(
                            child: const CircularProgressIndicator(),
                          ),
                        )
                      else if (_error != null)
                        Column(
                          children: [
                            Text(
                              'Error: $_error',
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _initializePaymentService,
                              child: const Text('Retry'),
                            ),
                          ],
                        )
                      else
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                const Text(
                                  'All-in Plan',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _subscriptionPackage != null
                                      ? _paymentService.formatPrice(
                                        _subscriptionPackage!,
                                      )
                                      : '\$9.99/month',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('✓ Unlimited reactions'),
                                    SizedBox(height: 4),
                                    Text('✓ Invite unlimited friends'),
                                    SizedBox(height: 4),
                                    Text('✓ Priority support'),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed:
                                        _isSubscribing
                                            ? null
                                            : _handleSubscribe,
                                    child:
                                        _isSubscribing
                                            ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                            : const Text('Subscribe Now'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      Padding(
                        padding: const EdgeInsets.only(bottom: 0, top: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Center(
                              child: GestureDetector(
                                onTap:
                                    _isRestoring
                                        ? null
                                        : _handleRestorePurchase,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (_isRestoring)
                                      const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    else
                                      Text(
                                        "Restore Purchase",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color:
                                              _isRestoring
                                                  ? Colors.grey
                                                  : AppColors.secondary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: GestureDetector(
                                onTap: () {
                                  // Handle Terms
                                },
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Terms and Conditions",
                                      style: TextStyle(
                                        color: Colors.grey.shade100,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  getUserData() {
    SharedPreferences.getInstance().then(
      (prefs) =>
          user = UserResource.fromJson(
            jsonDecode(prefs.getString('user') ?? '{}'),
          ),
    );
  }

  @override
  void initState() {
    super.initState();
    getUserData();
    _initializePaymentService();
  }

  Future<void> _handleRestorePurchase() async {
    setState(() {
      _isRestoring = true;
    });

    try {
      final result = await _paymentService.restorePurchases();
      if (result.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Purchases restored successfully!')),
          );
          Navigator.of(context).pop();
        }
      } else {
        setState(() {
          _isRestoring = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? 'Failed to restore purchases'),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isRestoring = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to restore purchases: $e')),
        );
      }
    }
  }

  Future<void> _handleSubscribe() async {
    if (_subscriptionPackage == null) return;

    setState(() {
      _isSubscribing = true;
    });

    try {
      final result = await _paymentService.purchasePackage(
        _subscriptionPackage!,
      );
      if (!result.success) {
        setState(() {
          _isSubscribing = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.error ?? 'Purchase failed')),
          );
        }
      }
      // Success will be handled by the purchase stream listener
    } catch (e) {
      setState(() {
        _isSubscribing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to start purchase: $e')));
      }
    }
  }

  Future<void> _initializePaymentService() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Initialize RevenueCat with your API key
      await _paymentService.initialize(
        apiKey:
            _revenueCatApiKey, // You'll need to set this from your RevenueCat dashboard
      );

      // Get offerings from RevenueCat
      final offerings = await _paymentService.getOfferings();

      if (offerings?.current != null) {
        // Look for the subscription package by product ID
        _subscriptionPackage = _paymentService.getPackageByProductId(
          _subscriptionProductId,
        );

        setState(() {
          _isLoading = false;
        });

        // Listen to purchase stream
        _paymentService.purchaseStream.listen(_onPurchaseUpdate);
      } else {
        setState(() {
          _error = 'No subscription plans available';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize payment service: $e';
        _isLoading = false;
      });
    }
  }

  void _onPurchaseUpdate(PaymentResult result) {
    setState(() {
      _isSubscribing = false;
      _isRestoring = false;
    });

    if (result.success) {
      // Handle successful purchase
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subscription successful!')),
        );
        // Navigate back or to the main app
        Navigator.of(context).pop();
      }
    } else {
      // Handle purchase error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Purchase failed: ${result.error ?? "Unknown error"}',
            ),
          ),
        );
      }
    }
  }
}
