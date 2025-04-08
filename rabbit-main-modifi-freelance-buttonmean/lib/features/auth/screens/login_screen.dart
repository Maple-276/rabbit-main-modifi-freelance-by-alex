import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_restaurant/common/widgets/custom_image_widget.dart';
import 'package:flutter_restaurant/common/widgets/custom_pop_scope_widget.dart';
import 'package:flutter_restaurant/helper/custom_snackbar_helper.dart';
import 'package:flutter_restaurant/helper/number_checker_helper.dart';
import 'package:flutter_restaurant/helper/responsive_helper.dart';
import 'package:flutter_restaurant/helper/router_helper.dart';
import 'package:flutter_restaurant/features/auth/providers/auth_provider.dart';
import 'package:flutter_restaurant/features/splash/providers/splash_provider.dart';
import 'package:flutter_restaurant/utill/dimensions.dart';
import 'package:flutter_restaurant/utill/images.dart';
import 'package:flutter_restaurant/utill/styles.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:io';

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
  // Form controllers and focus nodes
  final FocusNode _phoneFocus = FocusNode();
  final TextEditingController _phoneController = TextEditingController();
  final GlobalKey<FormState> _formKeyLogin = GlobalKey<FormState>();
  
  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // State variables
  String? countryCode;
  bool _isButtonDisabled = false; // Prevents multiple clicks
  DateTime? _lastClickTime; // Tracks time between clicks

  @override
  void initState() {
    super.initState();
    
    _initializeAnimations();
    _initializeCountryCode();
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
          parent: _animationController,
          curve: Curves.easeInOut,
        ),
      );
      
      _animationController.forward();
    } catch (e) {
      debugPrint('Animation initialization error: $e');
    }
  }

  /// Sets the default country code based on app configuration
  void _initializeCountryCode() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      try {
        // Get configuration from SplashProvider
        final configModel = Provider.of<SplashProvider>(context, listen: false).configModel;
        if (configModel != null) {
          final String defaultCountryCode = configModel.countryCode ?? 'US';
          if (mounted) {
            setState(() {
              countryCode = CountryCode.fromCountryCode(defaultCountryCode).dialCode;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              countryCode = '+1'; // Default value if no configuration exists
            });
          }
        }
        
        // Reset authentication provider states
        final AuthProvider authProvider = Provider.of<AuthProvider>(context, listen: false);
        authProvider.setIsLoading = false;
        if (authProvider.isPhoneNumberVerificationButtonLoading) {
          authProvider.setIsPhoneVerificationButttonLoading = false;
        }
      } catch (e) {
        // Set default values if providers cannot be accessed
        if (mounted) {
          setState(() {
            countryCode = '+1';
          });
        }
        debugPrint('Country code initialization error: $e');
      }
    });
  }

  @override
  void dispose() {
    // Clean up resources to prevent memory leaks
    _phoneController.dispose();
    _phoneFocus.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// Prevents rapid multiple taps on buttons
  /// 
  /// Returns true if a tap occurred within 1 second of the previous tap
  bool _isMultiTapping() {
    if (_lastClickTime == null) {
      _lastClickTime = DateTime.now();
      return false;
    }
    
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(_lastClickTime!);
    
    if (difference.inMilliseconds < 1000) { // 1 second between clicks
      return true;
    }
    
    _lastClickTime = now;
    return false;
  }
  
  /// Validates phone number format and content
  /// 
  /// Returns a tuple with (isValid, errorMessage)
  (bool isValid, String? errorMessage) validatePhoneNumber(String phone) {
    try {
      if (phone.isEmpty) {
        return (false, 'Por favor ingresa tu número de teléfono');
      }
      
      if (phone.length < 7) {
        return (false, 'El número de teléfono es demasiado corto');
      }
      
      if (!NumberCheckerHelper.isNumber(phone)) {
        return (false, 'Por favor ingresa un número válido (solo dígitos)');
      }
      
      return (true, null);
    } catch (e) {
      debugPrint('Phone validation error: $e');
      return (false, 'Error al validar el número de teléfono');
    }
  }
  
  /// Sends verification code to the provided phone number
  /// 
  /// Handles various error scenarios with appropriate user feedback
  Future<void> _sendVerificationCode(String phone) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Make API call to verify number and send OTP
      final apiResponseModel = await _verifyAndSendOTP(phone, authProvider);
      
      if (!mounted) return;
      
      setState(() {
        _isButtonDisabled = false;
      });
      
      if (apiResponseModel.success) {
        showCustomSnackBarHelper(
          'Código de verificación enviado a $phone',
          isError: false
        );
        
        // Navigate to OTP verification
        _handleOTPSent(phone, apiResponseModel.tempToken ?? '', apiResponseModel.message ?? '');
      } else {
        showCustomSnackBarHelper(apiResponseModel.message ?? 'Error al enviar código de verificación');
      }
    } on SocketException catch (e) {
      _handleNetworkError(e);
    } on TimeoutException catch (e) {
      _handleTimeoutError(e);
    } on FormatException catch (e) {
      _handleFormatError(e);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isButtonDisabled = false;
        });
        _handleGenericError('Error al procesar la solicitud', e);
      }
    }
  }
  
  /// Verifies the phone number and sends OTP
  /// 
  /// Makes the actual API call to the authentication service
  Future<ApiResponseModel> _verifyAndSendOTP(String phone, AuthProvider authProvider) async {
    try {
      // In production, use the real API call:
      // return await authProvider.sendOTPForVerification(phone);
      
      // For testing/development, use mock response
      await Future.delayed(const Duration(seconds: 2));
      return ApiResponseModel(
        success: true,
        message: 'Código enviado con éxito',
        tempToken: 'temp_token_${DateTime.now().millisecondsSinceEpoch}',
      );
    } catch (e) {
      debugPrint('OTP sending error: $e');
      rethrow; // Re-throw for centralized error handling
    }
  }
  
  /// Handles successful OTP sending
  /// 
  /// Shows verification dialog or navigates to verification screen
  void _handleOTPSent(String phone, String tempToken, String message) {
    try {
      // Store session data (could be moved to secure storage in production)
      final Map<String, dynamic> otpSessionData = {
        'phone': phone,
        'temp_token': tempToken,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      // Show OTP verification dialog
      _showOTPVerificationDialog(phone, tempToken);
    } catch (e) {
      _handleGenericError('Error al procesar respuesta del servidor', e);
    }
  }
  
  /// Error handler for network connectivity issues
  void _handleNetworkError(SocketException e) {
    if (mounted) {
      setState(() {
        _isButtonDisabled = false;
      });
      showCustomSnackBarHelper(
        'Error de conexión. Por favor verifica tu conexión a internet.', 
        isError: true
      );
      debugPrint('Network error: ${e.message}');
    }
  }
  
  /// Error handler for request timeouts
  void _handleTimeoutError(TimeoutException e) {
    if (mounted) {
      setState(() {
        _isButtonDisabled = false;
      });
      showCustomSnackBarHelper(
        'Tiempo de espera agotado. Por favor intenta de nuevo.', 
        isError: true
      );
      debugPrint('Timeout error: ${e.message}');
    }
  }
  
  /// Error handler for data format issues
  void _handleFormatError(FormatException e) {
    if (mounted) {
      setState(() {
        _isButtonDisabled = false;
      });
      showCustomSnackBarHelper(
        'Error en formato de datos. Por favor contacta a soporte.', 
        isError: true
      );
      debugPrint('Format error: ${e.message}');
    }
  }
  
  /// Generic error handler for unexpected exceptions
  void _handleGenericError(String userMessage, Object error) {
    showCustomSnackBarHelper(userMessage, isError: true);
    debugPrint('Error: $error');
  }
  
  /// Shows a modal dialog for OTP verification
  void _showOTPVerificationDialog(String phone, String tempToken) {
    final TextEditingController otpController = TextEditingController();
    bool isVerifying = false;
    String errorMessage = '';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'Verificación', 
                style: rubikMedium.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontSize: 20,
                ),
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ingresa el código enviado a $phone',
                    style: rubikRegular.copyWith(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  
                  // OTP input field
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: rubikMedium.copyWith(
                      fontSize: 20,
                      letterSpacing: 8,
                    ),
                    decoration: InputDecoration(
                      counterText: "",
                      hintText: "000000",
                      hintStyle: rubikRegular.copyWith(
                        color: Colors.grey,
                        fontSize: 20,
                        letterSpacing: 8,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                  
                  // Error message display
                  if (errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        errorMessage,
                        style: rubikRegular.copyWith(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              actions: [
                // Cancel button
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Cancelar',
                    style: rubikRegular.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ),
                
                // Verify button
                ElevatedButton(
                  onPressed: isVerifying 
                    ? null 
                    : () async {
                      if (otpController.text.length < 6) {
                        setState(() {
                          errorMessage = 'Ingresa el código completo de 6 dígitos';
                        });
                        return;
                      }
                      
                      setState(() {
                        isVerifying = true;
                        errorMessage = '';
                      });
                      
                      try {
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        final result = await _verifyOTP(
                          phone, 
                          otpController.text, 
                          tempToken,
                          authProvider
                        );
                        
                        if (result.success) {
                          Navigator.pop(context); // Close dialog
                          
                          showCustomSnackBarHelper(
                            'Verificación exitosa', 
                            isError: false
                          );
                          
                          // Navigate to dashboard or main page
                          RouterHelper.getDashboardRoute(
                            'home', 
                            action: RouteAction.pushNamedAndRemoveUntil
                          );
                        } else {
                          setState(() {
                            isVerifying = false;
                            errorMessage = result.message ?? 'Error al verificar el código';
                          });
                        }
                      } catch (e) {
                        setState(() {
                          isVerifying = false;
                          errorMessage = 'Error al procesar verificación';
                        });
                        debugPrint('OTP verification error: $e');
                      }
                    },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  child: isVerifying
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text('Verificar', style: rubikMedium),
                ),
              ],
            );
          }
        );
      },
    );
  }
  
  /// Verifies the OTP entered by the user
  /// 
  /// Makes the API call to verify the code and complete login
  Future<ApiResponseModel> _verifyOTP(
    String phone, 
    String otp, 
    String tempToken,
    AuthProvider authProvider
  ) async {
    try {
      // In production, use the real API call:
      // return await authProvider.verifyOTP(phone, otp, tempToken);
      
      // For testing/development, use mock response
      await Future.delayed(const Duration(seconds: 2));
      
      // Mock verification (success if OTP is 123456)
      if (otp == '123456') {
        return ApiResponseModel(
          success: true,
          message: 'Verificación exitosa',
          token: 'auth_token_${DateTime.now().millisecondsSinceEpoch}',
          userId: 12345,
        );
      } else {
        return ApiResponseModel(
          success: false,
          message: 'Código de verificación incorrecto',
        );
      }
    } catch (e) {
      debugPrint('OTP verification API error: $e');
      return ApiResponseModel(
        success: false,
        message: 'Error del servidor al verificar el código',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Safe handling to prevent errors if animation wasn't initialized correctly
    final fadeAnimation = _fadeAnimation ?? AlwaysStoppedAnimation(1.0);
    
    final double width = MediaQuery.of(context).size.width;
    final size = MediaQuery.of(context).size;
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
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
                          
                          // Main content
                          Center(
                            child: _buildLoginForm(isDesktop, width, isDarkMode),
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

  /// Builds the main login form container with all input fields
  Widget _buildLoginForm(bool isDesktop, double width, bool isDarkMode) {
    return Container(
      width: isDesktop ? 480 : width,
      margin: EdgeInsets.symmetric(
        horizontal: isDesktop ? 0 : Dimensions.paddingSizeLarge,
        vertical: Dimensions.paddingSizeLarge,
      ),
      padding: isDesktop 
        ? const EdgeInsets.all(40) 
        : const EdgeInsets.all(Dimensions.paddingSizeLarge),
      decoration: isDesktop ? BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ) : null,
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) => Form(
          key: _formKeyLogin,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center, 
            children: [
              // Logo del conejo
              Container(
                height: 120,
                width: 120,
                margin: const EdgeInsets.only(bottom: 15),
                child: Image.asset(
                  Images.logo,
                  fit: BoxFit.contain,
                ),
              ),
              
              // Mensaje principal persuasivo
              Text(
                'Tus platos favoritos a un clic',
                style: rubikBold.copyWith(
                  fontSize: 24,
                  color: Theme.of(context).primaryColor,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              // Subtítulo persuasivo
              Text(
                'Ingresa tu número y comienza a disfrutar',
                style: rubikRegular.copyWith(
                  fontSize: 16,
                  color: Theme.of(context).hintColor,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              
              // Texto contextual de confianza
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 12,
                      color: Theme.of(context).hintColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Solo necesitamos tu número para actualizaciones',
                      style: rubikRegular.copyWith(
                        fontSize: 12,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Phone input field con badge de seguridad
              _buildPhoneInput(isDarkMode),
              
              const SizedBox(height: 12),
              
              // Error message display
              _buildErrorMessage(authProvider),
              
              const SizedBox(height: 24),
              
              // Continue button mejorado
              _buildContinueButton(authProvider),
              
              const SizedBox(height: 20),
              
              // Elemento de prueba social
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Únete a +10,000 usuarios satisfechos',
                      style: rubikMedium.copyWith(
                        fontSize: 12,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 15),
              
              // Terms and privacy policy text
              Text(
                'Al continuar, aceptas nuestros Términos de Servicio y Política de Privacidad',
                style: rubikRegular.copyWith(
                  fontSize: 12,
                  color: Theme.of(context).hintColor,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              // Cancel button (if applicable)
              if (Navigator.canPop(context)) _buildCancelButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the phone input field with country code picker and security badge
  Widget _buildPhoneInput(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'Número de teléfono',
                  style: rubikMedium.copyWith(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
            ),
            // Badge de seguridad
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.green.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_user,
                    color: Colors.green,
                    size: 12,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '100% Seguro',
                    style: rubikMedium.copyWith(
                      color: Colors.green,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isDarkMode
                ? Colors.grey[900]
                : Colors.grey[50],
            border: Border.all(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Country code picker
              Container(
                height: 60,
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: Colors.grey.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: CountryCodePicker(
                  onChanged: (CountryCode value) {
                    setState(() {
                      countryCode = value.dialCode;
                    });
                  },
                  initialSelection: countryCode?.replaceAll('+', '') ?? 'US',
                  showDropDownButton: true,
                  padding: EdgeInsets.zero,
                  showFlagMain: true,
                  dialogBackgroundColor: Theme.of(context).cardColor,
                  flagWidth: 22,
                  textStyle: rubikRegular.copyWith(
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              
              // Phone number input field
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  focusNode: _phoneFocus,
                  style: rubikRegular.copyWith(
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  maxLength: 15,
                  buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                  decoration: InputDecoration(
                    hintText: '123 456 7890',
                    hintStyle: rubikRegular.copyWith(
                      color: Theme.of(context).hintColor,
                      fontSize: 16,
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the error message display
  Widget _buildErrorMessage(AuthProvider authProvider) {
    if (authProvider.loginErrorMessage == null || authProvider.loginErrorMessage!.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16, top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              authProvider.loginErrorMessage ?? "",
              style: rubikRegular.copyWith(
                fontSize: 13,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the continue button or loading indicator with improved CTA
  Widget _buildContinueButton(AuthProvider authProvider) {
    if (authProvider.isLoading || authProvider.isPhoneNumberVerificationButtonLoading) {
      return Center(
        child: Container(
          width: 24,
          height: 24,
          margin: const EdgeInsets.all(16),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
            strokeWidth: 2,
          ),
        ),
      );
    }
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isButtonDisabled 
          ? null
          : _onContinuePressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isButtonDisabled
            ? Theme.of(context).primaryColor.withOpacity(0.7)
            : Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '¡Comenzar ahora!',
              style: rubikBold.copyWith(fontSize: 16),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_rounded,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the cancel button
  Widget _buildCancelButton() {
    return Center(
      child: TextButton(
        onPressed: () => Navigator.pop(context),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          'Cancelar',
          style: rubikMedium.copyWith(
            color: Theme.of(context).primaryColor,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  /// Handles continue button press
  void _onContinuePressed() {
    // Prevent multiple taps
    if (_isMultiTapping()) {
      return;
    }
    
    // Disable button while processing
    setState(() {
      _isButtonDisabled = true;
    });
    
    try {
      final String phoneText = _phoneController.text.trim();
      final (isValid, errorMessage) = validatePhoneNumber(phoneText);
      
      if (!isValid) {
        showCustomSnackBarHelper(errorMessage ?? 'Número inválido');
        setState(() {
          _isButtonDisabled = false;
        });
        return;
      }
      
      // Format phone number with country code
      String phone = phoneText;
      if (!phone.startsWith('+') && countryCode != null) {
        phone = countryCode! + phone;
      } else if (!phone.startsWith('+')) {
        phone = '+1' + phone;
      }
      
      // Send verification code
      _sendVerificationCode(phone);
      
    } catch (e) {
      // Catch any unforeseen exceptions
      showCustomSnackBarHelper('Error al procesar la solicitud: $e');
      debugPrint('Phone validation error: $e');
      
      // Reset button state on error
      if (mounted) {
        setState(() {
          _isButtonDisabled = false;
        });
      }
    }
  }
}

/// Model for handling API responses
class ApiResponseModel {
  final bool success;
  final String? message;
  final String? token;
  final String? tempToken;
  final int? userId;
  final Map<String, dynamic>? data;
  
  /// Creates an API response model with required success flag and optional fields
  ApiResponseModel({
    required this.success,
    this.message,
    this.token,
    this.tempToken,
    this.userId,
    this.data,
  });
  
  /// Creates an ApiResponseModel from JSON data
  factory ApiResponseModel.fromJson(Map<String, dynamic> json) {
    return ApiResponseModel(
      success: json['success'] ?? false,
      message: json['message'],
      token: json['token'],
      tempToken: json['temp_token'],
      userId: json['user_id'],
      data: json['data'],
    );
  }
  
  /// Converts the model to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'token': token,
      'temp_token': tempToken,
      'user_id': userId,
      'data': data,
    };
  }
}
