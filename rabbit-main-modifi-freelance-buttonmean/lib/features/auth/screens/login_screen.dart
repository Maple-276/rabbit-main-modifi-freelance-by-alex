import 'package:flutter/material.dart';
import 'package:flutter_restaurant/common/widgets/custom_pop_scope_widget.dart';
import 'package:flutter_restaurant/common/widgets/custom_asset_image_widget.dart';
import 'package:flutter_restaurant/common/widgets/custom_button_widget.dart';
import 'package:flutter_restaurant/common/widgets/custom_text_field_widget.dart';
import 'package:flutter_restaurant/features/auth/providers/auth_provider.dart';
import 'package:flutter_restaurant/features/auth/services/auth_service.dart';
import 'package:flutter_restaurant/features/auth/widgets/login_form_widget.dart';
import 'package:flutter_restaurant/localization/language_constrants.dart';
import 'package:flutter_restaurant/utill/images.dart';
import 'package:flutter_restaurant/utill/dimensions.dart';
import 'package:provider/provider.dart';

/// A screen that handles user authentication through phone number verification.
///
/// This screen provides functionality for users to enter their phone number,
/// receive a verification code, and complete the login process.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  // Animation controllers
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  
  // Services - inicialización inmediata para evitar LateInitializationError
  AuthService? _authService;
  
  // State flags
  bool _isInitialized = false;
  bool _hasInitializationError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    // Inicializa el servicio inmediatamente para evitar errores de late
    _initializeServicesImmediate();
    // También programa la inicialización después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initializeServices();
    });
  }

  /// Inicializa el servicio de autenticación de manera inmediata para evitar errores de late
  void _initializeServicesImmediate() {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.authRepo != null) {
        _authService = AuthService(authProvider);
      }
    } catch (e) {
      debugPrint('Immediate service initialization error: $e');
      // No actualizamos el estado aquí para evitar errores durante initState
    }
  }

  /// Initializes fade-in animations for UI elements
  void _initializeAnimations() {
    try {
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
    } catch (e) {
      debugPrint('Animation initialization error: $e');
      // No llamamos a _setInitializationError en initState para evitar errores
    }
  }

  /// Sets initialization error state
  void _setInitializationError(String message) {
    if (mounted) {
      setState(() {
        _hasInitializationError = true;
        _errorMessage = message;
      });
    }
  }

  /// Initializes services needed for authentication
  void _initializeServices() {
    if (!mounted) return;
    
    try {
      // Get auth provider from provider and initialize service
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      if (authProvider.authRepo == null) {
        _setInitializationError('Error: AuthRepo no inicializado');
        return;
      }
      
      setState(() {
        // Reemplazamos la instancia o la creamos si no existe
        _authService = AuthService(authProvider);
        _isInitialized = true;
      });
      
      // Reset auth provider states if needed
      authProvider.setIsLoading = false;
      if (authProvider.isPhoneNumberVerificationButtonLoading) {
        authProvider.setIsPhoneVerificationButttonLoading = false;
      }
    } catch (e) {
      debugPrint('Services initialization error: $e');
      _setInitializationError('Error al inicializar servicios: $e');
    }
  }

  @override
  void dispose() {
    // Clean up resources to prevent memory leaks
    try {
      if (_animationController?.isAnimating ?? false) {
        _animationController?.stop();
      }
      _animationController?.dispose();
    } catch (e) {
      debugPrint('Error disposing animation controller: $e');
    }
    super.dispose();
  }

  // Crea una instancia del servicio de auth si es necesario
  AuthService _getAuthService() {
    if (_authService == null) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.authRepo != null) {
          _authService = AuthService(authProvider);
        } else {
          throw Exception('AuthRepo no está disponible');
        }
      } catch (e) {
        debugPrint('Error obteniendo AuthService: $e');
        _setInitializationError('Error: No se pudo inicializar el servicio de autenticación');
      }
    }
    
    if (_authService == null) {
      throw Exception('AuthService no inicializado correctamente');
    }
    
    return _authService!;
  }

  void _showOtpDialog(BuildContext context) {
    final otpController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(getTranslated('enter_otp', context)!),
          content: Form(
            key: formKey,
            child: CustomTextFieldWidget(
              controller: otpController,
              hintText: '------',
              inputType: TextInputType.number,
              onValidate: (value) {
                if (value == null || value.isEmpty) {
                  return getTranslated('enter_otp', context);
                } else if (value.length != 6) {
                  return getTranslated('otp_must_be_6_digits', context);
                }
                return null;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(getTranslated('cancel', context)!),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
              },
            ),
            CustomButtonWidget( // Use CustomButtonWidget for consistency
              btnTxt: getTranslated('verify', context), // Use 'btnTxt'
              onTap: () { // Assume 'onTap' is the correct parameter
                if (formKey.currentState?.validate() ?? false) {
                  String otp = otpController.text;
                  print('Entered OTP: $otp'); // Placeholder for verification logic
                  // TODO: Implement actual OTP verification call using Provider
                  // Provider.of<AuthProvider>(context, listen: false).verifyOtp(phoneNumber, otp);
                  Navigator.of(dialogContext).pop(); // Close the dialog after processing
                  // Potentially navigate to main screen on success
                }
              },
            ),
          ],
        );
      },
    );
    // Dispose controller when dialog is potentially closed
    // Note: A more robust solution might involve StatefulWidget for the dialog content
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // This might not always dispose if dialog is closed differently
       if (ModalRoute.of(context)?.isCurrent ?? false) {
         // Check if screen is still active
       } else {
           otpController.dispose();
       }
    });

  }

  @override
  Widget build(BuildContext context) {
    // Handle initialization error
    if (_hasInitializationError) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                getTranslated('initialization_error', context)!,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _hasInitializationError = false;
                    _errorMessage = '';
                  });
                  _initializeServices();
                },
                child: Text(getTranslated('retry', context)!),
              ),
            ],
          ),
        ),
      );
    }
    
    // Safe handling to prevent errors if animation wasn't initialized correctly
    final fadeAnimation = _fadeAnimation ?? AlwaysStoppedAnimation(1.0);
    final size = MediaQuery.of(context).size;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Si todavía estamos inicializando, muestra la pantalla de carga
    if (!_isInitialized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                getTranslated('loading', context)!,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }
    
    // Intenta obtener el servicio de autenticación de manera segura
    try {
      _getAuthService();
    } catch (e) {
      // If an error occurs while obtaining the service, display an error and allow retry
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                getTranslated('auth_service_load_error', context)!,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {});
                  _initializeServices();
                },
                child: Text(getTranslated('retry', context)!),
              ),
            ],
          ),
        ),
      );
    }
    
    return CustomPopScopeWidget(
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: fadeAnimation,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Container(
                      height: size.height,
                      width: size.width,
                      color: isDarkMode 
                        ? Colors.black 
                        : const Color(0xFFFAFAFA),
                      child: Stack(
                        children: [
                          // Decorative background shape
                          Positioned(
                            top: -size.height * 0.15,
                            right: -size.width * 0.4,
                            child: Container(
                              width: size.width * 0.8,
                              height: size.width * 0.8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).primaryColor.withOpacity(0.05),
                              ),
                            ),
                          ),
                          
                          // Main content - Login form and OTP Button
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                LoginFormWidget(
                                  authService: _getAuthService(),
                                  onOtpLoginRequested: () => _showOtpDialog(context),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
