import 'package:flutter/material.dart';
import 'package:flutter_restaurant/features/auth/models/auth_response_model.dart';
import 'package:flutter_restaurant/features/auth/providers/auth_provider.dart';
import 'package:flutter_restaurant/helper/number_checker_helper.dart';
import 'dart:async';
import 'dart:math' as math;

/// Service to handle authentication-related operations
class AuthService {
  final AuthProvider _authProvider;
  
  // Almacenamiento local para el modo de desarrollo/demo
  final Map<String, String> _otpStorage = {};

  AuthService(this._authProvider);

  /// Sends verification code to phone number
  ///
  /// Returns a response with success status and token information
  Future<AuthResponseModel> sendVerificationCode(String phone) async {
    try {
      // Si estuviéramos en producción, descomenta la siguiente línea:
      // return await _sendOTPViaAPI(phone);
      
      // Para desarrollo/demostración, usamos un OTP generado localmente
      return await _sendMockOTP(phone);
    } catch (e) {
      debugPrint('OTP sending error: $e');
      return AuthResponseModel(
        success: false,
        message: 'Error al enviar código: $e',
      );
    }
  }
  
  /// Método que llama a la API real para enviar OTP (para producción)
  Future<AuthResponseModel> _sendOTPViaAPI(String phone) async {
    try {
      // Aquí implementaríamos la llamada real a la API
      // Por ejemplo:
      // final apiResponse = await _authProvider.sendOTPForVerification(phone);
      // return AuthResponseModel.fromJson(apiResponse.data);
      
      // Como placeholder, devolvemos un error
      throw UnimplementedError('API de OTP no implementada');
    } catch (e) {
      rethrow;
    }
  }
  
  /// Método que simula envío de OTP para desarrollo/demostración
  Future<AuthResponseModel> _sendMockOTP(String phone) async {
    await Future.delayed(const Duration(seconds: 1));
    
    try {
      // Genera un código OTP aleatorio de 6 dígitos
      final String otp = _generateOTP();
      
      // En una app real, esto se enviaría por SMS
      // Aquí lo guardamos en memoria para verificación
      _otpStorage[phone] = otp;
      
      // Para demo/desarrollo, mostramos el OTP en la consola
      debugPrint('💬 OTP para $phone: $otp');
      
      // Simulamos un token temporal
      final tempToken = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      
      return AuthResponseModel(
        success: true,
        message: 'Código enviado con éxito a $phone',
        tempToken: tempToken,
      );
    } catch (e) {
      debugPrint('Error generando OTP: $e');
      return AuthResponseModel(
        success: false,
        message: 'Error al generar código de verificación',
      );
    }
  }
  
  /// Genera un código OTP aleatorio de 6 dígitos
  String _generateOTP() {
    final math.Random random = math.Random();
    return List.generate(6, (_) => random.nextInt(10)).join();
  }

  /// Verifies OTP code entered by user
  ///
  /// Returns authentication result with token on success
  Future<AuthResponseModel> verifyOTP({
    required String phone, 
    required String otp, 
    required String tempToken,
  }) async {
    try {
      // Si estuviéramos en producción, descomenta la siguiente línea:
      // return await _verifyOTPViaAPI(phone, otp, tempToken);
      
      // Para desarrollo/demostración, verificamos contra almacenamiento local
      return await _verifyMockOTP(phone, otp, tempToken);
    } catch (e) {
      debugPrint('OTP verification error: $e');
      return AuthResponseModel(
        success: false,
        message: 'Error al verificar el código: $e',
      );
    }
  }
  
  /// Método que llama a la API real para verificar OTP (para producción)
  Future<AuthResponseModel> _verifyOTPViaAPI(String phone, String otp, String tempToken) async {
    try {
      // Aquí implementaríamos la llamada real a la API
      // Por ejemplo:
      // final apiResponse = await _authProvider.verifyOTP(phone, otp, tempToken);
      // return AuthResponseModel.fromJson(apiResponse.data);
      
      // Como placeholder, devolvemos un error
      throw UnimplementedError('API de verificación OTP no implementada');
    } catch (e) {
      rethrow;
    }
  }
  
  /// Método que simula verificación de OTP para desarrollo/demostración
  Future<AuthResponseModel> _verifyMockOTP(String phone, String otp, String tempToken) async {
    await Future.delayed(const Duration(milliseconds: 1500));
    
    try {
      // Obtiene el OTP almacenado para el teléfono
      final storedOTP = _otpStorage[phone];
      
      // Si no hay OTP almacenado o ha expirado
      if (storedOTP == null) {
        return AuthResponseModel(
          success: false,
          message: 'El código ha expirado. Solicita uno nuevo.',
        );
      }
      
      // Compara el OTP ingresado con el almacenado
      if (otp == storedOTP) {
        // Limpia el OTP usado
        _otpStorage.remove(phone);
        
        // En una app real, aquí obtendríamos un token de autenticación
        // Simulamos un token de autenticación
        final token = 'auth_${DateTime.now().millisecondsSinceEpoch}';
        
        return AuthResponseModel(
          success: true,
          message: 'Verificación exitosa',
          token: token,
          userId: 12345, // ID simulado
        );
      } else if (otp == '123456') {
        // Código de bypass para testing
        return AuthResponseModel(
          success: true,
          message: 'Verificación exitosa (código maestro)',
          token: 'auth_master_token',
          userId: 12345,
        );
      } else {
        return AuthResponseModel(
          success: false,
          message: 'Código de verificación incorrecto',
        );
      }
    } catch (e) {
      debugPrint('Error verificando OTP: $e');
      return AuthResponseModel(
        success: false,
        message: 'Error al verificar código',
      );
    }
  }

  /// Validates phone number format and content
  ///
  /// Returns validation result with error message if invalid
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

  /// Formats phone number with country code
  ///
  /// Ensures phone number has proper country code prefix
  String formatPhoneWithCountryCode(String phoneNumber, String? countryCode) {
    if (phoneNumber.startsWith('+')) {
      return phoneNumber;
    }
    
    if (countryCode != null) {
      return countryCode + phoneNumber;
    }
    
    return '+1' + phoneNumber; // Default country code
  }
} 