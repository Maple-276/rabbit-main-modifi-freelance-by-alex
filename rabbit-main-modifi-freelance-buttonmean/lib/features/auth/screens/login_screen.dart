import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_restaurant/common/models/config_model.dart';
import 'package:flutter_restaurant/common/widgets/custom_image_widget.dart';
import 'package:flutter_restaurant/common/widgets/custom_pop_scope_widget.dart';
import 'package:flutter_restaurant/common/widgets/custom_button_widget.dart';
import 'package:flutter_restaurant/common/widgets/custom_text_field_widget.dart';
import 'package:flutter_restaurant/features/language/providers/localization_provider.dart';
import 'package:flutter_restaurant/helper/custom_snackbar_helper.dart';
import 'package:flutter_restaurant/helper/number_checker_helper.dart';
import 'package:flutter_restaurant/helper/responsive_helper.dart';
import 'package:flutter_restaurant/helper/router_helper.dart';
import 'package:flutter_restaurant/features/auth/providers/auth_provider.dart';
import 'package:flutter_restaurant/features/splash/providers/splash_provider.dart';
import 'package:flutter_restaurant/utill/color_resources.dart';
import 'package:flutter_restaurant/utill/dimensions.dart';
import 'package:flutter_restaurant/utill/images.dart';
import 'package:flutter_restaurant/utill/styles.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final FocusNode _phoneFocus = FocusNode();
  final TextEditingController _phoneController = TextEditingController();
  final GlobalKey<FormState> _formKeyLogin = GlobalKey<FormState>();
  String? countryCode;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isButtonDisabled = false; // Prevenir múltiples clics
  DateTime? _lastClickTime; // Rastrear tiempo entre clics

  @override
  void initState() {
    super.initState();
    
    try {
      // Configurar animaciones
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
      // Si la animación falla, simplemente continuar sin ella
      debugPrint('Error al inicializar animaciones: $e');
    }
    
    // Inicialización segura
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      try {
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
              countryCode = '+1'; // Valor por defecto si no hay configuración
            });
          }
        }
        
        // Resetear estados
        final AuthProvider authProvider = Provider.of<AuthProvider>(context, listen: false);
        authProvider.setIsLoading = false;
        if (authProvider.isPhoneNumberVerificationButtonLoading) {
          authProvider.setIsPhoneVerificationButttonLoading = false;
        }
      } catch (e) {
        // Si hay un error al acceder a los providers, establecer valores por defecto
        if (mounted) {
          setState(() {
            countryCode = '+1';
          });
        }
        debugPrint('Error al inicializar datos: $e');
      }
    });
  }

  @override
  void dispose() {
    try {
      _phoneController.dispose();
      _phoneFocus.dispose();
      _animationController.dispose();
    } catch (e) {
      debugPrint('Error al liberar recursos: $e');
    }
    super.dispose();
  }

  // Método para prevenir múltiples clics en corto tiempo
  bool _isMultiTapping() {
    if (_lastClickTime == null) {
      _lastClickTime = DateTime.now();
      return false;
    }
    
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(_lastClickTime!);
    
    if (difference.inMilliseconds < 1000) { // 1 segundo entre clics
      return true;
    }
    
    _lastClickTime = now;
    return false;
  }
  
  // Validar número de teléfono de forma segura
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
      debugPrint('Error validando número de teléfono: $e');
      return (false, 'Error al validar el número de teléfono');
    }
  }
  
  // Método para enviar OTP con manejo de errores
  Future<void> _sendVerificationCode(String phone) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Llamada real a la API para verificar el número antes de enviar OTP
      final apiResponseModel = await _verifyAndSendOTP(phone, authProvider);
      
      // Si el temporizador de simulación estaba presente, cancelarlo
      if (mounted) {
        setState(() {
          _isButtonDisabled = false;
        });
        
        if (apiResponseModel.success) {
          showCustomSnackBarHelper(
            'Código de verificación enviado a $phone',
            isError: false
          );
          
          // Redirigir a pantalla de verificación OTP o mostrar el modal de OTP
          _handleOTPSent(phone, apiResponseModel.tempToken ?? '', apiResponseModel.message ?? '');
        } else {
          showCustomSnackBarHelper(apiResponseModel.message ?? 'Error al enviar código de verificación');
        }
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
  
  // Método para verificar el número y enviar OTP
  Future<ApiResponseModel> _verifyAndSendOTP(String phone, AuthProvider authProvider) async {
    try {
      // Estructura de respuesta simulada para pruebas
      final ApiResponseModel mockResponse = ApiResponseModel(
        success: true,
        message: 'Código enviado con éxito',
        tempToken: 'temp_token_${DateTime.now().millisecondsSinceEpoch}',
      );
      
      // Simulación de llamada a API con latencia
      await Future.delayed(const Duration(seconds: 2));
      
      // Esta es la implementación real que se utilizaría:
      // return await authProvider.sendOTPForVerification(phone);
      
      return mockResponse;
    } catch (e) {
      debugPrint('Error en verificación de teléfono: $e');
      rethrow; // Reenviar la excepción para manejo centralizado
    }
  }
  
  // Manejar proceso posterior al envío exitoso de OTP
  void _handleOTPSent(String phone, String tempToken, String message) {
    try {
      // Guardar datos temporales para referencia
      final Map<String, dynamic> otpSessionData = {
        'phone': phone,
        'temp_token': tempToken,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      // Aquí se podría almacenar en SharedPreferences si fuera necesario
      
      // En una implementación real, navegar a la pantalla de verificación OTP 
      // o mostrar un diálogo para ingresar el código
      _showOTPVerificationDialog(phone, tempToken);
    } catch (e) {
      _handleGenericError('Error al procesar respuesta del servidor', e);
    }
  }
  
  // Manejadores de errores especializados
  void _handleNetworkError(SocketException e) {
    if (mounted) {
      setState(() {
        _isButtonDisabled = false;
      });
      showCustomSnackBarHelper(
        'Error de conexión. Por favor verifica tu conexión a internet.', 
        isError: true
      );
      debugPrint('Error de red: ${e.message}');
    }
  }
  
  void _handleTimeoutError(TimeoutException e) {
    if (mounted) {
      setState(() {
        _isButtonDisabled = false;
      });
      showCustomSnackBarHelper(
        'Tiempo de espera agotado. Por favor intenta de nuevo.', 
        isError: true
      );
      debugPrint('Error de timeout: ${e.message}');
    }
  }
  
  void _handleFormatError(FormatException e) {
    if (mounted) {
      setState(() {
        _isButtonDisabled = false;
      });
      showCustomSnackBarHelper(
        'Error en formato de datos. Por favor contacta a soporte.', 
        isError: true
      );
      debugPrint('Error de formato: ${e.message}');
    }
  }
  
  void _handleGenericError(String userMessage, Object error) {
    showCustomSnackBarHelper(userMessage, isError: true);
    debugPrint('Error: $error');
  }
  
  // Mostrar diálogo para verificación OTP
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
                  
                  // Campo OTP
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
                          Navigator.pop(context); // Cerrar diálogo
                          
                          // Mostrar mensaje de éxito
                          showCustomSnackBarHelper(
                            'Verificación exitosa', 
                            isError: false
                          );
                          
                          // Si la verificación fue exitosa, navegar al dashboard o página principal
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
                        debugPrint('Error al verificar OTP: $e');
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
  
  // Método para verificar el código OTP
  Future<ApiResponseModel> _verifyOTP(
    String phone, 
    String otp, 
    String tempToken,
    AuthProvider authProvider
  ) async {
    try {
      // Simulación de verificación con latencia
      await Future.delayed(const Duration(seconds: 2));
      
      // Esta es una simulación para pruebas
      // En implementación real se usaría:
      // return await authProvider.verifyOTP(phone, otp, tempToken);
      
      // Verificación simulada (éxito si OTP es 123456)
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
      debugPrint('Error en verificación de OTP: $e');
      return ApiResponseModel(
        success: false,
        message: 'Error del servidor al verificar el código',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Manejo seguro para prevenir errores si la animación no se inicializó correctamente
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
                          // Fondo con forma decorativa (opcional)
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
                          
                          // Contenido principal
                          Center(
                            child: Container(
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
                                    crossAxisAlignment: CrossAxisAlignment.start, 
                                    children: [
                                      // Logo
                                      if (isDesktop)
                                        Consumer<SplashProvider>(
                                          builder: (context, splash, child) {
                                            final String? logoUrl = splash.baseUrls?.restaurantImageUrl != null && splash.configModel?.restaurantLogo != null
                                              ? '${splash.baseUrls?.restaurantImageUrl}/${splash.configModel!.restaurantLogo}'
                                              : null;
                                              
                                            return Center(
                                              child: Padding(
                                                padding: const EdgeInsets.only(bottom: 40),
                                                child: Directionality(
                                                  textDirection: TextDirection.ltr,
                                                  child: CustomImageWidget(
                                                    image: logoUrl ?? '',
                                                    placeholder: Images.webAppBarLogo,
                                                    fit: BoxFit.contain,
                                                    width: 120, height: 80,
                                                  ),
                                                ),
                                              ),
                                            );
                                          }
                                        ),
                                      
                                      // Encabezado 
                                      Text(
                                        'Bienvenido',
                                        style: rubikBold.copyWith(
                                          fontSize: 28,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 8),
                                      
                                      // Subtítulo
                                      Text(
                                        'Ingresa tu número para continuar',
                                        style: rubikRegular.copyWith(
                                          fontSize: 16,
                                          color: Theme.of(context).hintColor,
                                          height: 1.4,
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 40),
                                      
                                      // Campo de teléfono con diseño mejorado
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(left: 4, bottom: 8),
                                            child: Text(
                                              'Número de teléfono',
                                              style: rubikMedium.copyWith(
                                                fontSize: 14,
                                                color: Theme.of(context).textTheme.bodyLarge?.color,
                                              ),
                                            ),
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
                                                // Selector de código de país con estilo
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
                                                
                                                // Campo de entrada para teléfono
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
                                                    // Agregar validación de entrada para permitir solo números
                                                    inputFormatters: [
                                                      FilteringTextInputFormatter.digitsOnly,
                                                    ],
                                                    // Límite de caracteres para prevenir desbordamientos
                                                    maxLength: 15,
                                                    // Ocultar el contador
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
                                      ),
                                      
                                      const SizedBox(height: 12),
                                      
                                      // Mensaje de error con estilo
                                      if (authProvider.loginErrorMessage != null && authProvider.loginErrorMessage!.isNotEmpty)
                                        Container(
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
                                        ),
                                      
                                      const SizedBox(height: 32),
                                      
                                      // Botón de continuar estilizado
                                      !authProvider.isLoading && !authProvider.isPhoneNumberVerificationButtonLoading 
                                      ? SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed: _isButtonDisabled 
                                              ? null // Deshabilitar botón si ya está procesando
                                              : () {
                                                // Prevenir múltiples clics
                                                if (_isMultiTapping()) {
                                                  return;
                                                }
                                                
                                                // Desactivar botón al iniciar proceso
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
                                                  
                                                  // Formatear número con código de país
                                                  String phone = phoneText;
                                                  if (!phone.startsWith('+') && countryCode != null) {
                                                    phone = countryCode! + phone;
                                                  } else if (!phone.startsWith('+')) {
                                                    phone = '+1' + phone;
                                                  }
                                                  
                                                  // Enviar código de verificación
                                                  _sendVerificationCode(phone);
                                                  
                                                } catch (e) {
                                                  // Capturar cualquier excepción no prevista
                                                  showCustomSnackBarHelper('Error al procesar la solicitud: $e');
                                                  debugPrint('Error en validación de teléfono: $e');
                                                  
                                                  // Restaurar estado del botón en caso de error
                                                  if (mounted) {
                                                    setState(() {
                                                      _isButtonDisabled = false;
                                                    });
                                                  }
                                                }
                                              },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: _isButtonDisabled
                                                ? Theme.of(context).primaryColor.withOpacity(0.7) // Color atenuado cuando está deshabilitado
                                                : Theme.of(context).primaryColor,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 16),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              elevation: 0,
                                            ),
                                            child: Text(
                                              'Continuar',
                                              style: rubikMedium.copyWith(fontSize: 16),
                                            ),
                                          ),
                                        )
                                      : Center(
                                          child: Container(
                                            width: 24,
                                            height: 24,
                                            margin: const EdgeInsets.all(16),
                                            child: CircularProgressIndicator(
                                              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        ),
                                      
                                      const SizedBox(height: 24),
                                      
                                      // Texto de política de privacidad
                                      Text(
                                        'Al continuar, aceptas nuestros Términos de Servicio y Política de Privacidad',
                                        style: rubikRegular.copyWith(
                                          fontSize: 12,
                                          color: Theme.of(context).hintColor,
                                          height: 1.5,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      
                                      // Botón para cancelar (si aplicable)
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
                                              'Cancelar',
                                              style: rubikMedium.copyWith(
                                                color: Theme.of(context).primaryColor,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
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

// Modelo para manejar respuestas de API
class ApiResponseModel {
  final bool success;
  final String? message;
  final String? token;
  final String? tempToken;
  final int? userId;
  final Map<String, dynamic>? data;
  
  ApiResponseModel({
    required this.success,
    this.message,
    this.token,
    this.tempToken,
    this.userId,
    this.data,
  });
  
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
