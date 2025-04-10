import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_restaurant/features/auth/models/auth_response_model.dart';
import 'package:flutter_restaurant/features/auth/services/auth_service.dart';
import 'package:flutter_restaurant/helper/custom_snackbar_helper.dart';
import 'package:flutter_restaurant/helper/router_helper.dart';
import 'package:flutter_restaurant/utill/styles.dart';
import 'package:intl/intl.dart';
import 'package:flutter_restaurant/localization/language_constrants.dart';

/// A dialog widget for OTP verification
class OtpVerificationDialog extends StatefulWidget {
  final String phone;
  final String tempToken;
  final AuthService authService;
  final VoidCallback? onVerificationSuccess;

  const OtpVerificationDialog({
    Key? key,
    required this.phone,
    required this.tempToken,
    required this.authService,
    this.onVerificationSuccess,
  }) : super(key: key);

  @override
  State<OtpVerificationDialog> createState() => _OtpVerificationDialogState();
}

class _OtpVerificationDialogState extends State<OtpVerificationDialog> {
  // Controllers
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  
  // State
  bool _isVerifying = false;
  bool _isResending = false;
  String _errorMessage = '';
  
  // Resend Timer
  Timer? _resendTimer;
  int _remainingSeconds = 60; // 1 minute expiration
  bool get _canResend => _remainingSeconds <= 0;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }
  
  void _startResendTimer() {
    _cancelResendTimer();
    
    setState(() {
      _remainingSeconds = 60;
    });
    
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _cancelResendTimer();
      }
    });
  }
  
  void _cancelResendTimer() {
    _resendTimer?.cancel();
    _resendTimer = null;
  }
  
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    // Resource cleanup
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _cancelResendTimer();
    super.dispose();
  }
  
  // Combines all OTP code digits
  String get _otpCode => _controllers.map((controller) => controller.text).join();
  
  // Checks if the OTP code is complete
  bool get _isOtpComplete => _otpCode.length == 6;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Text(
        'Verification', 
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
            'Enter the code sent to ${widget.phone}',
            style: rubikRegular.copyWith(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          // Timer
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.timer,
                size: 16,
                color: _canResend 
                    ? Colors.red 
                    : Theme.of(context).hintColor,
              ),
              const SizedBox(width: 4),
              Text(
                _canResend
                    ? 'Code expired'
                    : 'Expires in ${_formatTime(_remainingSeconds)}',
                style: rubikRegular.copyWith(
                  fontSize: 12,
                  color: _canResend 
                      ? Colors.red 
                      : Theme.of(context).hintColor,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // OTP input fields
          _buildOtpInputFields(),
          
          // Error message display
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: rubikRegular.copyWith(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
          // Resend code
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: TextButton(
              onPressed: _canResend && !_isResending ? _resendCode : null,
              child: _isResending
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Sending...',
                        style: rubikRegular.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ],
                  )
                : Text(
                    _canResend
                        ? 'Resend code'
                        : 'Resend in ${_formatTime(_remainingSeconds)}',
                    style: rubikMedium.copyWith(
                      color: _canResend
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).hintColor,
                    ),
                  ),
            ),
          ),
        ],
      ),
      actions: [
        // Cancel button
        TextButton(
          onPressed: _isVerifying ? null : () => Navigator.pop(context),
          child: Text(
            getTranslated('cancel', context) ?? 'Cancel',
            style: rubikRegular.copyWith(
              color: _isVerifying ? Colors.grey : Colors.grey.shade700,
            ),
          ),
        ),
        
        // Verify button
        ElevatedButton(
          onPressed: (_isOtpComplete && !_isVerifying) ? _verifyOTP : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          child: _isVerifying
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text('Verify', style: rubikMedium),
        ),
      ],
    );
  }
  
  /// Builds the input fields for the OTP code
  Widget _buildOtpInputFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        6,
        (index) => Container(
          width: 40,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _focusNodes[index].hasFocus
                  ? Theme.of(context).primaryColor
                  : Colors.grey.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            onChanged: (value) => _handleOtpDigitInput(index, value),
            style: rubikMedium.copyWith(fontSize: 20),
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
          ),
        ),
      ),
    );
  }
  
  /// Handles digit input in the OTP field
  void _handleOtpDigitInput(int index, String value) {
    // Auto-advance to the next field when a digit is entered
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    
    // Auto-backspace when a digit is deleted
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    
    // Update error state and automatically verify if the code is complete
    setState(() {
      _errorMessage = '';
    });
    
    if (_isOtpComplete && !_isVerifying) {
      // Short delay for visual feedback
      Future.delayed(const Duration(milliseconds: 100), _verifyOTP);
    }
  }
  
  /// Resends the OTP code
  Future<void> _resendCode() async {
    if (_isResending || !_canResend) return;
    
    setState(() {
      _isResending = true;
      _errorMessage = '';
    });
    
    try {
      final result = await widget.authService.sendVerificationCode(widget.phone);
      
      if (!mounted) return;
      
      if (result.success) {
        // Reset timer
        _startResendTimer();
        
        // Clear OTP fields
        for (var controller in _controllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('New code sent to ${widget.phone}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _errorMessage = result.message ?? 'Error resending code';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error resending code: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  /// Verifies the OTP code entered by the user
  Future<void> _verifyOTP() async {
    if (_isVerifying) return;
    
    // Get the complete code
    final completeOtp = _otpCode;
    
    if (completeOtp.length < 6) {
      setState(() {
        _errorMessage = 'Enter the complete 6-digit code';
      });
      return;
    }
    
    // Set loading state
    setState(() {
      _isVerifying = true;
      _errorMessage = '';
    });
    
    try {
      // Call auth service to verify OTP
      final AuthResponseModel result = await widget.authService.verifyOTP(
        phone: widget.phone, 
        otp: completeOtp, 
        tempToken: widget.tempToken,
      );
      
      if (!mounted) return;
      
      if (result.success) {
        // Close dialog
        Navigator.pop(context);
        
        // Show success message
        showCustomSnackBarHelper(
          'Verification successful', 
          isError: false
        );
        
        // Call success callback
        if (widget.onVerificationSuccess != null) {
          widget.onVerificationSuccess!();
        } else {
          // Default navigation if no callback provided
          RouterHelper.getDashboardRoute(
            'home', 
            action: RouteAction.pushNamedAndRemoveUntil
          );
        }
      } else {
        // Show error message
        setState(() {
          _isVerifying = false;
          _errorMessage = result.message ?? 'Error verifying code';
          
          // Clear OTP fields on error
          for (var controller in _controllers) {
            controller.clear();
          }
          _focusNodes[0].requestFocus();
        });
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isVerifying = false;
        _errorMessage = 'Error processing verification: $e';
        
        // Clear OTP fields on error
        for (var controller in _controllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      });
      debugPrint('OTP verification error: $e');
    }
  }
} 