import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_restaurant/common/widgets/custom_asset_image_widget.dart';
import 'package:flutter_restaurant/helper/responsive_helper.dart';
import 'package:flutter_restaurant/localization/language_constrants.dart';
import 'package:flutter_restaurant/main.dart';
import 'package:flutter_restaurant/utill/dimensions.dart';
import 'package:flutter_restaurant/utill/images.dart';
import 'package:flutter_restaurant/utill/styles.dart';

/// Defines the type of SnackBar to display in the application.
/// Used to control visual appearance and behavior of notifications.
///
/// Available types:
/// - [SnackBarType.error]: For error messages and failed operations
/// - [SnackBarType.success]: For successful operations
/// - [SnackBarType.info]: For general information and neutral messages
/// - [SnackBarType.cart]: For cart-related notifications (add/remove items)
enum SnackBarType {
  error,     // For error messages
  success,   // For success messages
  info,      // For general information
  cart       // For cart-related notifications
}

/// Shows a custom snackbar with optional animation based on the message type.
/// Optimized for performance on low-end devices while maintaining visual appeal.
/// 
/// Parameters:
/// - [message]: The text message to display in the snackbar
/// - [isError]: Legacy parameter to determine if error style should be used
/// - [isToast]: Whether to display as a toast-style notification
/// - [type]: The SnackBarType to determine styling and icon
/// - [duration]: How long the snackbar should remain visible
/// - [showProgressBar]: Whether to show a countdown progress indicator
/// 
/// Usage examples:
/// ```dart
/// // Show success message
/// showCustomSnackBarHelper(
///   'Item added to cart',
///   isError: false,
///   type: SnackBarType.success
/// );
/// 
/// // Show error with progress bar
/// showCustomSnackBarHelper(
///   'Connection failed',
///   type: SnackBarType.error,
///   showProgressBar: true
/// );
/// ```
void showCustomSnackBarHelper(String? message, {
  bool isError = true, 
  bool isToast = false,
  SnackBarType? type,
  Duration? duration,
  bool showProgressBar = false,
}) {
  // Set default type based on isError if not explicitly provided
  final SnackBarType snackBarType = type ?? (isError ? SnackBarType.error : SnackBarType.success);
  
  // Shorter duration (2 seconds) than Flutter's default (4 seconds)
  final Duration snackBarDuration = duration ?? const Duration(seconds: 2);
  
  final Size size = MediaQuery.of(Get.context!).size;
  
  // Hide any existing snackbar before showing the new one
  ScaffoldMessenger.of(Get.context!)..hideCurrentSnackBar()..showSnackBar(
    SnackBar(
      duration: snackBarDuration,
      elevation: 6,
      shape: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.transparent)
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSnackBarContent(message, snackBarType),
          if (showProgressBar) ...[
            const SizedBox(height: 4),
            _buildProgressBar(snackBarDuration, snackBarType),
          ],
        ],
      ),
      margin: ResponsiveHelper.isDesktop(Get.context!)
          ? EdgeInsets.only(right: size.width * 0.7, bottom: Dimensions.paddingSizeExtraSmall, left: Dimensions.paddingSizeExtraSmall)
          : EdgeInsets.only(bottom: size.height * 0.08, left: 16, right: 16),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
    )
  );
}

/// Builds the content for the snackbar with appropriate animations.
/// This is an internal method used by [showCustomSnackBarHelper].
/// 
/// Performance optimized with:
/// - Simple animation curves (easeOut instead of more complex curves)
/// - Reduced animation durations (300ms down from 350ms)
/// - Elimination of excessive visual effects like gradients
/// - Minimal layering and shadow effects (elevation 4 instead of 8)
/// - Single transform operation instead of multiple layered transforms
/// 
/// @param message Text to display in the notification
/// @param type The type of notification that controls styling
/// @return An animated widget containing the notification content
Widget _buildSnackBarContent(String? message, SnackBarType type) {
  // Complete message text
  String displayMessage = message ?? '';
  
  // Define accent colors based on notification type
  Color accentColor;
  Color backgroundColor = Colors.black;
  
  switch(type) {
    case SnackBarType.cart:
      accentColor = Colors.orange.shade300;
      backgroundColor = const Color(0xFF2D2D2D);
      break;
    case SnackBarType.success:
      accentColor = Colors.green.shade300;
      backgroundColor = const Color(0xFF2A332A);
      break;
    case SnackBarType.error:
      accentColor = Colors.red.shade300;
      backgroundColor = const Color(0xFF332A2A);
      break;
    case SnackBarType.info:
      accentColor = Colors.blue.shade300;
      backgroundColor = const Color(0xFF2A2A33);
      break;
  }
  
  // Widget with optimized animations for better performance on low-end devices
  return Align(
    alignment: Alignment.center,
    child: TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300), // Reduced from 350ms
      curve: Curves.easeOut, // Simpler curve for better performance
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1.0 - value)), // Reduced from 25 to 20
            child: child,
          ),
        );
      },
      child: Material(
        color: backgroundColor,
        elevation: 4, // Reduced from 8
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accentColor.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeDefault,
              vertical: Dimensions.paddingSizeSmall,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildIcon(type),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                Flexible(
                  child: Text(
                    displayMessage,
                    style: rubikMedium.copyWith(
                      color: Colors.white,
                      fontSize: Dimensions.fontSizeDefault,
                    ),
                    textAlign: TextAlign.center,
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

/// Creates an optimized icon based on the notification type.
/// This is an internal method used by [_buildSnackBarContent].
/// 
/// Performance optimized by:
/// - Removing complex animation layers
/// - Simplifying container structure (single container instead of nested)
/// - Eliminating shadow effects
/// - Using direct color assignments instead of gradients
/// 
/// @param type The notification type that determines icon and color
/// @return A container widget with the appropriate icon
Widget _buildIcon(SnackBarType type) {
  // Define colors and icons based on notification type
  late Color backgroundColor;
  late IconData iconData;

  switch(type) {
    case SnackBarType.success:
      backgroundColor = Colors.green.shade600;
      iconData = Icons.check_rounded;
      break;
    case SnackBarType.error:
      backgroundColor = Colors.red.shade600;
      iconData = Icons.close_rounded;
      break;
    case SnackBarType.info:
      backgroundColor = Colors.blue.shade600;
      iconData = Icons.info_rounded;
      break;
    case SnackBarType.cart:
      backgroundColor = Colors.orange.shade600;
      iconData = Icons.shopping_cart_rounded;
      break;
  }

  return Container(
    width: 26,
    height: 26,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: backgroundColor,
    ),
    child: Center(
      child: Icon(
        iconData,
        color: Colors.white,
        size: 16,
      ),
    ),
  );
}

// The following animation methods have been simplified to improve performance
// Original complex animations have been replaced with empty SizedBox widgets
// These placeholder methods are kept for backward compatibility and future expansion

/// Success animation placeholder (optimized).
/// Previously contained a complex animation, now returns an empty SizedBox for performance.
/// @return An empty SizedBox widget
Widget _buildSuccessAnimation() {
  return const SizedBox(); 
}

/// Error animation placeholder (optimized).
/// Previously contained a complex animation, now returns an empty SizedBox for performance.
/// @return An empty SizedBox widget
Widget _buildErrorAnimation() {
  return const SizedBox(); 
}

/// Info animation placeholder (optimized).
/// Previously contained a complex animation, now returns an empty SizedBox for performance.
/// @return An empty SizedBox widget
Widget _buildInfoAnimation() {
  return const SizedBox(); 
}

/// Cart animation placeholder (optimized).
/// Previously contained a complex animation, now returns an empty SizedBox for performance.
/// @return An empty SizedBox widget
Widget _buildCartAnimation() {
  return const SizedBox(); 
}

/// Builds a progress bar for the snackbar that counts down until dismissal.
/// This is an internal method used by [showCustomSnackBarHelper].
/// 
/// Performance optimized by:
/// - Simplifying the progress indicator (using built-in LinearProgressIndicator)
/// - Using direct value assignment without additional checks
/// - Linear animation curve for predictable, efficient updates
/// - Minimal height and transparency effects
/// 
/// @param duration How long the progress bar should take to complete
/// @param type The type of notification that controls the bar color
/// @return An animated linear progress indicator
Widget _buildProgressBar(Duration duration, SnackBarType type) {
  // Define color based on notification type
  Color accentColor;
  
  switch(type) {
    case SnackBarType.cart:
      accentColor = Colors.orange.shade300;
      break;
    case SnackBarType.success:
      accentColor = Colors.green.shade300;
      break;
    case SnackBarType.error:
      accentColor = Colors.red.shade300;
      break;
    case SnackBarType.info:
      accentColor = Colors.blue.shade300;
      break;
  }
  
  // Simple linear animation with minimal overhead
  return TweenAnimationBuilder<double>(
    tween: Tween<double>(begin: 1.0, end: 0.0),
    duration: duration,
    curve: Curves.linear,
    builder: (context, value, child) {
      return LinearProgressIndicator(
        value: value,
        backgroundColor: Colors.white.withOpacity(0.15),
        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
        minHeight: 2,
      );
    },
  );
}