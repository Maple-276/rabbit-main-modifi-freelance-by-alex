import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_restaurant/common/widgets/custom_alert_dialog_widget.dart';
import 'package:flutter_restaurant/helper/responsive_helper.dart';
import 'package:flutter_restaurant/localization/language_constrants.dart';
import 'package:flutter_restaurant/utill/images.dart';


class CustomPopScopeWidget extends StatefulWidget {
  final Widget child;
  final Function()? onPopInvoked;
  final bool isExit;

  const CustomPopScopeWidget({super.key, required this.child, this.onPopInvoked, this.isExit = true});

  @override
  State<CustomPopScopeWidget> createState() => _CustomPopScopeWidgetState();
}

class _CustomPopScopeWidgetState extends State<CustomPopScopeWidget> {

  @override
  Widget build(BuildContext context) {
    // Allow popping (including swipe gesture) by default on mobile.
    // Desktop might have different behaviors handled elsewhere or could also be true.
    final bool canPopScope = !ResponsiveHelper.isDesktop(context); // Or simply true if desktop behaves same

    return PopScope(
      // Let the system handle the pop gesture by default.
      canPop: true,
      onPopInvoked: (didPop) {
        // This is called AFTER the pop attempt (swipe gesture or back button).
        // didPop is true if the pop is proceeding, false if prevented by canPop (which is now true).

        if (didPop) {
          // If a custom action needs to happen AFTER a successful pop, call it.
          widget.onPopInvoked?.call();

          // IMPORTANT: The exit confirmation logic for the root screen (like Dashboard)
          // should be handled specifically where CustomPopScopeWidget is used with isExit=true,
          // possibly by providing a specific onPopInvoked callback there,
          // or by wrapping DashboardScreen's scaffold with its own PopScope.
          // Removing the generic exit logic from here.

        }
         // No need for manual Navigator.pop(context) as canPop is true.
         // No need for the !Navigator.canPop check here as the system handles root pop prevention.
      },
      child: widget.child,
    );
  }
}
