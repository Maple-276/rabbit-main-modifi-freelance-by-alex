import 'package:flutter/material.dart';
import 'package:flutter_restaurant/common/widgets/custom_pop_scope_widget.dart';
import 'package:flutter_restaurant/features/auth/providers/auth_provider.dart';
import 'package:flutter_restaurant/features/auth/services/auth_service.dart';
import 'package:flutter_restaurant/features/auth/widgets/login_form_widget.dart';
import 'package:flutter_restaurant/features/auth/widgets/otp_verification_dialog.dart';
import 'package:flutter_restaurant/helper/router_helper.dart';
import 'package:provider/provider.dart';
import 'package:flutter_restaurant/localization/language_constrants.dart';
import 'package:flutter_restaurant/utill/styles.dart';

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
    AuthService authService;
    try {
      authService = _getAuthService();
    } catch (e) {
      // Si ocurre un error al obtener el servicio, muestra un error y permite reintentar
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
                          
                          // Main content - Login form
                          Center(
                            child: LoginFormWidget(
                              authService: authService,
                              onOtpSent: _showOtpVerificationDialog,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 20.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (Navigator.canPop(context))
                                  Center(
                                    child: TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        getTranslated('cancel', context)!,
                                        style: rubikMedium.copyWith(
                                          color: Theme.of(context).primaryColor,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 10), // Espacio entre los botones
                                ElevatedButton.icon(
                                  onPressed: () {
                                    // Verificar que la ruta sea válida antes de navegar
                                    try {
                                      RouterHelper.getDashboardRoute(
                                        'home',
                                        action: RouteAction.pushNamedAndRemoveUntil,
                                      );
                                    } catch (e) {
                                      debugPrint('Error de navegación: $e');
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(getTranslated('navigation_error', context) ?? 'Error de navegación'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.person_outline, size: 18),
                                  label: Text(
                                    getTranslated('enter_as_guest', context)!,
                                    style: rubikMedium.copyWith(
                                      fontSize: 14,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.8),
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Shows the OTP verification dialog
  void _showOtpVerificationDialog(String phone, String tempToken) {
    if (!mounted) return;

    // Obtenemos la instancia actualizada del servicio de manera segura
    AuthService authService;
    try {
      authService = _getAuthService();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(getTranslated('otp_service_unavailable_error', context)!),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return OtpVerificationDialog(
            phone: phone,
            tempToken: tempToken,
            authService: authService,
            onVerificationSuccess: _handleVerificationSuccess,
          );
        },
      ).catchError((error) {
        debugPrint('Error showing OTP dialog: $error');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(getTranslated('otp_dialog_display_error', context)!),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    } catch (e) {
      debugPrint('Error in _showOtpVerificationDialog: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(getTranslated('otp_processing_error', context)!),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handles successful OTP verification
  void _handleVerificationSuccess() {
    try {
      // Navigate to dashboard or main page
      RouterHelper.getDashboardRoute(
        'home',
        action: RouteAction.pushNamedAndRemoveUntil,
      );
    } catch (e) {
      debugPrint('Navigation error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(getTranslated('navigation_error', context)!),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
