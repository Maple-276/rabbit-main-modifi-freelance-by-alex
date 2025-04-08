import 'package:flutter/material.dart';
import 'package:flutter_restaurant/features/auth/providers/auth_provider.dart';
import 'package:flutter_restaurant/features/auth/services/auth_service.dart';
import 'package:flutter_restaurant/features/auth/widgets/phone_input_widget.dart';
import 'package:flutter_restaurant/helper/custom_snackbar_helper.dart';
import 'package:flutter_restaurant/utill/dimensions.dart';
import 'package:flutter_restaurant/utill/images.dart';
import 'package:flutter_restaurant/utill/styles.dart';
import 'package:provider/provider.dart';

/// Widget that displays the login form with phone input and persuasive UI elements
class LoginFormWidget extends StatefulWidget {
  final AuthService authService;
  final Function(String, String) onOtpSent;
  
  const LoginFormWidget({
    Key? key,
    required this.authService,
    required this.onOtpSent,
  }) : super(key: key);

  @override
  State<LoginFormWidget> createState() => _LoginFormWidgetState();
}

class _LoginFormWidgetState extends State<LoginFormWidget> {
  final FocusNode _phoneFocus = FocusNode();
  final TextEditingController _phoneController = TextEditingController();
  final GlobalKey<FormState> _formKeyLogin = GlobalKey<FormState>();
  
  String? _countryCode = '+1';
  bool _isButtonDisabled = false;
  DateTime? _lastClickTime;

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isDesktop = width > 900;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
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
              
              // Phone input
              PhoneInputWidget(
                controller: _phoneController,
                focusNode: _phoneFocus,
                countryCode: _countryCode,
                isDarkMode: isDarkMode,
                onCountryChanged: (code) {
                  setState(() {
                    _countryCode = code.dialCode;
                  });
                },
              ),
              
              const SizedBox(height: 12),
              
              // Error message display
              _buildErrorMessage(authProvider),
              
              const SizedBox(height: 24),
              
              // Continue button
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

  /// Builds the continue button or loading indicator
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

  /// Prevents rapid multiple taps on buttons
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
      final (isValid, errorMessage) = widget.authService.validatePhoneNumber(phoneText);
      
      if (!isValid) {
        showCustomSnackBarHelper(errorMessage ?? 'Número inválido');
        setState(() {
          _isButtonDisabled = false;
        });
        return;
      }
      
      // Format phone number with country code
      final String formattedPhone = widget.authService.formatPhoneWithCountryCode(
        phoneText, 
        _countryCode
      );
      
      // Send verification code
      _sendVerificationCode(formattedPhone);
      
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

  /// Sends verification code to the provided phone number
  Future<void> _sendVerificationCode(String phone) async {
    try {
      final result = await widget.authService.sendVerificationCode(phone);
      
      if (!mounted) return;
      
      setState(() {
        _isButtonDisabled = false;
      });
      
      if (result.success) {
        showCustomSnackBarHelper(
          'Código de verificación enviado a $phone',
          isError: false
        );
        
        // Call the OTP sent callback with phone and temp token
        widget.onOtpSent(phone, result.tempToken ?? '');
      } else {
        showCustomSnackBarHelper(result.message ?? 'Error al enviar código de verificación');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isButtonDisabled = false;
        });
        showCustomSnackBarHelper('Error al procesar la solicitud: $e', isError: true);
      }
    }
  }
} 