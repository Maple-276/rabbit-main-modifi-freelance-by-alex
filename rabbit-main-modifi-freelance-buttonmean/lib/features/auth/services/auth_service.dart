import 'package:flutter/material.dart';
import 'package:flutter_restaurant/features/auth/models/auth_response_model.dart';
import 'package:flutter_restaurant/features/auth/providers/auth_provider.dart';
import 'package:flutter_restaurant/helper/number_checker_helper.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart' as fb_auth; // Use prefix fb_auth

/// Service to handle authentication-related operations
class AuthService {
  final AuthProvider _authProvider;
  final fb_auth.FirebaseAuth _firebaseAuth = fb_auth.FirebaseAuth.instance; // Use prefix

  // Store verification ID and token for later use
  String? _verificationId;
  int? _resendToken;

  // Local storage for development/demo mode (can be removed later)
  final Map<String, String> _otpStorage = {};

  AuthService(this._authProvider);

  /// Sends verification code to phone number using Firebase Auth
  ///
  /// Returns a response with success status and message.
  /// The verificationId and resendToken are stored internally.
  Future<AuthResponseModel> sendVerificationCode(String phoneNumber) async {
    // Reset stored values
    _verificationId = null;
    _resendToken = null;

    Completer<AuthResponseModel> completer = Completer();

    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber, // Make sure phoneNumber includes country code, e.g., +11234567890
        
        verificationCompleted: (fb_auth.PhoneAuthCredential credential) async {
          // Auto-retrieval or instant verification (Android only)
          debugPrint('Firebase Auth: Verification Completed Automatically');
          try {
            // Sign in directly
            fb_auth.UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
            String? firebaseToken = await userCredential.user?.getIdToken();
            debugPrint('Firebase Auth: Auto Sign-in successful.');
            // Complete with success and Firebase token
            if (!completer.isCompleted) {
              completer.complete(AuthResponseModel(
                success: true,
                message: 'Verification successful (auto)',
                token: firebaseToken, // Actual Firebase token
                userId: userCredential.user?.uid.hashCode, // Or use a different way to get a user ID
              ));
            }
          } on fb_auth.FirebaseAuthException catch (e) {
             debugPrint('Firebase Auth: Auto Sign-in Error: ${e.code} - ${e.message}');
             if (!completer.isCompleted) {
              completer.complete(AuthResponseModel(success: false, message: 'Auto verification failed: ${e.message}'));
            }
          }
        },

        verificationFailed: (fb_auth.FirebaseAuthException e) {
          debugPrint('Firebase Auth: Verification Failed: ${e.code} - ${e.message}');
          // Handle errors like invalid phone number, quota exceeded, etc.
          String errorMessage = 'Verification failed: ${e.message}';
          if (e.code == 'invalid-phone-number') {
            errorMessage = 'Invalid phone number provided.';
          } else if (e.code == 'too-many-requests') {
            errorMessage = 'Too many requests. Please try again later.';
          }
          if (!completer.isCompleted) {
            completer.complete(AuthResponseModel(success: false, message: errorMessage));
          }
        },

        codeSent: (String verificationId, int? resendToken) {
          debugPrint('Firebase Auth: Code Sent. Verification ID: $verificationId');
          // Store verificationId and resendToken to use when verifying the code manually
          _verificationId = verificationId;
          _resendToken = resendToken;
          // Complete with success, indicating code was sent
           if (!completer.isCompleted) {
            completer.complete(AuthResponseModel(
              success: true,
              message: 'Verification code sent successfully.',
              // Pass verificationId back if needed by the UI/Provider layer
              // tempToken: verificationId, 
            ));
          }
        },

        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('Firebase Auth: Code Auto Retrieval Timeout. Verification ID: $verificationId');
          // Called when auto-retrieval times out (Android only)
          // Store verificationId if not already stored
          _verificationId ??= verificationId;
          // You might want to inform the user or just wait for manual code entry
          // No need to complete the completer here usually, as codeSent should have fired.
        },

        // Optional: Force resent token for subsequent attempts
        forceResendingToken: _resendToken,
        
        // Optional: Timeout duration
        // timeout: const Duration(seconds: 60), 
      );
    } catch (e) {
      debugPrint('Firebase Auth: Error calling verifyPhoneNumber: $e');
       if (!completer.isCompleted) {
        completer.complete(AuthResponseModel(success: false, message: 'Error initiating verification: $e'));
      }
    }

    // Return the future from the completer
    return completer.future;
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
    required String phone, // Phone might not be needed if verificationId is global
    required String otp, 
    // required String tempToken, // We will use the stored _verificationId instead
  }) async {
    // Check if we have a verificationId stored from codeSent
    if (_verificationId == null) {
      return AuthResponseModel(success: false, message: 'Verification process not initiated or timed out.');
    }

    try {
      // Create the credential
      fb_auth.PhoneAuthCredential credential = fb_auth.PhoneAuthProvider.credential(
        verificationId: _verificationId!, 
        smsCode: otp,
      );

      // Sign the user in (or link) with the credential
      fb_auth.UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      String? firebaseToken = await userCredential.user?.getIdToken(); // Get the actual Firebase ID token

      debugPrint('Firebase Auth: Manual Sign-in successful.');

      // Clear stored verification ID after successful sign-in
      _verificationId = null;
      _resendToken = null;

      return AuthResponseModel(
        success: true,
        message: 'Verification successful',
        token: firebaseToken, // Return the real Firebase token
        userId: userCredential.user?.uid.hashCode, // Or use user.uid directly if needed as String
      );

    } on fb_auth.FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth: Sign-in Error: ${e.code} - ${e.message}');
      String errorMessage = 'Verification failed: ${e.message}';
      if (e.code == 'invalid-verification-code') {
        errorMessage = 'Incorrect verification code.';
      } else if (e.code == 'session-expired') {
         errorMessage = 'The code has expired. Please request a new one.';
      }
      return AuthResponseModel(success: false, message: errorMessage);

    } catch (e) {
      debugPrint('Firebase Auth: Unexpected error during sign-in: $e');
      return AuthResponseModel(success: false, message: 'An unexpected error occurred during verification.');
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