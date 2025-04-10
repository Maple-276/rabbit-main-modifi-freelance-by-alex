import 'package:flutter/material.dart';
import 'package:flutter_restaurant/features/auth/models/auth_response_model.dart';
import 'package:flutter_restaurant/features/auth/providers/auth_provider.dart';
import 'package:flutter_restaurant/helper/number_checker_helper.dart';
import 'dart:async';
import 'dart:math' as math;

/// Service to handle authentication-related operations
class AuthService {
  final AuthProvider _authProvider;
  
  // Local storage for development/demo mode
  final Map<String, String> _otpStorage = {};

  AuthService(this._authProvider);

  /// Sends verification code to phone number
  ///
  /// Returns a response with success status and token information
  Future<AuthResponseModel> sendVerificationCode(String phone) async {
    try {
      // If we were in production, uncomment the following line:
      // return await _sendOTPViaAPI(phone);
      
      // For development/demonstration, we use a locally generated OTP
      return await _sendMockOTP(phone);
    } catch (e) {
      debugPrint('OTP sending error: $e');
      return AuthResponseModel(
        success: false,
        message: 'Error sending code: $e',
      );
    }
  }
  
  /// Method that calls the real API to send OTP (for production)
  Future<AuthResponseModel> _sendOTPViaAPI(String phone) async {
    try {
      // Here we would implement the actual API call
      // Example:
      // final apiResponse = await _authProvider.sendOTPForVerification(phone);
      // return AuthResponseModel.fromJson(apiResponse.data);
      
      // As a placeholder, we return an error
      throw UnimplementedError('OTP API not implemented');
    } catch (e) {
      rethrow;
    }
  }
  
  /// Method that simulates sending OTP for development/demonstration
  Future<AuthResponseModel> _sendMockOTP(String phone) async {
    await Future.delayed(const Duration(seconds: 1));
    
    try {
      // Generate a random 6-digit OTP code
      final String otp = _generateOTP();
      
      // In a real app, this would be sent via SMS
      // Here we save it in memory for verification
      _otpStorage[phone] = otp;
      
      // For demo/development, we show the OTP in the console
      debugPrint('💬 OTP for $phone: $otp');
      
      // Simulate a temporary token
      final tempToken = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      
      return AuthResponseModel(
        success: true,
        message: 'Code sent successfully to $phone',
        tempToken: tempToken,
      );
    } catch (e) {
      debugPrint('Error generating OTP: $e');
      return AuthResponseModel(
        success: false,
        message: 'Error generating verification code',
      );
    }
  }
  
  /// Generates a random 6-digit OTP code
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
      // If we were in production, uncomment the following line:
      // return await _verifyOTPViaAPI(phone, otp, tempToken);
      
      // For development/demonstration, we verify against local storage
      return await _verifyMockOTP(phone, otp, tempToken);
    } catch (e) {
      debugPrint('OTP verification error: $e');
      return AuthResponseModel(
        success: false,
        message: 'Error verifying code: $e',
      );
    }
  }
  
  /// Method that calls the real API to verify OTP (for production)
  Future<AuthResponseModel> _verifyOTPViaAPI(String phone, String otp, String tempToken) async {
    try {
      // Here we would implement the actual API call
      // Example:
      // final apiResponse = await _authProvider.verifyOTP(phone, otp, tempToken);
      // return AuthResponseModel.fromJson(apiResponse.data);
      
      // As a placeholder, we return an error
      throw UnimplementedError('OTP verification API not implemented');
    } catch (e) {
      rethrow;
    }
  }
  
  /// Method that simulates OTP verification for development/demonstration
  Future<AuthResponseModel> _verifyMockOTP(String phone, String otp, String tempToken) async {
    await Future.delayed(const Duration(milliseconds: 1500));
    
    try {
      // Get the stored OTP for the phone
      final storedOTP = _otpStorage[phone];
      
      // If there is no stored OTP or it has expired
      if (storedOTP == null) {
        return AuthResponseModel(
          success: false,
          message: 'The code has expired. Please request a new one.',
        );
      }
      
      // Compare the entered OTP with the stored one
      if (otp == storedOTP) {
        // Clear the used OTP
        _otpStorage.remove(phone);
        
        // In a real app, here we would get an authentication token
        // Simulate an authentication token
        final token = 'auth_${DateTime.now().millisecondsSinceEpoch}';
        
        return AuthResponseModel(
          success: true,
          message: 'Verification successful',
          token: token,
          userId: 12345, // Simulated ID
        );
      } else if (otp == '123456') {
        // Bypass code for testing
        return AuthResponseModel(
          success: true,
          message: 'Verification successful (master code)',
          token: 'auth_master_token',
          userId: 12345,
        );
      } else {
        return AuthResponseModel(
          success: false,
          message: 'Incorrect verification code',
        );
      }
    } catch (e) {
      debugPrint('Error verifying OTP: $e');
      return AuthResponseModel(
        success: false,
        message: 'Error verifying code',
      );
    }
  }

  /// Validates phone number format and content
  ///
  /// Returns validation result with error message if invalid
  (bool isValid, String? errorMessage) validatePhoneNumber(String phone) {
    try {
      if (phone.isEmpty) {
        return (false, 'Please enter your phone number');
      }
      
      if (phone.length < 7) {
        return (false, 'The phone number is too short');
      }
      
      if (!NumberCheckerHelper.isNumber(phone)) {
        return (false, 'Please enter a valid number (digits only)');
      }
      
      return (true, null);
    } catch (e) {
      debugPrint('Phone validation error: $e');
      return (false, 'Error validating phone number');
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

  /// ```
  Future<String?> signInWithEmailAndPassword(String email, String password) async {
    // Simulate API call for email/password login
    await Future.delayed(const Duration(seconds: 1)); 

    // Example:
    if (email == 'test@example.com' && password == 'password') {
      // Simulate successful login, return a token
      return 'fake-email-auth-token';
    } else {
      // Simulate login failure
      throw Exception('Invalid credentials');
    }
  }

  /// Signs in using Google credentials.
  /// Returns a token on success, throws exception on failure.
  Future<String?> signInWithGoogle() async {
    // Simulate Google Sign-In flow
    await Future.delayed(const Duration(seconds: 1));
    // Simulate successful Google login
    return 'fake-google-auth-token'; 
  }

  /// Registers a new user with email and password.
  /// Returns a temporary token if verification is needed, or null on failure.
  Future<String?> registerWithEmailAndPassword(String email, String password) async {
    // Simulate API call for registration
    await Future.delayed(const Duration(seconds: 1)); 

    // Assume registration requires email verification
    // Simulate a temporary token
    return 'fake-temp-verification-token'; 
  }

  /// Verifies an OTP or verification code.
  /// Returns a final auth token on success, throws exception on failure.
  Future<String?> verifyCode(String code, {String? tempToken}) async {
    // Simulate API call to verify the code
    await Future.delayed(const Duration(seconds: 1));

    if (code == '123456' && tempToken != null) {
      // Simulate successful verification, return final token
      return 'final-auth-token-after-verification';
    } else {
      // Simulate verification failure
      throw Exception('Invalid verification code');
    }
  }

  /// Sends a password reset request.
  Future<void> sendPasswordResetEmail(String email) async {
    // Simulate API call to send reset email
    await Future.delayed(const Duration(seconds: 1));
    // Assume success
  }

  /// Logs the user out.
  Future<void> signOut() async {
    // Simulate clearing local session data
    await Future.delayed(const Duration(milliseconds: 500));
    // Assume success
  }

  /// Checks if a phone number exists.
  /// Returns true if exists, false otherwise.
  Future<bool> checkPhoneExists(String phoneNumber) async {
     // Simulate API call
     await Future.delayed(const Duration(milliseconds: 800));
     // Example:
     return phoneNumber == '+11234567890'; // Assume this number exists
  }
} 