import 'package:flutter/material.dart';

import 'package:flutter_restaurant/features/auth/providers/auth_provider.dart';
import 'package:flutter_restaurant/features/auth/services/auth_service.dart';
import 'package:flutter_restaurant/features/auth/widgets/login_form_widget.dart';
import 'package:flutter_restaurant/features/auth/widgets/otp_verification_dialog.dart';

import 'package:flutter_restaurant/helper/custom_snackbar_helper.dart';

import 'package:flutter_restaurant/helper/router_helper.dart';
import 'package:flutter_restaurant/localization/language_constrants.dart';

import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  // Animation controllers
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  // Services
  AuthService? _authService;

  // State flags
  bool _isInitialized = false;
  bool _hasInitializationError = false;
  String _errorMessage = '';
  bool _isSendingOtp = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeServicesImmediate();
  }

  // Immediate service initialization
  void _initializeServicesImmediate() {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      _authService = AuthService(authProvider);
      setState(() {
        _isInitialized = true;
        _hasInitializationError = false;
      });
    } catch (e) {
      debugPrint('LoginScreen: Error initializing services: $e');
      setState(() {
        _isInitialized = false;
        _hasInitializationError = true;
        _errorMessage = 'Failed to initialize authentication services: $e';
      });
    }
  }

  // Initialize animations
  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: Curves.easeInOut,
      ),
    );
    _animationController?.forward();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  // --- New method to handle successful OTP verification ---
  void _handleOtpVerificationSuccess() {
    if (!mounted) return;
    debugPrint("OTP Verification Successful! Proceeding to login/navigate...");
    Navigator.of(context, rootNavigator: true).pop();

    // Navigate to the main screen
    RouterHelper.getMainRoute(action: RouteAction.pushNamedAndRemoveUntil);
  }

  // --- Updated method to handle OTP Login request ---
  void _handleOtpLoginRequested(String? phoneNumber) async {
    // Use _authService directly, check if initialized
    if (_authService == null || !_isInitialized || _isSendingOtp) {
      debugPrint('Auth service not ready or already sending OTP.');
      return;
    }
    if (phoneNumber == null || phoneNumber.isEmpty) {
      showCustomSnackBarHelper(getTranslated('please_enter_phone_number', context));
      return;
    }

    setState(() {
      _isSendingOtp = true;
    });

    try {
      debugPrint('Attempting to send OTP to: $phoneNumber');
      final result = await _authService!.sendVerificationCode(phoneNumber);

      if (!mounted) return;

      if (result.success) {
        debugPrint('OTP sent successfully. Showing verification dialog.');
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return OtpVerificationDialog(
              phone: phoneNumber,
              authService: _authService!,
              onVerificationSuccess: _handleOtpVerificationSuccess,
            );
          },
        );
      } else {
        debugPrint('Failed to send OTP: ${result.message}');
        showCustomSnackBarHelper(result.message ?? getTranslated('failed_to_send_otp', context));
      }
    } catch (e) {
      debugPrint('Error sending OTP: $e');
      if (!mounted) return;
      showCustomSnackBarHelper('${getTranslated('error_sending_otp', context)}: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSendingOtp = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    // Use Scaffold directly, removed CustomPopScopeWidget
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: FadeTransition(
              opacity: _fadeAnimation ?? const AlwaysStoppedAnimation(1),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Check if services are initialized
                  if (_hasInitializationError)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else if (!_isInitialized)
                    const Center(child: CircularProgressIndicator()) // Show loading indicator
                  else ...[
                    // Login/Registration Form
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, _) {
                        // Ensure _authService is available before building LoginFormWidget
                        if (_authService == null) {
                          // This should ideally not happen if initialization logic is correct
                          return const Center(child: Text('Error: Authentication service not available.'));
                        }
                        return LoginFormWidget(
                          authService: _authService!, // Pass the initialized service
                          // Pass the new handler to LoginFormWidget
                          onOtpLoginRequested: _handleOtpLoginRequested, // Type fixed in LoginFormWidget's definition
                        );
                      },
                    ),
                  ],

                  SizedBox(height: size.height * 0.03),

                  // // User Satisfaction Banner (Example placeholder)
                  // Container(
                  //   padding: const EdgeInsets.all(12),
                  //   decoration: BoxDecoration(
                  //     color: Colors.green.withOpacity(0.1),
                  //     borderRadius: BorderRadius.circular(8),
                  //   ),
                  //   child: Text(
                  //     getTranslated('user_satisfaction_message', context)!,
                  //     textAlign: TextAlign.center,
                  //     style: TextStyle(color: Colors.green[800]),
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
