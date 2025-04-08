import 'package:flutter/material.dart';

/**
 * Enhanced back button component that offers improved 
 * visibility, state management, and accessibility.
 * 
 * This component provides:
 * - High visual contrast with the background
 * - Safe navigation handling
 * - Touch feedback
 * - Accessibility support
 * - Responsive sizing
 */
class EnhancedBackButton extends StatelessWidget {
  /// Optional callback to execute before navigation
  final VoidCallback? onBeforeNavigate;
  
  /// Optional custom color for the button
  final Color? buttonColor;
  
  /// Icon size, defaults to 24.0
  final double iconSize;
  
  /// Semantic label for accessibility, defaults to 'Back'
  final String semanticLabel;

  /// Whether the background is dark (to adapt the button style)
  final bool? isDarkBackground;

  /// Constructor with named parameters
  const EnhancedBackButton({
    Key? key,
    this.onBeforeNavigate,
    this.buttonColor,
    this.iconSize = 24.0,
    this.semanticLabel = 'Back',
    this.isDarkBackground,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get theme colors to ensure optimal contrast
    final ThemeData theme = Theme.of(context);
    final backgroundColor = theme.scaffoldBackgroundColor;
    
    // Determine if we're on a dark background
    final bool isOnDarkBg = isDarkBackground ?? 
                         ThemeData.estimateBrightnessForColor(backgroundColor) == Brightness.dark;
    
    // Calculate final button color with proper contrast
    final Color finalButtonColor = buttonColor ?? 
                  (isOnDarkBg ? Colors.white : theme.primaryColor);
    
    // Minimalist colors with good contrast
    final Color containerColor = isOnDarkBg ? Colors.black.withOpacity(0.5) : Colors.white.withOpacity(0.9);
    final Color iconColor = isOnDarkBg ? Colors.white : Colors.black87;
    
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Semantics(
        // Semantics improves accessibility for screen readers
        label: semanticLabel,
        button: true,
        enabled: true,
        onTap: () => _handleBackNavigation(context),
        child: Container(
          // Provide smaller touch target
          margin: const EdgeInsets.only(left: 10.0, top: 10.0),
          width: 40.0,
          height: 40.0,
          decoration: BoxDecoration(
            color: containerColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 6.0,
                spreadRadius: 0.2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Material(
            // Material provides ripple effect feedback
            color: Colors.transparent,
            child: InkWell(
              // InkWell provides touch feedback
              customBorder: const CircleBorder(),
              onTap: () => _handleBackNavigation(context),
              child: Center(
                child: Icon(
                  // Using clean icon design
                  Icons.arrow_back_rounded,
                  color: iconColor,
                  size: iconSize,
                  semanticLabel: semanticLabel,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Safely handles back navigation with proper error handling
  void _handleBackNavigation(BuildContext context) {
    try {
      // Execute any pre-navigation callback if provided
      if (onBeforeNavigate != null) {
        onBeforeNavigate!();
      }
      
      // Check if navigation is possible before attempting to pop
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      } else {
        // If we can't pop (e.g., this is the root), consider alternative navigation
        // This prevents exceptions when the navigation stack is empty
        debugPrint('Warning: Cannot navigate back from this screen - no parent routes');
      }
    } catch (e) {
      // Catch and log any navigation errors
      debugPrint('Error during back navigation: $e');
      
      // Attempt an alternative safe navigation approach if the standard one fails
      if (context.mounted) {
        Navigator.maybePop(context);
      }
    }
  }
} 